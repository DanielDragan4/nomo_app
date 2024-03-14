import 'package:flutter/material.dart';
import 'package:nomo/models/events_model.dart';

class Profile {
  const Profile({
    required this.profile_id,
    required this.avatar,
    required this.username,
    required this.profile_name,
  });

  final String profile_id;
  final avatar;
  final String username;
  final String profile_name;
}
