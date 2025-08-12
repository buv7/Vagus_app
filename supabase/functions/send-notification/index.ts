import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// OneSignal configuration
const ONESIGNAL_APP_ID = Deno.env.get("ONESIGNAL_APP_ID") || "YOUR-ONESIGNAL-APP-ID";
const ONESIGNAL_REST_API_KEY = Deno.env.get("ONESIGNAL_REST_API_KEY") || "YOUR-ONESIGNAL-REST-API-KEY";

interface NotificationRequest {
  type: 'user' | 'users' | 'role' | 'topic';
  userId?: string;
  userIds?: string[];
  role?: string;
  topic?: string;
  title: string;
  message: string;
  route?: string;
  screen?: string;
  id?: string;
  additionalData?: Record<string, any>;
}

interface OneSignalPayload {
  app_id: string;
  headings: { en: string };
  contents: { en: string };
  include_player_ids?: string[];
  include_external_user_ids?: string[];
  included_segments?: string[];
  data?: Record<string, any>;
  url?: string;
}

serve(async (req) => {
  try {
    // Handle CORS
    if (req.method === 'OPTIONS') {
      return new Response(null, {
        status: 200,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      });
    }

    // Only allow POST requests
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Parse request body
    const body: NotificationRequest = await req.json();
    
    // Validate required fields
    if (!body.title || !body.message) {
      return new Response(JSON.stringify({ error: 'Title and message are required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Build OneSignal payload
    const oneSignalPayload: OneSignalPayload = {
      app_id: ONESIGNAL_APP_ID,
      headings: { en: body.title },
      contents: { en: body.message },
      data: {
        route: body.route,
        screen: body.screen,
        id: body.id,
        ...body.additionalData,
      },
    };

    // Add routing data if provided
    if (body.route) {
      oneSignalPayload.url = body.route;
    }

    // Handle different notification types
    switch (body.type) {
      case 'user':
        if (!body.userId) {
          return new Response(JSON.stringify({ error: 'User ID required for user notification' }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' },
          });
        }
        oneSignalPayload.include_external_user_ids = [body.userId];
        break;

      case 'users':
        if (!body.userIds || body.userIds.length === 0) {
          return new Response(JSON.stringify({ error: 'User IDs required for users notification' }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' },
          });
        }
        oneSignalPayload.include_external_user_ids = body.userIds;
        break;

      case 'role':
        if (!body.role) {
          return new Response(JSON.stringify({ error: 'Role required for role notification' }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' },
          });
        }
        oneSignalPayload.included_segments = [body.role];
        break;

      case 'topic':
        if (!body.topic) {
          return new Response(JSON.stringify({ error: 'Topic required for topic notification' }), {
            status: 400,
            headers: { 'Content-Type': 'application/json' },
          });
        }
        oneSignalPayload.included_segments = [body.topic];
        break;

      default:
        return new Response(JSON.stringify({ error: 'Invalid notification type' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        });
    }

    // Send notification via OneSignal API
    const response = await fetch("https://onesignal.com/api/v1/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify(oneSignalPayload),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('OneSignal API error:', errorText);
      return new Response(JSON.stringify({ 
        error: 'Failed to send notification via OneSignal',
        details: errorText 
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const result = await response.json();
    console.log('Notification sent successfully:', result);

    return new Response(JSON.stringify({ 
      success: true, 
      message: 'Notification sent successfully',
      oneSignalResult: result 
    }), {
      status: 200,
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });

  } catch (error) {
    console.error('Error sending notification:', error);
    return new Response(JSON.stringify({ 
      error: 'Internal server error',
      details: error.message 
    }), {
      status: 500,
      headers: { 
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  }
});
