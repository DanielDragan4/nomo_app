// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
// <reference types="https://esm.sh/@supabase/functions-js/src/edge-runtime.d.ts" />

console.log("Hello from Functions!")

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

  const {data} = await supabase.from('Profiles').select('fcm_token').eq('profile_id', payload.record.host).single()

  const fcmToken = data!.fcm_token as string

  const {default: serviceAccount} = await import('../service-account.json', {
    with: { type: 'json' },
  })

  const accessToken = await getAccessToken({clientEmail: serviceAccount.client_email, privateKey: serviceAccount.private_key,})



  const res = await fetch(`https://fcm.googleapis.com/v1/projects/nomo-app-c3417/messages:send`, 
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: {
            title: `Event Created`,
            body: `Event: "${payload.record.title}" has been created`
          }
        }
      })
    }
  )

  const resData = await res.json()
  if(res.status < 200 || 299 < res.status) {
    throw resData
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
      if(err) {
        reject(err)
        return;
      }
      resolve(tokens!.access_token!)
    })
  })
}

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/event-deleted' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
