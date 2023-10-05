import 'package:flutter/material.dart';
import 'package:nomo/screens/home_screen.dart';
import 'package:nomo/screens/login_screen.dart';

// this is test commit

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterChat',
      theme: ThemeData().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 2, 42, 41)),
      ),
      home: const LoginScreen(),
    );
  }
}
