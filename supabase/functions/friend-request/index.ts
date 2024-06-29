// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'

interface FriendRequest {
  id: string
  sender_id: string
  reciever_id: string
}

interface WebhookPayload {
  type: 'INSERT'
  table: string
  record: FriendRequest
  schema: 'public',
  old_record: null | FriendRequest
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

  const { record } = payload

  // Fetch sender profile details
  const { data: senderProfile, error: senderError } = await supabase
    .from('Profiles')
    .select('profile_name')
    .eq('profile_id', record.sender_id)
    .single()

  if (senderError) {
    console.error('Error fetching sender profile:', senderError)
    return new Response('Internal Server Error', { status: 500 })
  }

  // Fetch reciever profile details
  const { data: recieverProfile, error: recieverError } = await supabase
    .from('Profiles')
    .select('fcm_token')
    .eq('profile_id', record.reciever_id)
    .single()

  if (recieverError) {
    console.error('Error fetching reciever profile:', recieverError)
    return new Response('Internal Server Error', { status: 500 })
  }

  const senderName = senderProfile.profile_name
  const recieverFcmToken = recieverProfile.fcm_token

  // Import the service account details
  const { default: serviceAccount } = await import('../service-account.json', {
    with: { type: 'json' },
  })

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
        token: recieverFcmToken,
        notification: {
          title: 'New Friend Request',
          body: `${senderName} sent you a friend request.`,
        },
        data: {
          senderName: senderName,
          type: 'REQUEST',
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
    { headers: { 'Content-Type': 'application/json' } },
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

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/friend-request' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
