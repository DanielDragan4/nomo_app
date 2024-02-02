import 'package:flutter/material.dart';
import 'package:nomo/models/events_model.dart';

class User {
  const User({
    required this.uid,
    required this.username,
    required this.avatar,
    required this.friends,
    required this.attending,
    required this.attended,
    required this.searches,
    required this.interests,
    required this.saved,
    required this.availability,
    required this.affiliates,
    required this.private,
  });

  final String uid;
  final String username;
  final Image avatar;
  final List<String> friends;
  final List<String> attending; //Event ids
  final List<String> attended; //Event ids
  final List<String> searches;
  final List<String> interests;
  final List<Event> saved;
  final List<DateTime> availability;
  final List<String> affiliates;
  final bool private;
}
