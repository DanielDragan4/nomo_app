import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';
import 'package:nomo/screens/password_handling/forgot_password_screen.dart';

class AuthSetting extends ConsumerStatefulWidget {
  const AuthSetting({super.key});

  @override
  ConsumerState<AuthSetting> createState() {
    return _AuthSettingState();
  }
}

class _AuthSettingState extends ConsumerState<AuthSetting> {
  late String userEmail;

  Future<void> getUserEmail() async {
    final user = await (await ref.read(supabaseInstance)).client.auth.currentUser;
    userEmail = user!.email!;
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: ListView(
        children: [
          ListTile(
              title: Text(
            "Authentication Settings:",
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600, fontSize: MediaQuery.of(context).size.width / 24),
          )),
          ListTile(
              onTap: () {
                getUserEmail();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ForgotPasswordScreen(
                          email: userEmail,
                        )));
              },
              title: Text(
                "Change Password",
                style: theme.textTheme.titleMedium,
              )),
        ],
      ),
    );
  }
}
