import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/models/interests_enum.dart';
import 'package:nomo/providers/saved_session_provider.dart';
import 'package:nomo/providers/user_signup_provider.dart';

class InterestsScreen extends ConsumerStatefulWidget {
  InterestsScreen({super.key, required this.isEditing});

  bool isEditing;

  @override
  ConsumerState<InterestsScreen> createState() {
    return _InterestsScreenState();
  }
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  late Map<Interests, bool> _selectedOptions = {
    for (var option in Interests.values) option: false
  };
  late int _selectedCount;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing)
      initializeSelectedOptions();
    else {
      _selectedCount = _selectedOptions.values.where((value) => value).length;
    }
  }

  Future<void> initializeSelectedOptions() async {
    final existingInterests =
        await ref.read(profileProvider.notifier).fetchExistingInterests();

    _selectedOptions = {
      for (var option in Interests.values)
        option: existingInterests.contains(ref
            .read(profileProvider.notifier)
            .enumToString(option.toString().split('.')[1])),
    };

    _selectedCount = _selectedOptions.values.where((value) => value).length;
    setState(() {}); // Trigger a rebuild after data is fetched
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
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
                        backgroundColor: _selectedOptions[option] ?? false
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 4),
                      ),
                      onPressed: () {
                        if (widget.isEditing ||
                            (!widget.isEditing && _selectedCount < 5) ||
                            _selectedOptions[option] == true) {
                          setState(() {
                            _selectedOptions[option] =
                                !_selectedOptions[option]!;
                            _selectedCount = _selectedOptions.values
                                .where((value) => value)
                                .length;
                          });
                        } else {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "You can only select up to 5 options. You can edit these later."),
                            ),
                          );
                        }
                      },
                      child: Text(
                        textAlign: TextAlign.center,
                        ref.read(profileProvider.notifier).enumToString(option),
                        style: TextStyle(
                          fontSize: 18,
                          color: _selectedOptions[option] ?? false
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
                            child: !widget.isEditing
                                ? const Text(
                                    "Continue",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  )
                                : const Text(
                                    "Update",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                            onPressed: () async {
                              await ref
                                  .watch(profileProvider.notifier)
                                  .updateInterests(_selectedOptions);
                              if (!widget.isEditing) {
                                ref
                                    .read(onSignUp.notifier)
                                    .completeProfileCreation();
                                ref
                                    .read(savedSessionProvider.notifier)
                                    .changeSessionDataList();

                                Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (context) => const NavBar()));
                              } else {
                                Navigator.of(context).pop();
                              }
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
                                    ref
                                        .watch(profileProvider.notifier)
                                        .skipInterests();
                                    ref
                                        .read(onSignUp.notifier)
                                        .completeProfileCreation();
                                    ref
                                        .read(savedSessionProvider.notifier)
                                        .changeSessionDataList();
                                    Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const NavBar()));
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
