import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/profile_model.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileProvider extends StateNotifier<Profile?> {
  ProfileProvider({required this.supabase}) : super(null);

  Future<Supabase> supabase;

  Future<Map> readProfile() async {
    final supabaseClient = (await supabase).client;
    Map profile = {};
    profile = (await supabaseClient
        .from('profile_view')
        .select('*, Interests(interests)')
        .eq('profile_id', supabaseClient.auth.currentUser!.id)
        .single());
    return profile;
  }

  Future<void> decodeData() async {
    final userProfile = await readProfile();
    Profile profile;
    final supabaseClient = (await supabase).client;
    print(userProfile['recommended_events']);

    String profileUrl = supabaseClient.storage
          .from('Images')
          .getPublicUrl(userProfile['profile_path']);

    profile = (Profile(
        profile_id: userProfile['profile_id'],
        avatar: profileUrl,
        username: userProfile['username'],
        profile_name: userProfile['profile_name'],
        interests: userProfile['Interests']));
    state = profile;
  }
}

final profileProvider = StateNotifierProvider<ProfileProvider, Profile?>((ref) {
  final supabase = ref.read(supabaseInstance);
  return ProfileProvider(supabase: supabase);
});
