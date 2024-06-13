import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/saved_session_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/screens/interests_screen.dart';
import 'package:nomo/screens/location_test_screen.dart';
import 'package:nomo/screens/settings/setting_screen.dart';

enum options { itemOne, itemTwo, itemThree }

class ProfileDropdown extends ConsumerStatefulWidget {
  const ProfileDropdown({
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _ProfileDropdownState();
  }
}

class _ProfileDropdownState extends ConsumerState<ProfileDropdown> {
  //final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    options? selectedOption;

    return PopupMenuButton<options>(
        onSelected: (options item) {
          setState(
            () {
              selectedOption = item;
            },
          );
        },
        itemBuilder: (context) => <PopupMenuEntry<options>>[
              PopupMenuItem(
                value: options.itemOne,
                child: const Text("Edit Interests"),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: ((context) => InterestsScreen(
                                isEditing: true,
                              ))));
                },
              ),
              PopupMenuItem(
                value: options.itemOne,
                child: const Text("Location"),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: ((context) => const LocationTestScreen(isCreation: false,))));
                },
              ),
              PopupMenuItem(
                value: options.itemTwo,
                child: const Text("Settings"),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: ((context) => SettingScreen(
                                isCorp: true,
                              ))));
                },
              ),
              PopupMenuItem(
                value: options.itemThree,
                child: const Text("Sign Out"),
                onTap: () {
                  ref.watch(currentUserProvider.notifier).signOut();
                  ref
                      .read(savedSessionProvider.notifier)
                      .changeSessionDataList();
                },
              ),
            ],
        iconSize: MediaQuery.sizeOf(context).height / 30);
  }
}
