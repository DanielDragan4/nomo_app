import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool isFcmInitialized = false;

// Initializes Firebase Cloud Messaging (FCM) and manages FCM token updates
// for sending push notifications. Listens for auth state changes
// to handle token updates when a user signs in or when the token refreshes by signing in to another device.
// Calls setFcmToken to update user's token in the database

Future<void> makeFcm(SupabaseClient client) async {
  if (!isFcmInitialized) {
    isFcmInitialized = true;
    client.auth.onAuthStateChange.listen((event) async {
      if (event.event == AuthChangeEvent.signedIn) {
        await FirebaseMessaging.instance.requestPermission();
        await FirebaseMessaging.instance.getAPNSToken();
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await setFcmToken(fcmToken, client);
        }
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (fcmToken) async {
        await setFcmToken(fcmToken, client);
      },
    );
  }
}

// Inserts provided fcmToken into user's row in 'Profiles' table in Supabase
// Parameters:
// - 'fcmToken': The Firebase Messaging token retrieved by makeFcm, set to be updated in current user's Profile

Future<void> setFcmToken(String fcmToken, SupabaseClient client) async {
  final userId = client.auth.currentUser?.id.toString();
  if (userId != null) {
    print('$userId');
    await client.from('Profiles').update({
      'fcm_token': fcmToken,
    }).eq('profile_id', client.auth.currentUser!.id);
  }
}
