import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseInstance = Provider((ref) {
  return Supabase.initialize(
  url: 'https://qyypchgcrxmdaioxndgb.supabase.co',
  anonKey:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF5eXBjaGdjcnhtZGFpb3huZGdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDk2ODY5MDMsImV4cCI6MjAyNTI2MjkwM30.pzMWpVoyvjxZiA4MvubbCseMo9tch_M7fSZliJxYG8Y',
    );
  }
);

class AuthProvider extends StateNotifier<Session?> {
  AuthProvider({required this.supabase}) : super(null);

  Future<Supabase> supabase;
  var session;

  void submit(String email, bool isLogin, String pass, bool isValid) async {
    if (!isValid) {
      return;
    }
    try {
      if (isLogin) {
        final AuthResponse res = await (await supabase).client.auth.signInWithPassword(
          email: email,
          password: pass,
        );
        state = res.session;
        saveData();
      } else {
        final AuthResponse res = await (await supabase).client.auth.signUp(
          email: email,
          password: pass,
        );
        state = res.session;
        saveData();
      }
    } catch (error) {
      return;
    }
  }

  void saveData() {
    SharedPreferences.getInstance().then((value) => value.setStringList("savedSession", [state!.accessToken, state!.user.id,]));
  }

  void signOut() async {
    try {
      await (await supabase).client.auth.signOut();
      state = null;
      final removeSession = await SharedPreferences.getInstance();
      removeSession.remove("savedSession");
    } 
    on AuthException catch (error) {
      return;
    } 
    catch (error) {
      return;
    } 
    finally {
      if (mounted) {
        session = null;
      }
    }
  }
}

final currentUserProvider = StateNotifierProvider<AuthProvider, Session?>((ref) {
  final supabase = ref.watch(supabaseInstance);
  return AuthProvider(supabase: supabase);
});

