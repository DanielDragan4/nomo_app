import 'dart:async';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/password_handling/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseInstance = Provider((ref) {
  return Supabase.initialize(
    url: 'https://qyypchgcrxmdaioxndgb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF5eXBjaGdjcnhtZGFpb3huZGdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDk2ODY5MDMsImV4cCI6MjAyNTI2MjkwM30.pzMWpVoyvjxZiA4MvubbCseMo9tch_M7fSZliJxYG8Y',
  );
});

final supabaseClientProvider = FutureProvider<SupabaseClient>((ref) async {
  final supabase = ref.watch(supabaseInstance);
  return (await supabase).client;
});

class AuthProvider extends StateNotifier<Session?> {
  AuthProvider({required this.supabase}) : super(null);

  Future<Supabase> supabase;
  var session;

  void submit(String email, bool isLogin, String pass, bool isValid) async {
    /*
      submits a users credentials based on wether it is login or creating an account. THis 
      then creates a new session and saves it onto the phone.

      Params: String email, bool isLogin, String pass, bool isValid
      
      Returns: List<Map>
    */
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

  Future<bool> signInWithIdToken(idToken, accessToken) async {
    /*
      signs in with a provided idToken and accessToken with the session then being
      saved onto the phone.

      Params: idToken: string, accessToken: string
      
      Returns: bool
    */
    final AuthResponse res = await (await supabase).client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
    var user = await (await supabase).client.from('Profiles').select('profile_id').eq('profile_id', res.user!.id);

    state = res.session;
    saveData();

    if (user.isEmpty) {
      return true;
    }
    return false;
  }

  void saveData() {
    /*
      saves the sessions user and the access token onto the phones data.

      Params: none
      
      Returns: none
    */
    SharedPreferences.getInstance().then((value) => value.setStringList("savedSession", [
          state!.accessToken,
          state!.user.id,
        ]));
  }

  Future<void> removeFcm(String userId) async {
    /*
      removes the fcm token based on the user id's when the user signs out

      Params: userId: uuid
      
      Returns: none
    */
    final supabaseClient = (await supabase).client;
    await supabaseClient.from('Profiles').update({'fcm_token': null}).eq('profile_id', userId);
  }

  void signOut() async {
    /*
      signs the user out by ending the session and removing the session data off of the phone

      Params: none
      
      Returns: none
    */
    try {
      String userId = (await supabase).client.auth.currentUser!.id;
      await (await supabase).client.auth.signOut();
      await removeFcm(userId);
      state = null;
      final removeSession = await SharedPreferences.getInstance();
      removeSession.remove("savedSession");
    } on AuthException {
      return;
    } catch (error) {
      return;
    } finally {
      if (mounted) {
        session = null;
      }
    }
  }
  void deleteAccount() async {
    /*
      signs the user out by ending the session and removing the session data off of the phone

      Params: none
      
      Returns: none
    */
    try {
      String userId = (await supabase).client.auth.currentUser!.id;
      await (await supabase).client.from('Profile').delete().eq('profile_id', userId);
      await (await supabase).client.auth.admin.deleteUser(userId);

      state = null;
    } on AuthException {
      return;
    } catch (error) {
      return;
    } finally {
      if (mounted) {
        session = null;
      }
    }
  }
}


Future<void> checkProfile() async {
  /*
      Checks to see if the profile was fully set up before allowing for entry onto the app

      Params: none
      
      Returns: none
    */
  late final checkProf;
  if(supabase.auth.currentUser == null) {
    checkProf = null;
  }
  else {
   checkProf =
      await supabase.from("Profiles").select('profile_id, username').eq('profile_id', supabase.auth.currentUser!.id);
  }
  final removeSession = await SharedPreferences.getInstance();
  if (checkProf.isEmpty || checkProf == null) {
    removeSession.remove("savedSession");
    await supabase.from("auth.users").delete().eq('id', (supabase.auth.currentUser!.id));
  } else if ((checkProf.first['profile_id'] == supabase.auth.currentUser!.id) &&
      (checkProf.first['username'] == null)) {
    await supabase.from("Profiles").delete().eq('profile_id', (supabase.auth.currentUser!.id));
  }
}

final currentUserProvider = StateNotifierProvider<AuthProvider, Session?>((ref) {
  final supabase = ref.watch(supabaseInstance);
  checkProfile();
  return AuthProvider(supabase: supabase);
});