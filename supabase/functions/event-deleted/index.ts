// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

//console.log("Hello from Functions!")

import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'

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
  type: 'DELETE'
  table: string
  record: null | Event
  schema: 'public',
  old_record: Event
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

Deno.serve(async (req) => {
  const payload: WebhookPayload = await req.json()

  console.log('Received payload:', JSON.stringify(payload, null, 2))

  // Ensure the event type is DELETE
  if (payload.type !== 'DELETE') {
    return new Response('Invalid event type', { status: 400 })
  }

  const { data: hostProfileName, error: hostProfileError } = await supabase
    .from('Profiles')
    .select('profile_name')
    .eq('profile_id', payload.old_record.host)
    .single()

    if (hostProfileError) {
      console.error('Error fetching host profile:', hostProfileError)
      return new Response('Internal Server Error', { status: 500 })
    }

  const { data: friends, error } = await supabase
    .from('Friends')
    .select('friend')
    .eq('current', payload.old_record.host)

  if (error) {
    console.error('Error fetching friends:', error)
    return new Response('Internal Server Error', { status: 500 })
  }

  if (friends.length === 0) {
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
            title: `${hostProfileName.profile_name} has deleted an Event`,
            body: `"${payload.old_record.title}"`
          },
          data: {
            hostUsername: hostProfileName.profile_name,
            eventTitle: payload.old_record.title,
            eventDescription: payload.old_record.description,
          }
        }
      })
    })

    const resData = await res.json()
    if (res.status < 200 || res.status > 299) {
      console.error('Error sending notification:', resData)
    }

    return resData
  })

  // Await all notifications to be sent
  const results = await Promise.all(notifications)

  // Return the updated/deleted event title and description as data
  const responseData = {
    title: payload.old_record.title,
    description: payload.old_record.description,
    notifications: results
  }

  return new Response(
    JSON.stringify(responseData),
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

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/event-deleted' \
    --header 'Authorization: Bearer YOUR_JWT_TOKEN' \
    --header 'Content-Type: application/json' \
    --data '{"type":"DELETE","table":"Events","record":null,"old_record":{"eventId":"1","imageId":"1","imageUrl":"http://example.com/image.jpg","title":"Old Event","location":"Event Location","description":"Event Description","eventType":"Type","hostUsername":"hostuser","hostProfileUrl":"http://example.com/profile.jpg","profileName":"Host Name","bookmarked":false,"attending":true,"isHost":true,"host":"host-id"}}'

*/
