import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/profile_model.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileProvider extends StateNotifier<List?> {
  ProfileProvider({required this.supabase}) : super([]);

  Future<Supabase> supabase;

  Future<List> readProfile() async {
    final supabaseClient = (await supabase).client;
    List<Map> profile = [];
    profile.add(await supabaseClient
        .from('Profiles')
        .select()
        .eq('profile_id', supabaseClient.auth.currentUser!.id)
        .single());
    return profile;
  }

  Future<void> decodeData() async {
    final userProfile = await readProfile();
    List<Profile> profile = [];

    profile.add(Profile(
      profile_id: userProfile[0]['profile_id'],
      avatar: userProfile[0]['avatar_id'],
      username: userProfile[0]['username'],
      profile_name: userProfile[0]['profile_name'],
    ));
    state = profile;
  }

  Future<String> imageURL(imgId) async {
    final supabaseClient = (await supabase).client;
    final imgPath = await supabaseClient
        .from('Images')
        .select('image_url')
        .eq('images_id', imgId);
    final imgURL = supabaseClient.storage
        .from('Images')
        .getPublicUrl(imgPath[0]['image_url']);

    return imgURL;
  }
}

final profileProvider = StateNotifierProvider<ProfileProvider, List?>((ref) {
  final supabase = ref.read(supabaseInstance);
  return ProfileProvider(supabase: supabase);
});
