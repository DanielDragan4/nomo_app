import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {

    print(Theme.of(context).primaryColor);



    return MaterialApp(
      title: 'FlutterChat',
      theme: ThemeData().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Color.fromARGB(255, 0, 71, 79),
            onPrimaryContainer:  Color.fromARGB(255, 0, 71, 79)),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color.fromARGB(255, 0, 71, 79),
          unselectedItemColor: Colors.grey,
        ),
        primaryColor: Color.fromARGB(255, 0, 71, 79),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          if (snapshot.hasData) {
            return const NavBar();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
