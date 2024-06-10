import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/models/interests_enum.dart';
import 'package:nomo/providers/search_provider.dart';
import 'package:nomo/screens/interests_screen.dart';
import 'package:nomo/widgets/event_tab.dart';
import 'package:nomo/widgets/friend_tab.dart';
import 'package:nomo/models/events_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<bool> _isSelected;
  List<dynamic> _searchResults = [];
  Map<Interests, bool> categories = {};

  @override
  void initState() {
    _isSelected = [true, false, false];
    super.initState();
  }

  Future<void> _searchProfiles(String query) async {
    try {
      final List<Friend> profiles =
          await ref.read(searchProvider.notifier).decodeProfileSearch(query);
      print(profiles);
      setState(() {
        _searchResults = profiles
            .map((profile) => FriendTab(
                  friendData: profile,
                  isRequest: false,
                  isSearch: true,
                  toggle: false,
                ))
            .toList();
      });
    } catch (e) {
      print('Error during search: $e');
    }
  }

  Future<void> _searchEvents(String query) async {
    try {
      // Split the query string by commas and trim any whitespace
      final List<String> categories =
          query.split(',').map((e) => e.trim()).toList();

      // A list to hold the search results from each category
      List<Event> allEvents = [];

      for (String category in categories) {
        final List<Event> events =
            await ref.read(searchProvider.notifier).decodeEventSearch(category);
        allEvents.addAll(events);
      }

      setState(() {
        _searchResults = allEvents
            .map((event) => EventTab(
                  eventData: event,
                  bookmarkSet: event.bookmarked,
                ))
            .toList();
        print('Search results updated: $_searchResults');
      });
    } catch (e) {
      print('Error during event search: $e');
    }
  }

  Future<void> _searchInterests(String query) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    try {
      // Split the query string by commas and trim any whitespace
      final List<String> categories =
          query.split(',').map((e) => e.trim()).toList();

      // A list to hold the search results from each category
      List<Event> allEvents = [];

      for (String category in categories) {
        final List<Event> events = await ref
            .read(searchProvider.notifier)
            .decodeInterestSearch(category);
        allEvents.addAll(events);
      }

      if (allEvents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No Events Found With These Interests"),
          ),
        );
      }

      setState(() {
        _searchResults = allEvents
            .map((event) => EventTab(
                  eventData: event,
                  bookmarkSet: event.bookmarked,
                ))
            .toList();
      });
    } catch (e) {
      print('Error during event search: $e');
    }
  }

  void resetScreen() {
    setState(() {
      _searchResults = [];
      _searchController.text = '';
    });
  }

  void _updateSearchBar(Map<Interests, bool> selectedInterests) {
    final selected = selectedInterests.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key.toString().split('.').last)
        .join(', ');
    setState(() {
      _searchController.text = selected;
    });
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
              resetScreen();
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
          Padding(
            padding: const EdgeInsets.only(bottom: 15.0),
            child: ElevatedButton(
              onPressed: () {
                if (_isSelected[0]) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  _searchEvents(_searchController.text);
                } else if (_isSelected[1]) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  _searchProfiles(_searchController.text);
                } else if (_isSelected[2]) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  _searchInterests(_searchController.text);
                }
              },
              child: const Text('Search'),
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? (_isSelected[2]
                    ? InterestsScreen(
                        isEditing: false,
                        creatingEvent: false,
                        searching: true,
                        selectedInterests: categories,
                        onSelectionChanged: _updateSearchBar,
                      )
                    : const Center(
                        child: Text('Search results will be displayed here'),
                      ))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      print('Building item for index $index');
                      return _searchResults[index];
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
