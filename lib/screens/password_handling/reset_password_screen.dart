import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/screens/password_handling/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final emailC = TextEditingController();
  final passwordC = TextEditingController();
  final passwordConfirmC = TextEditingController();
  final resetTokenC = TextEditingController();
  bool _passwordVisible = true;
  bool _confirmPassVisible = true;
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.canvasColor,
      appBar: AppBar(
        title: Text(
          'Reset Password',
          style: TextStyle(color: theme.primaryColor, fontSize: 30, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Text(
                  'Enter your details to reset your password',
                  style: TextStyle(color: theme.colorScheme.onSecondary, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  controller: resetTokenC,
                  hintText: 'Reset Code',
                  icon: Icons.token,
                  validator: (value) {
                    if (value!.isEmpty || value.length < 6) {
                      return 'Invalid token!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: emailC,
                  hintText: 'Email',
                  icon: Icons.email,
                  validator: (value) => !EmailValidator.validate(value!) ? 'Invalid Email!' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: passwordC,
                  hintText: 'New Password',
                  icon: Icons.lock,
                  obscureText: _passwordVisible,
                  toggleVisibility: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                  validator: (value) {
                    if (value!.isEmpty || value.length < 6) {
                      return 'Password must be at least 6 characters!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: passwordConfirmC,
                  hintText: 'Confirm Password',
                  icon: Icons.lock_clock,
                  obscureText: _confirmPassVisible,
                  toggleVisibility: () {
                    setState(() {
                      _confirmPassVisible = !_confirmPassVisible;
                    });
                  },
                  validator: (value) {
                    if (value != passwordC.text) {
                      return 'Passwords do not match!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _resetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Reset Password',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Builds all of the text fields used in this screen with various details.
// Handles toggling text visibility and validation each individual field
//
// Parameters:
// - 'icon': tapped to toggle text visibility
// - 'obscureText'(optional): set to false by default (text visible)
// - 'toggleVisibility'(optional): function to handle toggling text visibility (typically sets obscureText = !obscureText)
// - 'validator'(optional): checks validity of text extered for a specific field (character count, matching with another field, etc.)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    VoidCallback? toggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        hintText: hintText,
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        suffixIcon: toggleVisibility != null
            ? IconButton(
                onPressed: toggleVisibility,
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Theme.of(context).primaryColor,
                ),
              )
            : null,
      ),
      validator: validator,
    );
  }

// Handles password reset logic. If entered token is valid and passwords match, sets new password and automatically logs user in
  void _resetPassword() async {
    if (formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();
      showDialog(
        context: context,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      try {
        final recovery = await supabase.auth.verifyOTP(
          email: emailC.text,
          token: resetTokenC.text,
          type: OtpType.recovery,
        );

        if (recovery.user != null) {
          await supabase.auth.updateUser(
            UserAttributes(password: passwordC.text),
          );
          try {
            final signInResponse = await supabase.auth.signInWithPassword(
              email: emailC.text,
              password: passwordC.text,
            );
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password reset successful. You are now logged in.'),
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const NavBar(),
              ),
            );
          } catch (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login failed: $error'),
              ),
            );
          }
        } else {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid token or email.'),
            ),
          );
        }
      } catch (e) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
          ),
        );
      }
    }
  }
}
