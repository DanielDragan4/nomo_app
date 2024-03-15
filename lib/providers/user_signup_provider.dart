import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignUpProvider extends StateNotifier<int?> {
  SignUpProvider({initialSave}) : super(null);

  void notifyAccountCreation() {
    state = 1;
  }

  void completeProfileCreation() {
    state = 2;
  }
}

final onSignUp = StateNotifierProvider<SignUpProvider, int?>((ref) {
  return SignUpProvider(initialSave: null);
});
