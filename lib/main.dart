import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomo/providers/chat_id_provider.dart';
import 'package:nomo/providers/saved_session_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/providers/user_signup_provider.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/screens/create_account_screen.dart';
import 'package:nomo/screens/login_screen.dart';
import 'package:nomo/screens/detailed_event_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nomo/firebase_options.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool isFcmInitialized = false;

final routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterBranchSdk.init(enableLogging: false, disableTracking: false);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const OverlaySupport.global(child: ProviderScope(child: App())),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void navigateToEvent(String eventId) {
  // Implement navigation logic to DetailedEventScreen
  navigatorKey.currentState?.push(MaterialPageRoute(
    builder: (context) => DetailedEventScreen(linkEventId: eventId),
  ));
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  _AppState createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  StreamSubscription<Map>? streamSubscription;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  void showSimpleNotification(
      BuildContext context, String message, String sender,
      {Color background = const Color.fromARGB(255, 109, 51, 146)}) {
    showOverlayNotification(
      (context) {
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 4),
          color: background,
          child: SafeArea(
            child: ListTile(
              leading: Icon(Icons.message, color: Colors.white),
              title: Text(
                sender,
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
              trailing: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  OverlaySupportEntry.of(context)?.dismiss();
                },
              ),
            ),
          ),
        );
      },
      duration: Duration(seconds: 5),
    );
  }

  @override
  void initState() {
    super.initState();
    streamSubscription = FlutterBranchSdk.listSession().listen((data) {
      if (data.containsKey("+clicked_branch_link") &&
          data["+clicked_branch_link"] == true) {
        String eventId = data["event_id"];
        navigateToEvent(eventId);
      }
    }, onError: (error) {
      print('listSession error: ${error.toString()}');
    });

    _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received message: ${message.notification?.title}");
      print("Message data: ${message.data}");

      String? chatId = message.data['chat_id'];
      String? activeChatId = ref.read(activeChatIdProvider);
      print('active: $activeChatId');
      print('current: $chatId');

      if (activeChatId != chatId || activeChatId == null) {
        showSimpleNotification(context,
            message.data['message'] ?? 'New Message', message.data['sender']);
      }
    });
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final supabase = ref.watch(supabaseClientProvider);

    void loadData() {
      ref.read(savedSessionProvider.notifier).changeSessionDataList();
    }

    Widget content = supabase.when(
      data: (client) {
        _makeFcm(client);
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [routeObserver],
            themeMode: ThemeMode.system,
            theme: ThemeData().copyWith(
              colorScheme: ColorScheme.fromSeed(
                  onSecondary: Colors.black,
                  seedColor: const Color.fromARGB(255, 80, 12, 122),
                  onPrimaryContainer: const Color.fromARGB(255, 80, 12, 122)),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                selectedItemColor: Color.fromARGB(255, 80, 12, 122),
                unselectedItemColor: Color.fromARGB(255, 158, 158, 158),
              ),
              textTheme: GoogleFonts.nunitoTextTheme(),
              primaryColor: const Color.fromARGB(255, 80, 12, 122),
            ),
            darkTheme: ThemeData().copyWith(
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                selectedItemColor: Color.fromARGB(255, 109, 51, 146),
                unselectedItemColor: Color.fromARGB(255, 206, 206, 206),
                backgroundColor: Colors.black,
              ),
              primaryColor: const Color.fromARGB(255, 109, 51, 146),
              canvasColor: Colors.black,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                      onSecondary: const Color.fromARGB(255, 206, 206, 206),
                      background: Colors.black,
                      brightness: Brightness.dark,
                      seedColor: const Color.fromARGB(255, 109, 51, 146),
                      onPrimaryContainer:
                          const Color.fromARGB(255, 109, 51, 146))
                  .copyWith(surface: Colors.black),
              textTheme: GoogleFonts.nunitoTextTheme(),
            ),
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
