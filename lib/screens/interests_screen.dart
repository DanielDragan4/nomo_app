import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/models/interests_enum.dart';
import 'package:nomo/providers/saved_session_provider.dart';
import 'package:nomo/providers/user_signup_provider.dart';
import 'package:nomo/screens/new_event_screen.dart';

class InterestsScreen extends ConsumerStatefulWidget {
  InterestsScreen(
      {super.key,
      required this.isEditing,
      this.creatingEvent,
      this.searching,
      this.selectedInterests,
      this.onSelectionChanged});

  bool isEditing;
  bool? creatingEvent;
  bool? searching;
  Map<Interests, bool>? selectedInterests = {};
  final Function(Map<Interests, bool>)? onSelectionChanged;

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
    else if (widget.creatingEvent != null &&
        widget.selectedInterests!.isNotEmpty) {
      _selectedOptions = widget.selectedInterests!;
      _selectedCount = _selectedOptions.values.where((value) => value).length;
    } else {
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

  void _handleInterestSelection(Interests interest) {
    if (widget.isEditing ||
        (!widget.isEditing && _selectedCount < 5) ||
        _selectedOptions[interest] == true) {
      setState(() {
        _selectedOptions[interest] = !_selectedOptions[interest]!;
        _selectedCount = _selectedOptions.values.where((value) => value).length;

        // Trigger the callback with the updated selected options
        if (widget.onSelectionChanged != null) {
          widget.onSelectionChanged!(_selectedOptions);
        }
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
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          if (widget.searching == null)
            SliverAppBar(
              backgroundColor: colorScheme.background,
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
                        widget.creatingEvent == null
                            ? Text(
                                'Interests',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 30,
                                ),
                              )
                            : Text(
                                'Event Categories',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 30,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: widget.creatingEvent != null
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(kToolbarHeight / 2),
                      child: Text("Select up to 5 of your interests",
                          style: TextStyle(
                              fontSize: 20, color: colorScheme.onBackground)),
                    )
                  : null,
              centerTitle: true,
            ),
        ],
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  clipBehavior: Clip.hardEdge,
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
                            ? colorScheme.primary
                            : colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 4),
                      ),
                      onPressed: () => _handleInterestSelection(option),
                      child: Text(
                        textAlign: TextAlign.center,
                        ref.read(profileProvider.notifier).enumToString(option),
                        style: TextStyle(
                          fontSize: 18,
                          color: _selectedOptions[option] ?? false
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (widget.searching == null)
              SizedBox(
                height: widget.isEditing ? 90 : 110,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.background,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: widget.isEditing ? 20 : 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              child: !widget.isEditing
                                  ? widget.creatingEvent == null
                                      ? const Text(
                                          //Initial Setup
                                          "Continue",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        )
                                      : const Text(
                                          //Selecting for event
                                          "Add Interests",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        )
                                  : const Text(
                                      //Updating in settings (may work for editing event as well)
                                      "Update",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                              onPressed: () async {
                                if (widget.creatingEvent == null) {
                                  await ref
                                      .watch(profileProvider.notifier)
                                      .updateInterests(_selectedOptions);
                                  if (!widget.isEditing) {
                                    if (widget.creatingEvent == null) {
                                      //Initial account creation
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
                                    }
                                  } else {
                                    //Updating
                                    Navigator.of(context).pop();
                                  }
                                } else {
                                  print(_selectedOptions);
                                  Navigator.pop(context, _selectedOptions);
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
                          children: (!widget.isEditing &&
                                  widget.creatingEvent == null)
                              ? [
                                  TextButton(
                                    onPressed: () {
                                      if (widget.creatingEvent == null)
                                      //Initial creation skip interests
                                      {
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
                                      }
                                      // else {
                                      //   //Skip Event Interests
                                      //   ref.watch(profileProvider.notifier);

                                      //   Navigator.of(context).pushReplacement(
                                      //       MaterialPageRoute(
                                      //           builder: (context) =>
                                      //               const NavBar()));
                                      // }
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
