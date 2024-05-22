import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';

enum Interests {
  Outdoors,
  Indoors,
  Biking,
  Hiking,
  Running,
  Swimming,
  Sports,
  Skateboarding,
  Skiing,
  Snowboarding,
  Beach,
  Surfing,
  Coding,
  Photography,
  Cinematography,
  DomesticTravel,
  InternationalTravel,
  Gardening,
  Cooking,
  Art,
  Reading,
  Writing,
  Concerts,
  Raves,
  MakingMusic,
  Gaming,
  Sowing,
  Knitting,
  Crocheting,
  Camping,
  Chess,
  CasinoGames,
  Movies,
  PersonalDevelopment,
  Hunting,
  Yoga,
  Pilates,
  RockClimbing,
  Boating,
  Motorcycles,
  Cars,
  Mushrooming,
  BBQ,
  Pets,
  Powerlifting,
  Bodybuilding,
  Fishing,
  Food,
  AdultBeverages
}

class InterestsScreen extends ConsumerStatefulWidget {
  InterestsScreen({super.key, required this.isEditing});

  bool isEditing;

  @override
  ConsumerState<InterestsScreen> createState() {
    return _InterestsScreenState();
  }
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  late Map<Interests, bool> _selectedOptions;
  late int _selectedCount;

  @override
  void initState() {
    super.initState();
    _selectedOptions = {};
    _selectedCount = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.isEditing) {
      _fetchExistingInterests();
    } else {
      _initializeSelectedOptions();
    }
  }

  void _initializeSelectedOptions() {
    _selectedOptions = {
      for (var option in Interests.values) option: false,
    };
  }

  Future<void> _fetchExistingInterests() async {
    final supabase = await ref.watch(supabaseInstance);
    final userId = supabase.client.auth.currentUser!.id;

    supabase.client
        .from('Interests')
        .select('Interests')
        .eq('user_id', userId)
        .then((response) {
      final List<dynamic> rows = response.toList();
      final List<String> existingInterests =
          rows.map((row) => row['Interests'].toString()).toList();

      setState(() {
        _selectedOptions = {
          for (var option in Interests.values)
            option: existingInterests.contains(_enumToString(option)),
        };
        _selectedCount = existingInterests.length;
      });
    }).catchError((error) {
      print('Error fetching existing interests: $error');
    });
  }

  String _enumToString(Interests interest) {
    final str = interest.toString().split('.').last;
    return str.replaceAllMapped(RegExp(r"((?<!^)([A-Z][a-z]|(?<=[a-z])[A-Z]))"),
        (match) => ' ${match.group(1)}');
  }

  void _updateSelectedOptions(Interests interest, bool isSelected) {
    setState(() {
      _selectedOptions[interest] = isSelected;
      _selectedCount =
          _selectedOptions.values.where((selected) => selected).length;
    });
  }

  void updateInterests() async {
    final supabase = (await ref.watch(supabaseInstance)).client;
    final userId = supabase.auth.currentUser!.id;
    final selectedInterests = _selectedOptions.entries
        .where((entry) => entry.value)
        .map((entry) => _enumToString(entry.key))
        .toList();

    // Clear existing interests if editing
    if (widget.isEditing) {
      await supabase.from('Interests').delete().eq('user_id', userId);
    }

    // Insert new interests
    final newInterestsRows = selectedInterests
        .map((interest) => {
              'user_id': userId,
              'Interests': interest,
            })
        .toList();

    await supabase.from('Interests').insert(newInterestsRows);
  }

  void skipInterests() async {
    final supabase = (await ref.watch(supabaseInstance)).client;
    final userId = supabase.auth.currentUser!.id;

    // Clear existing interests if skipping
    await supabase.from('Interests').delete().eq('user_id', userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            expandedHeight: 10,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.all(0),
              background: Padding(
                padding: const EdgeInsets.only(top: 35),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Interests',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(kToolbarHeight / 2),
              child: Text("Select up to 5 of your interests",
                  style: TextStyle(fontSize: 20)),
            ),
            centerTitle: true,
          ),
        ],
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  clipBehavior: Clip.none,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 30.0,
                    childAspectRatio: 2.4,
                  ),
                  itemCount: Interests.values.length,
                  itemBuilder: (context, index) {
                    final option = Interests.values[index];
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedOptions[option]!
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 4),
                      ),
                      onPressed: () {
                        if (_selectedOptions[option] == true ||
                            (_selectedCount < 5 && !widget.isEditing ||
                                widget.isEditing)) {
                          setState(() {
                            _selectedOptions[option] =
                                !_selectedOptions[option]!;
                          });
                        } else {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'You can only select up to 5 options. You can edit these later.'),
                            ),
                          );
                        }
                      },
                      child: Text(
                        textAlign: TextAlign.center,
                        _enumToString(option),
                        style: TextStyle(
                          fontSize: 18,
                          color: _selectedOptions[option]!
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              height: 110,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                            ),
                            child: const Text(
                              "Continue",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            onPressed: () {
                              updateInterests();
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: ((context) => const NavBar()),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: !widget.isEditing
                            ? [
                                TextButton(
                                  onPressed: () {
                                    skipInterests();
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: ((context) => const NavBar()),
                                      ),
                                    );
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("Skip"),
                                      Icon(Icons.arrow_forward_rounded),
                                    ],
                                  ),
                                ),
                              ]
                            : [],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
