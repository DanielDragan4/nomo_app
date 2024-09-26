import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nomo/functions/make-fcm.dart';
import 'package:nomo/providers/simplified_view_provider.dart';
import 'package:nomo/providers/supabase-providers/saved_session_provider.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';
import 'package:nomo/providers/supabase-providers/user_signup_provider.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/screens/password_handling/forgot_password_screen.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  LoginScreen({
    super.key,
    this.creating,
  });

  bool? creating;

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

    if (!isValid) {
      return;
    }

    setState(() {
      isAuthenticating = true;
    });

    try {
      await ref.read(currentUserProvider.notifier).submit(email, login, pass, isValid);

      if (!login) {
        ref.read(onSignUp.notifier).notifyAccountCreation();
      }

      setState(() {
        _emailError = false;
        _passwordError = false;
        _emailErrorText = '';
        _passwordErrorText = '';
      });

      ref.read(guestModeProvider.notifier).setGuestMode(false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const NavBar()),
      );
    } on AuthException catch (error) {
      setState(() {
        if (error.message.contains('Invalid login credentials')) {
          _emailError = true;
          _passwordError = true;
          _emailErrorText = 'Invalid Credentials';
          _passwordErrorText = 'Invalid Credentials';
        } else if (error.message.contains('Email not confirmed')) {
          _emailError = true;
          _emailErrorText = 'Please confirm your email';
        } else {
          _emailError = true;
          _passwordError = true;
          _emailErrorText = error.message;
          _passwordErrorText = error.message;
        }
      });
    } catch (error) {
      setState(() {
        _emailError = true;
        _passwordError = true;
        _emailErrorText = 'An unexpected error occurred';
        _passwordErrorText = 'An unexpected error occurred';
      });
    } finally {
      setState(() {
        isAuthenticating = false;
      });
    }
    ref.read(savedSessionProvider.notifier).changeSessionDataList();
  }

  void _continueAsGuest() {
    print('continuing as guest!_____________________________________');
    ref.read(guestModeProvider.notifier).setGuestMode(true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const NavBar()),
    );
  }

  var isLogin = true;
  TextEditingController emailC = TextEditingController();
  TextEditingController passC = TextEditingController();
  TextEditingController passConfirmC = TextEditingController();
  bool _obscurePass = true;
  bool _obscurePassConfirm = true;
  bool isAuthenticating = false;
  bool _emailError = false;
  bool _passwordError = false;
  String _emailErrorText = '';
  String _passwordErrorText = '';

  @override
  Widget build(BuildContext context) {
    if (widget.creating != null) {
      setState(() {
        isLogin = false;
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: "Email Address",
                                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                errorText: _emailError ? _emailErrorText : null,
                                errorStyle: TextStyle(color: Colors.red),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: _emailError ? Colors.red : Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: _emailError ? Colors.red : Theme.of(context).primaryColor),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              controller: emailC,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty || !value.contains('@')) {
                                  return 'Please enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: "Password",
                                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                errorText: _passwordError ? _passwordErrorText : null,
                                errorStyle: TextStyle(color: Colors.red),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: _passwordError ? Colors.red : Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: _passwordError ? Colors.red : Theme.of(context).primaryColor),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    _obscurePass = !_obscurePass;
                                    setState(() {});
                                  },
                                  icon: _obscurePass == true
                                      ? Icon(Icons.visibility, color: Theme.of(context).colorScheme.onSurface)
                                      : Icon(Icons.visibility_off, color: Theme.of(context).colorScheme.onSurface),
                                ),
                              ),
                              obscureText: _obscurePass,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                              controller: passC,
                              validator: (value) {
                                if (value == null || value.trim().length < 8) {
                                  return 'Password must be at least 8 characters long.';
                                }
                                return null;
                              },
                            ),
                          ),
                          if (!isLogin)
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: "Confirm Password",
                                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                errorText: _passwordError ? _passwordErrorText : null,
                                errorStyle: TextStyle(color: Colors.red),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: _passwordError ? Colors.red : Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: _passwordError ? Colors.red : Theme.of(context).primaryColor),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                suffixIcon: IconButton(
                                    onPressed: () {
                                      _obscurePassConfirm = !_obscurePassConfirm;
                                      setState(() {});
                                    },
                                    icon: _obscurePassConfirm == true
                                        ? Icon(Icons.visibility, color: Theme.of(context).colorScheme.onSurface)
                                        : Icon(Icons.visibility_off, color: Theme.of(context).colorScheme.onSurface)),
                              ),
                              obscureText: _obscurePassConfirm,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
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
                                  MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
                                );
                              },
                              child: Text('Forgot Password?',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          if (isAuthenticating) const CircularProgressIndicator(),
                          if (!isAuthenticating)
                            ElevatedButton(
                              onPressed: () {
                                _submit(emailC.text, isLogin, passC.text);
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor, // Background color
                                padding: EdgeInsets.symmetric(
                                    vertical: MediaQuery.of(context).size.height * .0085,
                                    horizontal: MediaQuery.of(context).size.width * 0.175),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                ),
                              ),
                              child: Text(isLogin ? 'Login' : 'Signup',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                            ),
                          if (!isAuthenticating)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  isLogin = !isLogin;
                                });
                              },
                              child: Text(
                                isLogin ? 'Create an Account' : 'I already have an account.',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              ),
                            ),
                          // ElevatedButton(
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: Theme.of(context).canvasColor,
                          //     ),
                          //     onPressed: () async {
                          //       final rawNonce = supabase.auth.generateRawNonce();
                          //       final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
                          //       final credential = await SignInWithApple.getAppleIDCredential(
                          //         scopes: [
                          //           AppleIDAuthorizationScopes.email,
                          //           AppleIDAuthorizationScopes.fullName,
                          //         ],
                          //         nonce: hashedNonce,
                          //       );

                          //       final idToken = credential.identityToken;
                          //       if (idToken == null) {
                          //         throw const AuthException('Could not find ID Token from generated credential.');
                          //       }
                          //       bool firstSignIn = await ref
                          //           .read(currentUserProvider.notifier)
                          //           .signInWithIdTokenApple(idToken, rawNonce);

                          //       if (firstSignIn) {
                          //         print('1');
                          //         ref.watch(onSignUp.notifier).notifyAccountCreation();
                          //       } else {
                          //         print('2');
                          //         makeFcm(supabase);
                          //       }
                          //       ref.read(savedSessionProvider.notifier).changeSessionDataList();

                          //       // Now send the credential (especially `credential.authorizationCode`) to your server to create a session
                          //       // after they have been validated with Apple (see `Integration` section for more information on how to do this)
                          //     },
                          //     child: Padding(
                          //       padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1),
                          //       child: Container(
                          //         child: Row(
                          //           mainAxisAlignment: MainAxisAlignment.center,
                          //           children: [
                          //             Image.asset(
                          //               'assets/images/apple.png',
                          //               fit: BoxFit.cover,
                          //               scale: MediaQuery.of(context).size.aspectRatio * 75,
                          //             ),
                          //             SizedBox(
                          //               width: MediaQuery.of(context).size.width * .01,
                          //             ),
                          //             Text(
                          //               'Sign in with Apple',
                          //               style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          //             )
                          //           ],
                          //         ),
                          //       ),
                          //     )),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).canvasColor,
                              ),
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
                                final googleAuth = await googleUser!.authentication;
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
                                  print('1');
                                  ref.watch(onSignUp.notifier).notifyAccountCreation();
                                } else {
                                  print('2');
                                  makeFcm(supabase);
                                }
                                ref.read(savedSessionProvider.notifier).changeSessionDataList();
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1),
                                child: Container(
                                  //width: MediaQuery.of(context).size.width * .40,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/google_PNG19635.png',
                                        fit: BoxFit.cover,
                                        scale: MediaQuery.of(context).size.aspectRatio * 100,
                                      ),
                                      Text(
                                        'Sign in with Google',
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                      )
                                    ],
                                  ),
                                ),
                              )),
                          if (!isAuthenticating)
                            TextButton(
                                onPressed: () {
                                  _continueAsGuest();
                                },
                                child: Text(
                                  'Continue as Guest',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                )),
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
