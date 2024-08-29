// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

//console.log("Hello from Functions!")

import { createClient } from 'npm:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'

interface Event {
  event_id: string
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
  type: 'DELETE' | 'UPDATE' // Handle both DELETE and UPDATE events
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

  // Ensure the event type is DELETE or UPDATE
  if (payload.type !== 'DELETE' && payload.type !== 'UPDATE') {
    return new Response('Invalid event type', { status: 400 })
  }

  // Handle DELETE event
  if (payload.type === 'DELETE') {
    const { data: hostProfileName, error: hostProfileError } = await supabase
      .from('Profiles')
      .select('profile_name')
      .eq('profile_id', payload.old_record.host)
      .single()

    if (hostProfileError) {
      console.error('Error fetching host profile:', hostProfileError)
      return new Response('Internal Server Error', { status: 500 })
    }

    const { data: attendees, error: attendeesError } = await supabase
      .from('Attendees')
      .select('user_id')
      .eq('event_id', payload.old_record.event_id)
      .neq('user_id', payload.old_record.host)

    if (attendeesError) {
      console.error('Error fetching attendees:', attendeesError)
      return new Response('Internal Server Error', { status: 500 })
    }

    if (attendees.length === 0) {
      return new Response('No attendees found', { status: 404 })
    }

    const attendeeIds = attendees.map(a => a.user_id)

    // Fetch all FCM tokens of attendees
    const { data: profiles, error: profileError } = await supabase
      .from('Profiles')
      .select('fcm_token')
      .in('profile_id', attendeeIds)

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
              type: payload.type
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
  }

  // Handle UPDATE event (for demonstration)
  if (payload.type === 'UPDATE') {
    
    const { data: hostProfileName, error: hostProfileError } = await supabase
      .from('Profiles')
      .select('profile_name')
      .eq('profile_id', payload.old_record.host)
      .single()

    if (hostProfileError) {
      console.error('Error fetching host profile:', hostProfileError)
      return new Response('Internal Server Error', { status: 500 })
    }

    const { data: attendees, error: attendeesError } = await supabase
      .from('Attendees')
      .select('user_id')
      .eq('event_id', payload.old_record.event_id)
      .neq('user_id', payload.old_record.host)

    if (attendeesError) {
      console.error('Error fetching attendees:', attendeesError)
      return new Response('Internal Server Error', { status: 500 })
    }

    if (attendees.length === 0) {
      return new Response('No attendees found', { status: 404 })
    }

    const attendeeIds = attendees.map(a => a.user_id)

    // Fetch all FCM tokens of attendees
    const { data: profiles, error: profileError } = await supabase
      .from('Profiles')
      .select('fcm_token')
      .in('profile_id', attendeeIds)

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
              title: `${hostProfileName.profile_name} has updated an Event`,
              body: `"${payload.old_record.title}"`
            },
            data: {
              hostUsername: hostProfileName.profile_name,
              eventTitle: payload.old_record.title,
              eventDescription: payload.old_record.description,
              eventId: payload.old_record.event_id,
              type: payload.type
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
      JSON.stringify({ message: 'Event updated', event: payload.record }),
      { headers: { "Content-Type": "application/json" } },
    )
  }

  return new Response('Unhandled event type', { status: 400 })
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
  2. Make an HTTP request for DELETE:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/event-deleted' \
    --header 'Authorization: Bearer YOUR_JWT_TOKEN' \
    --header 'Content-Type: application/json' \
    --data '{"type":"DELETE","table":"Events","record":null,"old_record":{"eventId":"1","imageId":"1","imageUrl":"http://example.com/image.jpg","title":"Old Event","location":"Event Location","description":"Event Description","eventType":"Type","hostUsername":"hostuser","hostProfileUrl":"http://example.com/profile.jpg","profileName":"Host Name","bookmarked":false,"attending":true,"isHost":true,"host":"host-id"}}'

  3. Make an HTTP request for UPDATE (example):

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/event-deleted' \
    --header 'Authorization: Bearer YOUR_JWT_TOKEN' \
    --header 'Content-Type: application/json' \
    --data '{"type":"UPDATE","table":"Events","record":{"eventId":"2","imageId":"2","imageUrl":"http://example.com/image2.jpg","title":"Updated Event","location":"Updated Location","description":"Updated Description","eventType":"Type","hostUsername":"hostuser","hostProfileUrl":"http://example.com/profile.jpg","profileName":"Host Name","bookmarked":false,"attending":true,"isHost":true,"host":"host-id"},"old_record":{"eventId":"2","imageId":"2","imageUrl":"http://example.com/image2.jpg","title":"Old Event","location":"Event Location","description":"Event Description","eventType":"Type","hostUsername":"hostuser","hostProfileUrl":"http://example.com/profile.jpg","profileName":"Host Name","bookmarked":false,"attending":true,"isHost":true,"host":"host-id"}}'

*/
