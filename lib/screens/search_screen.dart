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

// Default initialization with event search selected
  @override
  void initState() {
    _isSelected = [true, false, false];
    super.initState();
  }

// Calls the search profider and uses decodeProfileSearch method to display list of profiles matching the query
  Future<void> _searchProfiles(String query) async {
    try {
      final List<Friend> profiles = await ref.read(searchProvider.notifier).decodeProfileSearch(query);
      print(profiles);
      setState(() {
        _searchResults = profiles
            .map((profile) => FriendTab(
                  friendData: profile,
                  isRequest: false,
                  isSearch: true,
                  toggle: false,
                  isEventAttendee: true,
                ))
            .toList();
      });
    } catch (e) {
      print('Error during search: $e');
    }
  }

// Calls the search profider and uses decodeEventSearch method to display list of events matching the query
  Future<void> _searchEvents(String query) async {
    try {
      // Split the query string by commas and trim any whitespace
      final List<String> categories = query.split(',').map((e) => e.trim()).toList();

      // A list to hold the search results from each category
      List<Event> allEvents = [];

      for (String category in categories) {
        final List<Event> events = await ref.read(searchProvider.notifier).decodeEventSearch(category);
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

// Calls the search profider and uses decodeSearchInterests method to display list of events with the queried interests
  Future<void> _searchInterests(String query) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    try {
      // Split the query string by commas and trim any whitespace
      final List<String> categories = query.split(',').map((e) => e.trim()).toList();

      // A list to hold the search results from each category
      List<Event> allEvents = [];

      for (String category in categories) {
        final List<Event> events = await ref.read(searchProvider.notifier).decodeInterestSearch(category);
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

// Resets the search bar text
  void resetScreen() {
    setState(() {
      _searchResults = [];
    });
  }

// Adds or removes interest from the search bar when one is selected or deselected in interest search
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        toolbarHeight: MediaQuery.of(context).padding.top,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
      ),
      body: Column(
        children: [
          SizedBox(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
              child: TextField(
                readOnly: _isSelected[2] == true,
                autofocus: false,
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _isSelected[2] == true ? 'Please select interests below.' : 'What are you looking for?',
                  hintStyle: TextStyle(color: Theme.of(context).primaryColorLight.withOpacity(0.75)),
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              resetScreen();
                            });
                          },
                        )
                      : null,
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                onChanged: (value) {
                  setState(() {});
                },
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
              FocusManager.instance.primaryFocus?.unfocus();
              resetScreen();
              setState(() {
                for (int i = 0; i < _isSelected.length; i++) {
                  _isSelected[i] = i == index;
                }
              });
              if (_isSelected[2] == true) {
                FocusManager.instance.primaryFocus?.unfocus();
                _searchController.text = '';
              }
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
                    : Center(
                        child: Text(
                          'Search results will be displayed here',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 18),
                        ),
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
