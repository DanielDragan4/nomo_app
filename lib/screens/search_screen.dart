import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/models/interests_enum.dart';
import 'package:nomo/providers/search_provider.dart';
import 'package:nomo/providers/theme_provider.dart';
import 'package:nomo/screens/profile/interests_screen.dart';
import 'package:nomo/widgets/event_tab.dart';
import 'package:nomo/widgets/friend_tab.dart';
import 'package:nomo/models/events_model.dart';

class SearchScreen extends ConsumerStatefulWidget {
  SearchScreen({
    Key? key,
    required this.searchingPeople,
    this.addToGroup,
  }) : super(key: key);

  final bool searchingPeople;
  final Function(bool, String)? addToGroup;

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<bool> _isSelected;
  List<dynamic> _searchResults = [];
  Map<Interests, bool> _selectedInterests = {};
  String _mainSearchText = '';
  bool get _showSearchButton => _selectedInterests.values.any((value) => value);

  @override
  void initState() {
    _isSelected = widget.searchingPeople ? [false, true, false] : [true, false, false];
    super.initState();
  }

  Future<void> _searchProfiles(String query) async {
    try {
      final List<Friend> profiles = await ref.read(searchProvider.notifier).decodeProfileSearch(query);
      if (widget.addToGroup == null) {
        setState(() {
          _searchResults = profiles
              .map((profile) => FriendTab(
                    friendData: profile,
                    isRequest: false,
                    isSearch: true,
                    toggle: true,
                    isEventAttendee: false,
                    groupMemberToggle: widget.addToGroup,
                  ))
              .toList();
        });
      } else {
        _searchResults = profiles
            .map((profile) => FriendTab(
                  friendData: profile,
                  isRequest: false,
                  groupMemberToggle: widget.addToGroup,
                  toggle: true,
                  isEventAttendee: false,
                ))
            .toList();
      }
    } catch (e) {
      print('Error during search: $e');
    }
  }

  Future<void> _searchEvents(String query) async {
    try {
      final List<String> categories = query.split(',').map((e) => e.trim()).toList();
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

  Future<void> _searchInterests(String query) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    try {
      final List<String> categories = query.split(',').map((e) => e.trim()).toList();
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

  void resetScreen() {
    setState(() {
      _searchResults = [];
    });
  }

  void _updateSearchBar(Map<Interests, bool> selectedInterests) {
    setState(() {
      _selectedInterests = selectedInterests;
      _searchController.text = selectedInterests.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key.toString().split('.').last)
          .join(', ');
    });
  }

  void _switchTab(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      if (_isSelected[0] || _isSelected[1]) _mainSearchText = _searchController.text;

      for (int i = 0; i < _isSelected.length; i++) {
        _isSelected[i] = i == index;
      }

      if (index == 0) {
        _searchController.text = _mainSearchText;
      } else if (index == 1) {
        _searchController.text = _mainSearchText;
      } else if (index == 2) {
        _searchController.text = _selectedInterests.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key.toString().split('.').last)
            .join(', ');
      } else {
        _searchController.clear();
      }

      resetScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    var themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        toolbarHeight: MediaQuery.of(context).padding.top + 5,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(45),
              ),
              child: TextField(
                readOnly: _isSelected[2] == true,
                autofocus: false,
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _isSelected[2] == true
                      ? 'Please select interests below.'
                      : _isSelected[1] == true
                          ? 'Who are you looking for?'
                          : 'What are you looking for?',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontWeight: FontWeight.w500),
                  prefixIcon: themeMode == ThemeMode.dark
                      ? Image.asset('assets/icons/search-dark.png')
                      : Image.asset('assets/icons/search-light.png'),
                  suffixIcon: _searchController.text.isNotEmpty && !_isSelected[2]
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              resetScreen();
                            });
                          },
                        )
                      : null,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontSize: MediaQuery.of(context).devicePixelRatio * 4.5,
                ),
                onChanged: (value) {
                  setState(() {});
                },
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  if (_isSelected[0]) {
                    //FocusManager.instance.primaryFocus?.unfocus();
                    _searchEvents(value);
                  } else if (_isSelected[1]) {
                    //FocusManager.instance.primaryFocus?.unfocus();
                    _searchProfiles(value);
                  }
                },
              ),
            ),
          ),
          if (!widget.searchingPeople)
            Padding(
              padding: _isSelected[2]
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                  : const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: constraints.maxWidth,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: List.generate(3 * 2 - 1, (index) {
                        if (index.isOdd) {
                          // This is a divider
                          return Container(
                            width: 1,
                            height: 12,
                            color: Theme.of(context).dividerColor,
                          );
                        }
                        int buttonIndex = index ~/ 2;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _switchTab(buttonIndex),
                            child: Container(
                              height: 28,
                              decoration: BoxDecoration(
                                color: _isSelected[buttonIndex]
                                    ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  ['Events', 'People', 'Interests'][buttonIndex],
                                  style: TextStyle(
                                    color: _isSelected[buttonIndex]
                                        ? Colors.white
                                        : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                                    fontSize: MediaQuery.of(context).devicePixelRatio * 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          if (_isSelected[2])
            AnimatedSize(
              duration: Duration(milliseconds: 300),
              child: _showSearchButton
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: ElevatedButton(
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          _searchInterests(_searchController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Text(
                            'Search',
                            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          Expanded(
            child: _searchResults.isEmpty
                ? (_isSelected[2]
                    ? InterestsScreen(
                        isEditing: false,
                        creatingEvent: false,
                        searching: true,
                        selectedInterests: _selectedInterests,
                        onSelectionChanged: _updateSearchBar,
                      )
                    : Center(
                        child: Text(
                          'Search results will be displayed here',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 18),
                        ),
                      ))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        return _searchResults[index];
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
