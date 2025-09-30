// Supabase Edge Function: cancel-workout-reminders
// Cancels scheduled workout reminder notifications

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID')!
const ONESIGNAL_API_KEY = Deno.env.get('ONESIGNAL_API_KEY')!

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
    const { plan_id } = await req.json()

    if (!plan_id) {
      return new Response(
        JSON.stringify({ error: 'plan_id is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Get all scheduled notifications for this plan
    const { data: scheduled, error: fetchError } = await supabaseClient
      .from('scheduled_notifications')
      .select('*')
      .eq('plan_id', plan_id)
      .eq('status', 'scheduled')

    if (fetchError) {
      throw new Error(`Failed to fetch scheduled notifications: ${fetchError.message}`)
    }

    if (!scheduled || scheduled.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No scheduled notifications found for this plan',
          cancelled_count: 0,
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Cancel each notification via OneSignal API
    const cancelled = []
    for (const notification of scheduled) {
      try {
        await cancelOneSignalNotification(notification.onesignal_notification_id)
        cancelled.push(notification.id)

        // Update status in database
        await supabaseClient
          .from('scheduled_notifications')
          .update({ status: 'cancelled', cancelled_at: new Date().toISOString() })
          .eq('id', notification.id)
      } catch (error) {
        console.error(`Failed to cancel notification ${notification.id}:`, error)
        // Continue with other notifications
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        cancelled_count: cancelled.length,
        total_scheduled: scheduled.length,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error cancelling reminders:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

// Cancel notification via OneSignal API
async function cancelOneSignalNotification(notificationId: string) {
  const response = await fetch(
    `https://onesignal.com/api/v1/notifications/${notificationId}?app_id=${ONESIGNAL_APP_ID}`,
    {
      method: 'DELETE',
      headers: {
        Authorization: `Basic ${ONESIGNAL_API_KEY}`,
      },
    }
  )

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`OneSignal API error: ${error}`)
  }

  return await response.json()
}
