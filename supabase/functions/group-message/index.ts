// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

//console.log("Hello from Functions!")

import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9.11.0'

interface GroupMessage {
  group_message_id: string
  sender_id: string
  group_id: string
  message: string
  created_at: string
}

interface Group {
  group_id: string
  name: string
  avatar: string
}

interface WebhookPayload {
  type: 'INSERT'
  table: string
  record: GroupMessage
  schema: 'public'
  old_record: null | GroupMessage
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
  const { group_id, sender_id, message } = payload.record

  // Fetch group details
  const { data: group, error: groupError } = await supabase
    .from('Groups')
    .select('name')
    .eq('group_id', group_id)
    .single()

  if (groupError) {
    console.error('Error fetching group details:', groupError)
    return new Response('Internal Server Error', { status: 500 })
  }

  // Fetch all group members except the sender
  const { data: groupMembers, error: membersError } = await supabase
    .from('Group_Members')
    .select('profile_id')
    .eq('group_id', group_id)
    .neq('profile_id', sender_id)

  if (membersError) {
    console.error('Error fetching group members:', membersError)
    return new Response('Internal Server Error', { status: 500 })
  }

  // Fetch sender's profile name
  const { data: senderProfile, error: senderError } = await supabase
    .from('Profiles')
    .select('profile_name')
    .eq('profile_id', sender_id)
    .single()

  if (senderError) {
    console.error('Error fetching sender profile name:', senderError)
    return new Response('Internal Server Error', { status: 500 })
  }

  const senderName = senderProfile.profile_name

  // Import the service account details
  const { default: serviceAccount } = await import('../service-account.json', {
    with: { type: 'json' },
  })

  // Get the access token
  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })

  // Send notifications to all group members
  const notificationPromises = groupMembers.map(async (member) => {
    // Fetch recipient's FCM token from the Profiles table
    const { data: profile, error: profileError } = await supabase
      .from('Profiles')
      .select('fcm_token')
      .eq('profile_id', member.profile_id)
      .single()

    if (profileError) {
      console.error('Error fetching recipient profile:', profileError)
      return null
    }

    const fcmToken = profile.fcm_token as string

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
            title: `New message in ${group.name}`,
            body: `${senderName}: ${message}`
          },
          data: {
            type: 'GroupMessage',
            group_id: group_id,
            group: group.name,
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
      return null
    }

    return resData
  })

  const results = await Promise.all(notificationPromises)

  return new Response(
    JSON.stringify({ success: true, results }),
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
