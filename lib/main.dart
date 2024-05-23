import 'package:flutter/material.dart';
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
      ref.read(savedSessionProvider.notifier).changeSessionDataList();
      //ref.read(eventsProvider.notifier).deCodeData();
      //ref.read(attendEventsProvider.notifier).deCodeData();
      //ref.read(profileProvider.notifier).decodeData();
    }

    return GestureDetector(
      //tapping outside of textField closes keyboard (all screens)
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp(
        themeMode: ThemeMode.system,
        theme: ThemeData().copyWith(
          colorScheme: ColorScheme.fromSeed(
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
            selectedItemColor: Color.fromARGB(255, 80, 12, 122),
            unselectedItemColor: Color.fromARGB(255, 206, 206, 206),
            backgroundColor: Colors.black
          ),
          primaryColor: const Color.fromARGB(255, 80, 12, 122),
          brightness: Brightness.dark, colorScheme: ColorScheme.fromSeed(
            background: Colors.black,
              seedColor: const Color.fromARGB(255, 80, 12, 122),
              onPrimaryContainer: const Color.fromARGB(255, 80, 12, 122)).copyWith(background: Colors.black)
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
  }
}
