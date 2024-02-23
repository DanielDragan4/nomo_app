import 'package:flutter/material.dart';

class Event {
  const Event({
    required this.id,
    required this.image,
    required this.title,
    required this.date,
    required this.attendies,
    required this.friends,
    required this.bookmarked,
    required this.comments,
    required this.orgainizer,
    required this.attending,
    required this.host,
    required this.type,
  });

  final String id;
  final String image;
  final String title;
  final DateTime date;
  final int attendies;
  final List<String> friends;
  final bool bookmarked;
  final List<String> comments;
  final String orgainizer;
  final bool attending;
  final bool host;
  final String type;
}
