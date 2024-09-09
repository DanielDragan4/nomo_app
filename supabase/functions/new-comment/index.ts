// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

//console.log("Hello from Functions!")

import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9.11.0'

interface Comment {
  comments_id: string
  commented_at: string
  comment_text: string
  event_id: string
  user_id: string
}

interface Event {
  event_id: string
  host: string
  title: string
}

interface WebhookPayload {
  type: 'INSERT'
  table: string
  record: Comment
  schema: 'public'
  old_record: null | Comment
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

  // Get the comment details
  const { event_id, user_id, comment_text } = payload.record

  // Fetch event details to get the host and event title
  const { data: event, error: eventError } = await supabase
    .from('Event')
    .select('host, title')
    .eq('event_id', event_id)
    .single()

  if (eventError) {
    console.error('Error fetching event details:', eventError)
    return new Response('Internal Server Error', { status: 500 })
  }

  // Fetch commenter's profile name
  const { data: commenterProfile, error: commenterError } = await supabase
    .from('Profiles')
    .select('profile_name')
    .eq('profile_id', user_id)
    .single()

  if (commenterError) {
    console.error('Error fetching commenter profile:', commenterError)
    return new Response('Internal Server Error', { status: 500 })
  }

  // Fetch host's FCM token
  const { data: hostProfile, error: hostError } = await supabase
    .from('Profiles')
    .select('fcm_token')
    .eq('profile_id', event.host)
    .single()

  if (hostError) {
    console.error('Error fetching host profile:', hostError)
    return new Response('Internal Server Error', { status: 500 })
  }

  const fcmToken = hostProfile.fcm_token as string

  // Import the service account details
  const { default: serviceAccount } = await import('../service-account.json', {
    with: { type: 'json' },
  })

  // Get the access token
  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })

  // Send the notification to the host
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
          title: `New comment on your event: ${event.title}`,
          body: `${commenterProfile.profile_name}: ${comment_text.substring(0, 100)}${comment_text.length > 100 ? '...' : ''}`
        },
        data: {
          type: 'EventComment',
          event_id: event_id,
          comment_id: payload.record.comments_id,
          commenter_id: user_id,
          commenter_name: commenterProfile.profile_name,
          comment_content: `${comment_text.substring(0, 100)}${comment_text.length > 100 ? '...' : ''}`,
          title: event.title,
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
    JSON.stringify({ success: true, result: resData }),
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
