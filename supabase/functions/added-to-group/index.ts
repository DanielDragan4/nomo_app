// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

import { createClient } from 'npm:@supabase/supabase-js@2';
import { JWT } from 'npm:google-auth-library@9';

interface GroupMember {
  profile_id: string;
  group_id: string;
}

interface WebhookPayload {
  type: 'INSERT';
  table: string;
  record: GroupMember;
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
  if (payload.type !== 'INSERT' || payload.table !== 'Group_Members') {
    return new Response('Invalid event type or table', { status: 400 });
  }

   // Fetch group details
   const { data: group, error: groupError } = await supabase
   .from('Groups')
   .select('name')
   .eq('group_id', payload.record.group_id)
   .single();

 if (groupError) {
    console.error('Error fetching group:', groupError);
    return new Response('Internal Server Error', { status: 500 });
  }

  // Fetch user's profile and FCM token
  const { data: memberProfile, error: memberProfileError } = await supabase
    .from('Profiles')
    .select('profile_name, fcm_token')
    .eq('profile_id', payload.record.profile_id)
    .single();

  if (memberProfileError) {
    console.error('Error fetching user profile:', memberProfileError);
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
        token: memberProfile.fcm_token,
        notification: {
          title: `Added to Group`,
          body: `You have been added to the group "${group.name}"`,
        },
        data: {
          groupName: group.name,
          groupId: payload.record.group_id,
          memberId: memberProfile.profile_name,
          attendeeId: payload.record.profile_id,
          type: 'GROUP',
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
