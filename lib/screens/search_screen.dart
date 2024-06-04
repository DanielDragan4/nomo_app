import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/search_provider.dart';
import 'package:nomo/widgets/friend_tab.dart';
import 'package:nomo/widgets/user_tab.dart';
import 'package:nomo/models/profile_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<bool> _isSelected;
  List<FriendTab> _searchResults = [];

  @override
  void initState() {
    _isSelected = [true, false, false];
    super.initState();
  }

  Future<void> _search(String query) async {
    try {
      final List<Friend> profiles =
          await ref.read(searchProvider.notifier).decodeSearch(query);
      print(profiles);
      setState(() {
        _searchResults = profiles
            .map((profile) => FriendTab(
                  friendData: profile,
                  isRequest: false,
                  isSearch: true,
                ))
            .toList();
      });
    } catch (e) {
      print('Error during search: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        toolbarHeight: 30,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
      ),
      body: Column(
        children: [
          SizedBox(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'What are you looking for?',
                  prefixIcon: const Icon(Icons.search),
                ),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              ),
            ),
          ),
          ToggleButtons(
            constraints: const BoxConstraints(
              maxHeight: 250,
              minWidth: 90,
              maxWidth: 200,
            ),
            borderColor: Colors.black,
            fillColor: Theme.of(context).primaryColor,
            borderWidth: 1,
            selectedBorderColor: Colors.black,
            selectedColor: Colors.grey,
            borderRadius: BorderRadius.circular(15),
            onPressed: (int index) {
              setState(() {
                for (int i = 0; i < _isSelected.length; i++) {
                  _isSelected[i] = i == index;
                }
              });
            },
            isSelected: _isSelected,
            children: const [
              Padding(
                padding: EdgeInsets.fromLTRB(10, 3, 10, 3),
                child: Text(
                  'Events',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(10, 3, 10, 3),
                child: Text(
                  'People',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(10, 3, 10, 3),
                child: Text(
                  'Interests',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const Divider(),
          ElevatedButton(
            onPressed: () {
              _search(_searchController.text);
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: const Text('Search'),
          ),
          // Placeholder for the list of FriendTab objects
          // Replace this with the actual list of FriendTab objects returned from the search
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return _searchResults[index];
              },
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('Search results will be displayed here'),
            ),
          ),
        ],
      ),
    );
  }
}
