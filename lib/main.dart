import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomo/functions/make-fcm.dart';
import 'package:nomo/functions/notification-utils.dart';
import 'package:nomo/providers/location_on_reload_service.dart';
import 'package:nomo/providers/notification-provider.dart';
import 'package:nomo/providers/saved_session_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/providers/theme_provider.dart';
import 'package:nomo/providers/user_signup_provider.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/screens/create_account_screen.dart';
import 'package:nomo/screens/login_screen.dart';
import 'package:nomo/screens/detailed_event_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nomo/firebase_options.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request location permission
  var status = await Permission.location.request();

  await getCurrentPosition();

  // Handle the response
  if (status.isGranted) {
    print('Location permission granted');
  } else {
    print('Location permission denied');
  }

  await FlutterBranchSdk.init(enableLogging: false, disableTracking: false);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SharedPreferences.getInstance();

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
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

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

    firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      handleMessage(message, context, ref);
    });
  }

  @override
  void dispose() {
    streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supabase = ref.watch(supabaseClientProvider);
    ref.read(appInitializationProvider);

    void loadData() {
      ref.read(savedSessionProvider.notifier).changeSessionDataList();
    }

    Widget content = supabase.when(
      data: (client) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [routeObserver],
            themeMode: ref.read(themeModeProvider),
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
                primaryColorLight: Color.fromARGB(255, 202, 141, 237),
                canvasColor: Colors.white),
            darkTheme: ThemeData().copyWith(
              cardColor: Color.fromARGB(255, 27, 27, 27),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                selectedItemColor: Color.fromARGB(255, 109, 51, 146),
                unselectedItemColor: Color.fromARGB(255, 206, 206, 206),
                backgroundColor: Colors.black,
              ),
              primaryColor: const Color.fromARGB(255, 109, 51, 146),
              primaryColorLight: Color.fromARGB(255, 202, 141, 237),
              canvasColor: Colors.black,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                      onSecondary: const Color.fromARGB(255, 206, 206, 206),
                      surface: Colors.black,
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
                  makeFcm(client);
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
