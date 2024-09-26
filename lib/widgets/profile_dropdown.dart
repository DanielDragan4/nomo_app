import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/profile_model.dart';
import 'package:nomo/providers/supabase-providers/saved_session_provider.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';
import 'package:nomo/screens/profile/create_account_screen.dart';
import 'package:nomo/screens/profile/interests_screen.dart';
import 'package:nomo/screens/location/location_screen.dart';
import 'package:nomo/screens/password_handling/login_screen.dart';
import 'package:nomo/screens/settings/setting_screen.dart';

enum options { itemOne, itemTwo, itemThree, itemFour, itemFive }

// Dropdown and all item operations in Profile Screen (Three dots)
//
// Parameters:
// - 'updateProfileInfo': callback function to update user's profile info in Profile Screen after edit
// - 'profileInfo': current user's profile infrmation retrieved by fetchProfileById in profile provider
class ProfileDropdown extends ConsumerStatefulWidget {
  void Function() updateProfileInfo;
  final Future<Profile>? profileInfo;

  ProfileDropdown({
    super.key,
    required this.updateProfileInfo,
    required this.profileInfo,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _ProfileDropdownState();
  }
}

class _ProfileDropdownState extends ConsumerState<ProfileDropdown> {
  @override
  Widget build(BuildContext context) {
    options? selectedOption;

    return PopupMenuButton<options>(
        iconColor: Theme.of(context).colorScheme.onPrimary,
        color: Theme.of(context).colorScheme.secondary,
        onSelected: (options item) {
          setState(
            () {
              selectedOption = item;
            },
          );
        },
        itemBuilder: (context) => <PopupMenuEntry<options>>[
              // PopupMenuItem(
              //   value: options.itemOne,
              //   child: const Text("Edit Profile"),
              //   //Navigates to Create Account Screen, then calls for Profile Screen update once popped
              //   onTap: () {
              //     widget.profileInfo?.then((profile) {
              //       Navigator.of(context)
              //           .push(MaterialPageRoute(
              //         builder: ((context) => CreateAccountScreen(
              //               isNew: false,
              //               avatar: profile.avatar,
              //               profilename: profile.profile_name,
              //               username: profile.username,
              //               onUpdateProfile: widget.updateProfileInfo,
              //             )),
              //       ))
              //           .then((_) {
              //         widget.updateProfileInfo();
              //       });
              //     });
              //   },
              // ),
              PopupMenuItem(
                value: options.itemTwo,
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
                value: options.itemThree,
                child: const Text("Location"),
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                      builder: ((context) => const LocationScreen(
                            isCreation: false,
                          ))));
                },
              ),
              PopupMenuItem(
                value: options.itemFour,
                child: const Text("Settings"),
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                      builder: ((context) => SettingScreen(
                            isCorp: false,
                          ))));
                },
              ),
              PopupMenuItem(
                value: options.itemFive,
                child: const Text("Sign Out"),
                onTap: () async {
                  ref.read(currentUserProvider.notifier).signOut();
                  ref.read(savedSessionProvider.notifier).changeSessionDataList();
                  await Future.delayed(const Duration(milliseconds: 300));
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
        iconSize: MediaQuery.sizeOf(context).height / 30);
  }
}
