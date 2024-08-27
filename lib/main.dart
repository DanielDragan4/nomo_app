import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomo/functions/make-fcm.dart';
import 'package:nomo/functions/notification-utils.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/event-providers/events_provider.dart';
import 'package:nomo/providers/location-providers/location_on_reload_service.dart';
import 'package:nomo/providers/notification-providers/notification-provider.dart';
import 'package:nomo/providers/supabase-providers/saved_session_provider.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';
import 'package:nomo/providers/theme_provider.dart';
import 'package:nomo/providers/supabase-providers/user_signup_provider.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/screens/profile/create_account_screen.dart';
import 'package:nomo/screens/password_handling/login_screen.dart';
import 'package:nomo/screens/events/detailed_event_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nomo/firebase_options.dart';
import 'package:nomo/screens/recommended_screen.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

final routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  _AppState createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  StreamSubscription<Map>? streamSubscription;
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  void navigateToEvent(String eventId) async {
    // Implement navigation logic to DetailedEventScreen
    Event eventData = await ref.read(eventsProvider.notifier).deCodeLinkEvent(eventId);
    navigatorKey.currentState?.push(MaterialPageRoute(
      builder: (context) => DetailedEventScreen(eventData: eventData),
    ));
  }

  void initBranch() async {
    await FlutterBranchSdk.init(
        useTestKey: true, // Use this for beta testing
        enableLogging: true,
        disableTracking: false);
  }

  @override
  void initState() {
    super.initState();
    checkProfile();
    // streamSubscription = FlutterBranchSdk.listSession().listen((data) {
    //   if (data.containsKey("+clicked_branch_link") && data["+clicked_branch_link"] == true) {
    //     String eventId = data["event_id"];
    //     navigateToEvent(eventId);
    //   }
    // }, onError: (error) {
    //   print('listSession error: ${error.toString()}');
    // });

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

  void setSystemOverlay(Color color) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        systemNavigationBarColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void loadData() {
      ref.read(savedSessionProvider.notifier).changeSessionDataList();
    }

    final supabase = ref.watch(supabaseClientProvider);
    ref.read(appInitializationProvider);

    Widget content = supabase.when(
      data: (client) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            navigatorObservers: [routeObserver],
            themeMode: ref.read(themeModeProvider),
            theme: ThemeData().copyWith(
              appBarTheme: const AppBarTheme(
                backgroundColor: const Color.fromARGB(255, 241, 242, 245),
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
              ),
              colorScheme: ColorScheme.fromSeed(
                primary: const Color.fromARGB(255, 106, 13, 173), // seen on 'Join' button in detailed view
                onPrimary: Colors.black, // text on 'Join' button
                secondary: Color.fromARGB(255, 207, 209, 213), // seen on 'Bookmark' + distance box in detailed view
                onSecondary: const Color.fromARGB(255, 75, 85, 99), // bookmark + distance icon color
                seedColor: const Color.fromARGB(255, 106, 13, 173), // same as primary
                primaryContainer: const Color.fromARGB(255, 241, 242, 245), // seen on comments box
                onPrimaryContainer:
                    const Color.fromARGB(255, 3, 7, 18), // comments title (use onSecondary for detail text)
                surface: const Color.fromARGB(255, 241, 242, 245), // page color of detailed view
                onSurface: const Color.fromARGB(255, 3, 7, 18),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                selectedItemColor: Color.fromARGB(255, 142, 57, 202), // navabar selected icon (center uses primary)
                unselectedItemColor: Color.fromARGB(255, 173, 177, 184), // navbar unselected icon
                backgroundColor:
                    Color.fromARGB(255, 255, 255, 255), // border necessary with Color.fromARGB(255, 241, 243, 245),
              ),
              cardColor: Color.fromARGB(255, 227, 229, 231),
              textTheme: GoogleFonts.nunitoTextTheme(
                const TextTheme(
                  titleMedium: TextStyle(
                    // comments title + user
                    color: Color.fromARGB(255, 3, 7, 18),
                  ),
                  bodyMedium: TextStyle(
                    // details + comments text (same as onSecondary)
                    color: Color.fromARGB(255, 75, 85, 99),
                  ),
                  labelMedium: TextStyle(
                    // text color on purple button
                    color: Colors.white,
                  ),
                ),
              ),
              primaryColor: const Color.fromARGB(255, 106, 13, 173), // same as primary
              primaryColorLight: const Color.fromARGB(255, 169, 78, 219), // seen on search toggle
              canvasColor: Colors.white, // scaffold color on all light mode screens
            ),
            darkTheme: ThemeData().copyWith(
              appBarTheme: const AppBarTheme(
                backgroundColor: const Color.fromARGB(255, 27, 27, 31),
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
              ),
              colorScheme: ColorScheme.fromSeed(
                primary: const Color.fromARGB(255, 106, 13, 173), // seen on 'Join' button in detailed view
                onPrimary: Colors.white,
                secondary: const Color.fromARGB(255, 53, 55, 60), // seen on 'Bookmark' + distance box in detailed view
                onSecondary: const Color.fromARGB(255, 173, 177, 184), // bookmark + distance icon color
                seedColor: const Color.fromARGB(255, 106, 13, 173), // same as primary
                primaryContainer: const Color.fromARGB(255, 36, 36, 45), // seen on comments box
                onPrimaryContainer:
                    const Color.fromARGB(255, 237, 238, 240), // comments title (use onSecondary for detail text)
                surface: const Color.fromARGB(255, 27, 27, 31), // page color of detailed view
                onSurface: const Color.fromARGB(255, 237, 238, 240),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                selectedItemColor: Color.fromARGB(255, 142, 57, 202), // navabar selected icon (center uses primary)
                unselectedItemColor: Color.fromARGB(255, 173, 177, 184), // navbar unselected icon
                backgroundColor: Color.fromARGB(255, 24, 24, 26), // no border
              ),
              cardColor: const Color.fromARGB(255, 36, 36, 45),
              textTheme: GoogleFonts.nunitoTextTheme(
                const TextTheme(
                  titleMedium: TextStyle(
                    // comments title + user
                    color: Color.fromARGB(255, 237, 238, 240),
                  ),
                  bodyMedium: TextStyle(
                    // details + comments text (same as onSecondary)
                    color: Color.fromARGB(255, 173, 177, 184),
                  ),
                  labelMedium: TextStyle(
                    // text color on purple button
                    color: Colors.white,
                  ),
                ),
              ),
              datePickerTheme: const DatePickerThemeData(
                headerBackgroundColor: Color.fromARGB(255, 142, 57, 202),
                headerForegroundColor: Colors.white,
                backgroundColor: Color.fromARGB(255, 53, 55, 60),
              ),
              // textButtonTheme: TextButtonThemeData(
              //     style: TextButton.styleFrom(
              //   foregroundColor: Colors.white,
              // )),

              primaryColor: const Color.fromARGB(255, 106, 13, 173), // same as primary
              primaryColorLight: const Color.fromARGB(255, 142, 57, 202), // seen on search toggle
              canvasColor: Color.fromARGB(255, 27, 27, 31), // scaffold color on all light mode screens
            ),
            home: StreamBuilder(
              stream: ref.watch(currentUserProvider.notifier).stream,
              builder: (context, snapshot) {
                setSystemOverlay(Theme.of(context).bottomNavigationBarTheme.backgroundColor!);
                if (ref.watch(onSignUp.notifier).state == 1) {
                  return CreateAccountScreen(
                    isNew: true,
                  );
                } else if (snapshot.data != null ||
                    (ref.watch(savedSessionProvider) != null && ref.watch(savedSessionProvider)!.isNotEmpty)) {
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
