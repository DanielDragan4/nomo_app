import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool isFcmInitialized = false;

Future<void> setFcmToken(String fcmToken, SupabaseClient client) async {
  final userId = client.auth.currentUser?.id.toString();
  if (userId != null) {
    print('$userId');
    await client.from('Profiles').update({
      'fcm_token': fcmToken,
    }).eq('profile_id', client.auth.currentUser!.id);
  }
}

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
