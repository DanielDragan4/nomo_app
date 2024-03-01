import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseInstance = Supabase.initialize(
  url: 'https://empbcnqichgibqjsidlc.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVtcGJjbnFpY2hnaWJxanNpZGxjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDkwMDMwNjUsImV4cCI6MjAyNDU3OTA2NX0.UNTuYSYy931_9J_iNpeOoZzL25_5HarmhrsQqQDwKWk',
);

class AuthProvider extends StateNotifier<User?> {
  AuthProvider() : super(null);

   void submit(String email, bool isLogin, String pass, bool isValid) async {
    final Supabase db = await supabaseInstance;

      if (!isValid) {
        return;
      }
    try {
      if (isLogin) {
          final AuthResponse res = await db.client.auth.signInWithPassword(email: email, password: pass,);
          state = res.user; 
        }
      else {
        final AuthResponse res = await db.client.auth.signUp(email: email, password: pass,);
        state = res.user;
    }
    }
    catch(error){
      return;
    }
  }
}

final currentUserProvider = StateNotifierProvider<AuthProvider, User?>((ref) {
  return AuthProvider();
  }
);
