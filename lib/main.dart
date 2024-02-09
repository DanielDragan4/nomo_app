import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nomo/auth_service.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nomo/screens/splash.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(App());
}

class App extends StatelessWidget {
  App({super.key});

  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Color.fromARGB(255, 0, 71, 79),
            onPrimaryContainer: Color.fromARGB(255, 0, 71, 79)),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color.fromARGB(255, 0, 71, 79),
          unselectedItemColor: Colors.grey,
        ),
        primaryColor: Color.fromARGB(255, 0, 71, 79),
      ),
      home: StreamBuilder<User?>(
        stream: authService.userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          if (snapshot.hasData) {
            return NavBar();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
