import 'package:flutter/material.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  runApp(
    const ProviderScope(child: App()),
  );
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        theme: ThemeData().copyWith(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 0, 71, 79),
              onPrimaryContainer: const Color.fromARGB(255, 0, 71, 79)),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: Color.fromARGB(255, 0, 71, 79),
            unselectedItemColor: Colors.grey,
          ),
          primaryColor: const Color.fromARGB(255, 0, 71, 79),
        ),
        home: StreamBuilder(
          stream: ref.watch(currentUserProvider.notifier).stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return const NavBar();
            } else {
              return const LoginScreen();
            }
          },
        ));
  }
}
