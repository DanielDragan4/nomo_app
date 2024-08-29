// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

//console.log("Hello from Functions!")

import { createClient } from 'npm:@supabase/supabase-js@2'
import {JWT} from 'npm:google-auth-library@9'

interface Event {
  eventId: string
  imageId: string
  imageUrl: string
  title: string
  location: string
  description: string
  eventType: string
  hostUsername: string
  hostProfileUrl: string
  profileName: string
  bookmarked: boolean
  attending: boolean
  isHost: boolean
  host: string
}

interface WebhookPayload {
  type: 'INSERT'
  table: string
  record: Event
  schema: 'public',
  old_record: null | Event
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

  const { data: hostProfileName, error: hostProfileError } = await supabase
    .from('Profiles')
    .select('profile_name')
    .eq('profile_id', payload.record.host)
    .single()

    if (hostProfileError) {
      console.error('Error fetching host profile:', hostProfileError)
      return new Response('Internal Server Error', { status: 500 })
    }

  const { data : friends, error } = await supabase.from('Friends').select('friend').eq('current', payload.record.host)

  if (error) {
    console.error('Error fetching friends:', error)
    return new Response('Internal Server Error', { status: 500 })
  }

  if(friends.length === 0) {
    return new Response('No friends found', { status: 404 })
  }

  const friendIds = friends.map(f => f.friend)

  // Fetch all FCM tokens of friends
  const { data: profiles, error: profileError } = await supabase
    .from('Profiles')
    .select('fcm_token')
    .in('profile_id', friendIds)

  if (profileError) {
    console.error('Error fetching FCM tokens:', profileError)
    return new Response('Internal Server Error', { status: 500 })
  }

  // Import the service account details
  const { default: serviceAccount } = await import('../service-account.json', {
    with: { type: 'json' },
  })

  // Get the access token
  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })

  // Send notifications to all users
  const notifications = profiles.map(async profile => {
    const fcmToken = profile.fcm_token

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
            title: `New Event Created by ${hostProfileName.profile_name}`,
            body: `"${payload.record.title}"`
          },
          data: {
            hostUsername: hostProfileName.profile_name,
            eventTitle: payload.record.title,
            eventId: payload.record.eventId,
            type: 'CREATE'
          }
        }
      })
    })

    const resData = await res.json()
    if (res.status < 200 || 299 < res.status) {
      console.error('Error sending notification:', resData)
    }

    return resData
  })

  // Await all notifications to be sent
  const results = await Promise.all(notifications)

  return new Response(
    JSON.stringify(results),
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

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/event-created' \
    --header 'Authorization: Bearer YOUR_JWT_TOKEN' \
    --header 'Content-Type: application/json' \
    --data '{"type":"INSERT","table":"Events","record":{"eventId":"1","imageId":"1","imageUrl":"http://example.com/image.jpg","title":"New Event","location":"Event Location","description":"Event Description","eventType":"Type","hostUsername":"hostuser","hostProfileUrl":"http://example.com/profile.jpg","profileName":"Host Name","bookmarked":false,"attending":true,"isHost":true,"host":"host-id"}}'

*/

