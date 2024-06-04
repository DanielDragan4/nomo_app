import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nomo/models/friend_model.dart';

class SearchProvider extends StateNotifier<List<Friend>> {
  SearchProvider({required this.supabase}) : super([]);

  Future<Supabase> supabase;

  Future<List> searchProfiles(String query) async {
    final supabaseClient = (await supabase).client;

    final profiles = supabaseClient
        .from('profile_view')
        .select()
        .textSearch('search_vector', query, config: 'english');

    return profiles;
  }

  Future<List<Friend>> decodeSearch(String query) async {
    final List userSearchCoded = await searchProfiles(query);
    List<Friend> userSearches = [];
    final supabaseClient = (await supabase).client;

    for (var s in userSearchCoded) {
      String profileUrl =
          supabaseClient.storage.from('Images').getPublicUrl(s['profile_path']);

      final Friend user = Friend(
          friendProfileId: s['profile_id'],
          avatar: profileUrl,
          friendUsername: s['username'],
          friendProfileName: s['profile_name']);

      userSearches.add(user);
    }
    return userSearches;
  }
}

final searchProvider =
    StateNotifierProvider<SearchProvider, List<Friend>>((ref) {
  final supabase = ref.read(supabaseInstance);
  return SearchProvider(supabase: supabase);
});
