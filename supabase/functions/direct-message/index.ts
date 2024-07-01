// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

//console.log("Hello from Functions!")

import { createClient } from 'npm:@supabase/supabase-js@2'
import {JWT} from 'npm:google-auth-library@9.11.0'

interface Message {
  id: string
  chat_id: string
  sender_id: string
  created_at: string
  message: string
}

interface Chat {
  chat_id: string
  chat_name: string
  user1_id: string
  user2_id: string
}

interface WebhookPayload {
  type: 'INSERT'
  table: string
  record: Message
  schema: 'public',
  old_record: null | Message
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

Deno.serve(async (req) => {
  const payload: WebhookPayload = await req.json()

  // Ensure the event type is INSERT
  if (payload.type !== 'INSERT') {
    return new Response('Invalid event type', { status: 400 })
  }

  // Get the message details
  const { chat_id, sender_id, message } = payload.record

  // Fetch chat details to get the recipient
  const { data: chat, error: chatError } = await supabase
    .from('Chats')
    .select('chat_id, user1_id, user2_id')
    .eq('chat_id', chat_id)
    .single()

  if (chatError) {
    console.error('Error fetching chat details:', chatError)
    return new Response('Internal Server Error', { status: 500 })
  }

  const recipient_id = chat.user1_id === sender_id ? chat.user2_id : chat.user1_id

  // Fetch recipient's FCM token from the Profiles table
  const { data: profile, error: profileError } = await supabase
    .from('Profiles')
    .select('fcm_token')
    .eq('profile_id', recipient_id)
    .single()

  if (profileError) {
    console.error('Error fetching recipient profile:', profileError)
    return new Response('Internal Server Error', { status: 500 })
  }

  const fcmToken = profile.fcm_token as string

  // Import the service account details
  const { default: serviceAccount } = await import('../service-account.json', {
    with: { type: 'json' },
  })

  const { data: senderProfile, error: senderError } = await supabase
    .from('Profiles')
    .select('profile_name')
    .eq('profile_id', payload.record.sender_id)
    .single();

  if (senderError) {
    console.error('Error fetching sender profile name:', senderError);
    return new Response('Internal Server Error', { status: 500 });
  }

  const senderName = senderProfile.profile_name;

  // Get the access token
  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })

  // Send the notification
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/nomo-app-c3417/messages:send`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification: {
          title: `New message from ${senderName}`,
          body: message
        },
        data: {
          type: 'DM',
          chat_id: chat_id,
          message: message,
          sender: senderName,
          senderId: sender_id,
        }
      }
    })
  })

  const resData = await res.json()
  if (res.status < 200 || 299 < res.status) {
    console.error('Error sending notification:', resData)
    return new Response('Internal Server Error', { status: 500 })
  }

  return new Response(
    JSON.stringify(resData),
    { headers: { "Content-Type": "application/json" } },
  )
})

const getAccessToken = ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string,
  privateKey: string,
}): Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    jwtClient.authorize((err, tokens) => {
      if (err) {
        reject(err)
        return
      }
      resolve(tokens!.access_token!)
    })
  })
}

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/direct-message' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
