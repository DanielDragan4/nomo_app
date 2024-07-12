import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nomo/functions/make-fcm.dart';
import 'package:nomo/providers/saved_session_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/providers/user_signup_provider.dart';
import 'package:nomo/screens/forgot_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() {
    return _LoginScreenState();
  }
}

final supabase = Supabase.instance.client;

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();

  void _submit(String email, bool login, String pass) async {
    final isValid = _form.currentState!.validate();

    try {
      ref
          .watch(currentUserProvider.notifier)
          .submit(email, login, pass, isValid);

      if (!login) {
        ref.watch(onSignUp.notifier).notifyAccountCreation();
      }
    } catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication Failed'),
        ),
      );
    }
    ref.read(savedSessionProvider.notifier).changeSessionDataList();
  }

  var isLogin = true;
  TextEditingController emailC = TextEditingController();
  TextEditingController passC = TextEditingController();
  TextEditingController passConfirmC = TextEditingController();
  final isAuthenticating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/logo.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(
                                labelText: "Email Address"),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            controller: emailC,
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSecondary),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            decoration:
                                const InputDecoration(labelText: "Password"),
                            obscureText: true,
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSecondary),
                            controller: passC,
                            validator: (value) {
                              if (value == null || value.trim().length < 8) {
                                return 'Password must be at least 8 characters long.';
                              }
                              return null;
                            },
                          ),
                          if (!isLogin)
                            TextFormField(
                              decoration: const InputDecoration(
                                  labelText: "Confirm Password"),
                              obscureText: true,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondary),
                              controller: passConfirmC,
                              validator: (value) {
                                if (value != passC.text) {
                                  return 'Passwords do not match!';
                                }
                                return null;
                              },
                            ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ForgotPasswordScreen()),
                                );
                              },
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          if (isAuthenticating)
                            const CircularProgressIndicator(),
                          if (!isAuthenticating)
                            ElevatedButton(
                              onPressed: () {
                                _submit(emailC.text, isLogin, passC.text);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              child: Text(isLogin ? 'Login' : 'Signup'),
                            ),
                          if (!isAuthenticating)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  isLogin = !isLogin;
                                });
                              },
                              child: Text(isLogin
                                  ? 'Create an Account'
                                  : 'I already have an account.'),
                            ),
                          ElevatedButton(
                              onPressed: () async {
                                const webClientId =
                                    '360184712841-clbo4mf1nmbkitr4of35spnmcrsqidgq.apps.googleusercontent.com';
                                const iosClientId =
                                    '360184712841-mh9s1b58m7afvd7b06gbf2l5lssi8622.apps.googleusercontent.com';

                                // Google sign in on Android will work without providing the Android
                                // Client ID registered on Google Cloud.

                                final GoogleSignIn googleSignIn = GoogleSignIn(
                                  clientId: iosClientId,
                                  serverClientId: webClientId,
                                );
                                final googleUser = await googleSignIn.signIn();
                                final googleAuth =
                                    await googleUser!.authentication;
                                final accessToken = googleAuth.accessToken;
                                final idToken = googleAuth.idToken;

                                if (accessToken == null) {
                                  throw 'No Access Token found.';
                                }
                                if (idToken == null) {
                                  throw 'No ID Token found.';
                                }
                                bool firstSignIn = await ref
                                    .read(currentUserProvider.notifier)
                                    .signInWithIdToken(idToken, accessToken);

                                if (firstSignIn) {
                                  ref
                                      .watch(onSignUp.notifier)
                                      .notifyAccountCreation();
                                } else {
                                  makeFcm(supabase);
                                }
                                ref
                                    .read(savedSessionProvider.notifier)
                                    .changeSessionDataList();
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width * .38,
                                child: Row(
                                  children: [
                                    Image.asset(
                                      'assets/images/google_PNG19635.png',
                                      fit: BoxFit.cover,
                                      scale: MediaQuery.of(context)
                                              .size
                                              .aspectRatio *
                                          100,
                                    ),
                                    Text('Sign in with Google')
                                  ],
                                ),
                              ))
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
