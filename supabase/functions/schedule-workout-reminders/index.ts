// Supabase Edge Function: schedule-workout-reminders
// Schedules workout reminder notifications based on user preferences and workout plan

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID')!
const ONESIGNAL_API_KEY = Deno.env.get('ONESIGNAL_API_KEY')!

interface WorkoutDay {
  id: string
  day_label: string
  date: string
  is_rest_day: boolean
  exercises: Array<{
    id: string
    name: string
    muscle_group: string
    sets: number
  }>
}

interface NotificationPreferences {
  workout_reminders_enabled: boolean
  workout_reminder_time?: string
  reminder_minutes_before: number
  rest_day_reminders_enabled: boolean
  timezone: string
}

serve(async (req) => {
  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get request body
    const { plan_id, schedule } = await req.json()

    if (!plan_id) {
      return new Response(
        JSON.stringify({ error: 'plan_id is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get workout plan with days and user info
    const { data: plan, error: planError } = await supabaseClient
      .from('workout_plans')
      .select(`
        *,
        user_id,
        profiles!inner(
          onesignal_player_id,
          timezone
        ),
        workout_weeks!inner(
          *,
          workout_days!inner(
            *,
            exercises(*)
          )
        )
      `)
      .eq('id', plan_id)
      .single()

    if (planError) {
      throw new Error(`Failed to fetch plan: ${planError.message}`)
    }

    const userId = plan.user_id
    const playerIds = plan.profiles.onesignal_player_id ? [plan.profiles.onesignal_player_id] : []

    if (playerIds.length === 0) {
      return new Response(
        JSON.stringify({ error: 'User has no OneSignal player ID' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get notification preferences
    const { data: prefsData } = await supabaseClient
      .from('notification_preferences')
      .select('preferences')
      .eq('user_id', userId)
      .maybeSingle()

    const preferences: NotificationPreferences = prefsData?.preferences || {
      workout_reminders_enabled: true,
      reminder_minutes_before: 30,
      rest_day_reminders_enabled: true,
      timezone: 'UTC',
    }

    if (!preferences.workout_reminders_enabled) {
      return new Response(
        JSON.stringify({ message: 'Workout reminders disabled for user' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Collect all workout days
    const allDays: WorkoutDay[] = []
    for (const week of plan.workout_weeks) {
      for (const day of week.workout_days) {
        allDays.push({
          id: day.id,
          day_label: day.day_label,
          date: day.date,
          is_rest_day: day.is_rest_day || false,
          exercises: day.exercises || [],
        })
      }
    }

    // Schedule notifications for each day
    const scheduled = []
    for (const day of allDays) {
      // Skip rest days if disabled
      if (day.is_rest_day && !preferences.rest_day_reminders_enabled) {
        continue
      }

      // Calculate send time
      const dayDate = new Date(day.date)
      const sendTime = calculateSendTime(
        dayDate,
        preferences.workout_reminder_time,
        preferences.reminder_minutes_before,
        preferences.timezone
      )

      // Don't schedule past notifications
      if (sendTime < new Date()) {
        continue
      }

      // Prepare notification data
      const notificationData = day.is_rest_day
        ? prepareRestDayNotification(day)
        : prepareWorkoutNotification(day)

      // Schedule notification via OneSignal
      const result = await scheduleOneSignalNotification({
        player_ids: playerIds,
        send_after: sendTime.toISOString(),
        ...notificationData,
      })

      scheduled.push({
        day_id: day.id,
        day_label: day.day_label,
        send_time: sendTime.toISOString(),
        notification_id: result.id,
      })

      // Save scheduled notification to database
      await supabaseClient.from('scheduled_notifications').insert({
        user_id: userId,
        plan_id: plan_id,
        day_id: day.id,
        notification_type: day.is_rest_day ? 'rest_day_reminder' : 'workout_reminder',
        send_at: sendTime.toISOString(),
        onesignal_notification_id: result.id,
        status: 'scheduled',
      })
    }

    return new Response(
      JSON.stringify({
        success: true,
        scheduled_count: scheduled.length,
        notifications: scheduled,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error scheduling reminders:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

// Calculate notification send time based on preferences
function calculateSendTime(
  dayDate: Date,
  reminderTime: string | undefined,
  minutesBefore: number,
  timezone: string
): Date {
  // If specific time is set, use that
  if (reminderTime) {
    const [hours, minutes] = reminderTime.split(':').map(Number)
    const sendTime = new Date(dayDate)
    sendTime.setHours(hours, minutes, 0, 0)
    return sendTime
  }

  // Otherwise, send X minutes before the workout
  // Assume workout is at 8:00 AM by default
  const defaultWorkoutTime = new Date(dayDate)
  defaultWorkoutTime.setHours(8, 0, 0, 0)

  const sendTime = new Date(defaultWorkoutTime.getTime() - minutesBefore * 60 * 1000)
  return sendTime
}

// Prepare workout reminder notification
function prepareWorkoutNotification(day: WorkoutDay) {
  const exerciseCount = day.exercises.length
  const muscleGroups = [...new Set(day.exercises.map(e => e.muscle_group))]
  const totalSets = day.exercises.reduce((sum, e) => sum + (e.sets || 0), 0)
  const estimatedDuration = Math.ceil(totalSets * 3) // ~3 min per set

  return {
    headings: { en: `Time for ${day.day_label}` },
    contents: {
      en: `${exerciseCount} exercises • ${muscleGroups.join(', ')} • ~${estimatedDuration} min`,
    },
    data: {
      type: 'workout_reminder',
      payload: JSON.stringify({
        day_id: day.id,
        day_label: day.day_label,
        scheduled_time: day.date,
        exercise_count: exerciseCount,
        estimated_duration: estimatedDuration,
        muscle_groups: muscleGroups,
      }),
    },
    buttons: [
      { id: 'start', text: 'Start Workout' },
      { id: 'snooze', text: 'Snooze 15min' },
    ],
    android_channel_id: 'workout_reminders',
    ios_sound: 'workout_bell.wav',
  }
}

// Prepare rest day notification
function prepareRestDayNotification(day: WorkoutDay) {
  const motivationalMessages = [
    'Recovery is where the magic happens! 💤',
    'Rest today, conquer tomorrow! 🌟',
    'Your muscles are rebuilding stronger! 💪',
    'Active recovery or complete rest - both build strength! 🧘',
  ]

  const message = motivationalMessages[Math.floor(Math.random() * motivationalMessages.length)]

  return {
    headings: { en: 'Rest Day 💤' },
    contents: { en: message },
    data: {
      type: 'rest_day_reminder',
      payload: JSON.stringify({
        date: day.date,
        motivational_message: message,
        is_active_recovery: false,
      }),
    },
    android_channel_id: 'rest_day_reminders',
  }
}

// Schedule notification via OneSignal API
async function scheduleOneSignalNotification(payload: any) {
  const response = await fetch('https://onesignal.com/api/v1/notifications', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Basic ${ONESIGNAL_API_KEY}`,
    },
    body: JSON.stringify({
      app_id: ONESIGNAL_APP_ID,
      include_player_ids: payload.player_ids,
      send_after: payload.send_after,
      headings: payload.headings,
      contents: payload.contents,
      data: payload.data,
      buttons: payload.buttons,
      android_channel_id: payload.android_channel_id,
      ios_sound: payload.ios_sound,
    }),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`OneSignal API error: ${error}`)
  }

  return await response.json()
}
