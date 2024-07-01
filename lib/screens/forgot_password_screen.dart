import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:nomo/screens/login_screen.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailC = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: emailC,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Email',
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) =>
                    !EmailValidator.validate(value!) ? 'Invalid Email!' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          Center(child: CircularProgressIndicator()),
                    );

                    try {
                      await supabase.auth.resetPasswordForEmail(emailC.text);
                      Navigator.of(context, rootNavigator: true).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Check your email for reset instructions.'),
                        ),
                      );
                    } catch (e) {
                      Navigator.of(context, rootNavigator: true).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Send Reset Email'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResetPasswordScreen(),
                    ),
                  );
                },
                child: const Text('Already have a token? Reset your password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
