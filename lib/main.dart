import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:nomo/providers/saved_session_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/providers/user_signup_provider.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/screens/create_account_screen.dart';
import 'package:nomo/screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nomo/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool isFcmInitialized = false;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(child: App()),
  );
}

Future<void> _setFcmToken(String fcmToken, SupabaseClient client) async {
  final userId = client.auth.currentUser?.id;
  if (userId != null) {
    await client.from('Profiles').upsert({
      'profile_id': userId,
      'fcm_token': fcmToken,
    });
  }
}

Future<void> _makeFcm(SupabaseClient client) async {
  if (!isFcmInitialized) {
    isFcmInitialized = true;
    client.auth.onAuthStateChange.listen((event) async {
      if (event.event == AuthChangeEvent.signedIn) {
        await FirebaseMessaging.instance.requestPermission();
        await FirebaseMessaging.instance.getAPNSToken();
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _setFcmToken(fcmToken, client);
        }
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (fcmToken) async {
        await _setFcmToken(fcmToken, client);
      },
    );
  }
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabase = ref.watch(supabaseClientProvider);

    void loadData() {
      ref.read(savedSessionProvider.notifier).changeSessionDataList();
      //ref.read(eventsProvider.notifier).deCodeData();
      //ref.read(attendEventsProvider.notifier).deCodeData();
      //ref.read(profileProvider.notifier).decodeData();
    }

    Widget content = supabase.when(
      data: (client) {
        _makeFcm(client);
        return GestureDetector(
          //tapping outside of textField closes keyboard (all screens)
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: MaterialApp(
            themeMode: ThemeMode.system,
            theme: ThemeData().copyWith(
              colorScheme: ColorScheme.fromSeed(
                  onSecondary: Colors.black,
                  seedColor: const Color.fromARGB(255, 80, 12, 122),
                  onPrimaryContainer: const Color.fromARGB(255, 80, 12, 122)),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                selectedItemColor: Color.fromARGB(255, 80, 12, 122),
                unselectedItemColor: Colors.grey,
              ),
              primaryColor: const Color.fromARGB(255, 80, 12, 122),
            ),
            darkTheme: ThemeData().copyWith(
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  selectedItemColor: Color.fromARGB(255, 109, 51, 146),
                  unselectedItemColor: Color.fromARGB(255, 206, 206, 206),
                  backgroundColor: Colors.black,
                ),
                primaryColor: Color.fromARGB(255, 109, 51, 146),
                canvasColor: Colors.black,
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                        onSecondary: Color.fromARGB(255, 206, 206, 206),
                        background: Colors.black,
                        brightness: Brightness.dark,
                        seedColor: Color.fromARGB(255, 109, 51, 146),
                        onPrimaryContainer: Color.fromARGB(255, 109, 51, 146))
                    .copyWith(background: Colors.black)),
            home: StreamBuilder(
              stream: ref.watch(currentUserProvider.notifier).stream,
              builder: (context, snapshot) {
                if (ref.watch(onSignUp.notifier).state == 1) {
                  return CreateAccountScreen(
                    isNew: true,
                  );
                } else if (snapshot.data != null ||
                    (ref.watch(savedSessionProvider) != null &&
                        ref.watch(savedSessionProvider)!.isNotEmpty)) {
                  loadData();
                  return const NavBar();
                } else {
                  loadData();
                  return const LoginScreen();
                }
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );

    return content;
  }
}
