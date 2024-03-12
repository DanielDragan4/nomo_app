import 'package:flutter/material.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/saved_session_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/providers/user_signup_provider.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/screens/create_account_screen.dart';
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
    void loadData() {
      ref.watch(savedSessionProvider.notifier).changeSessionDataList();
    }

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
            if (ref.watch(onSignUp.notifier).state == 1) {
              return const CreateAccountScreen();
            }
            else if (snapshot.data != null ||
                (ref.watch(savedSessionProvider) != null &&
                    ref.watch(savedSessionProvider)!.isNotEmpty)) {
              loadData();
              return const NavBar();
            } else {
              loadData();
              return const LoginScreen();
            }
          },
        ));
  }
}
