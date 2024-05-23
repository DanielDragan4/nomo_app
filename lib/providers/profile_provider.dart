import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/profile_model.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nomo/models/interests_enum.dart';

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

  Future<List> fetchExistingInterests() async {
    final supabaseClient = (await supabase).client;
    final userId = supabaseClient.auth.currentUser!.id;
    final response = await supabaseClient
        .from('Interests')
        .select('interests')
        .eq('user_id', userId);
    final List<dynamic> rows = response;
    final List<String> existingInterests =
        rows.map((row) => row['interests'].toString()).toList();

    print('Existing Interests: $existingInterests');
    return existingInterests;
  }

  Future<void> updateInterests(Map<Interests, bool> selectedInterests) async {
    final supabaseClient = (await supabase).client;
    final userId = supabaseClient.auth.currentUser!.id;

    // Clear existing interests if editing
    if (state?.interests != null) {
      await supabaseClient.from('Interests').delete().eq('user_id', userId);
    }

    // Get selected interests
    final newInterestsRows =
        selectedInterests.entries.where((entry) => entry.value).map((entry) {
      final interestString = enumToString(entry.key);
      return {
        'user_id': userId,
        'interests': interestString,
      };
    }).toList();

    // Insert new interests
    await supabaseClient.from('Interests').insert(newInterestsRows);
  }

  void skipInterests() async {
    final supabaseClient = (await supabase).client;

    final userId = supabaseClient.auth.currentUser!.id;

    // Clear existing interests if skipping
    await supabaseClient.from('Interests').delete().eq('user_id', userId);
  }

  String enumToString(interest) {
    final str = interest.toString().split('.').last;
    return str.replaceAllMapped(RegExp(r"((?<!^)([A-Z][a-z]|(?<=[a-z])[A-Z]))"),
        (match) => ' ${match.group(1)}');
  }
}

final profileProvider = StateNotifierProvider<ProfileProvider, Profile?>((ref) {
  final supabase = ref.read(supabaseInstance);
  return ProfileProvider(supabase: supabase);
});
