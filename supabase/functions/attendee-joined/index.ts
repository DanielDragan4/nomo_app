// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

import { createClient } from 'npm:@supabase/supabase-js@2';
import { JWT } from 'npm:google-auth-library@9';

interface Attendee {
  attendees_id: string;
  event_id: string;
  user_id: string;
}

interface WebhookPayload {
  type: 'INSERT';
  table: string;
  record: Attendee;
  schema: 'public';
  old_record: null;
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
);

Deno.serve(async (req) => {
  const payload: WebhookPayload = await req.json();

  // Ensure the event type is INSERT
  if (payload.type !== 'INSERT') {
    return new Response('Invalid event type', { status: 400 });
  }

  // Fetch event details
  const { data: event, error: eventError } = await supabase
    .from('Event')
    .select('title, host')
    .eq('event_id', payload.record.event_id)
    .single();

  if (eventError) {
    console.error('Error fetching event:', eventError);
    return new Response('Internal Server Error', { status: 500 });
  }

  // Fetch attendee profile name
  const { data: attendeeProfile, error: attendeeProfileError } = await supabase
    .from('Profiles')
    .select('profile_name')
    .eq('profile_id', payload.record.user_id)
    .single();

  if (attendeeProfileError) {
    console.error('Error fetching attendee profile:', attendeeProfileError);
    return new Response('Internal Server Error', { status: 500 });
  }

  // Fetch host FCM token
  const { data: hostProfile, error: hostProfileError } = await supabase
    .from('Profiles')
    .select('fcm_token')
    .eq('profile_id', event.host)
    .single();

  if (hostProfileError) {
    console.error('Error fetching host profile:', hostProfileError);
    return new Response('Internal Server Error', { status: 500 });
  }

  // Import the service account details
  const { default: serviceAccount } = await import('../service-account.json', {
    with: { type: 'json' },
  });

  // Get the access token
  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  });

  // Send notification to the host
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/nomo-app-c3417/messages:send`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      message: {
        token: hostProfile.fcm_token,
        notification: {
          title: `New Attendee`,
          body: `${attendeeProfile.profile_name} has joined your event, "${event.title}"`,
        },
        data: {
          eventTitle: event.title,
          eventId: payload.record.event_id,
          attendeeName: attendeeProfile.profile_name,
          attendeeId: payload.record.attendees_id,
          type: 'JOIN',
        },
      },
    }),
  });

  const resData = await res.json();
  if (res.status < 200 || res.status > 299) {
    console.error('Error sending notification:', resData);
    return new Response('Error sending notification', { status: 500 });
  }

  return new Response(
    JSON.stringify({ message: 'Notification sent successfully' }),
    { headers: { 'Content-Type': 'application/json' } },
  );
});

const getAccessToken = ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string;
  privateKey: string;
}): Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });
    jwtClient.authorize((err, tokens) => {
      if (err) {
        reject(err);
        return;
      }
      resolve(tokens!.access_token!);
    });
  });
};

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/attendee-joined' \
    --header 'Authorization: Bearer YOUR_JWT_TOKEN' \
    --header 'Content-Type: application/json' \
    --data '{"type":"INSERT","table":"Attendees","record":{"event_id":"1","user_id":"user-id"}}'
*/
