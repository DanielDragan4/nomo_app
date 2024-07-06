import 'package:flutter/material.dart';
import 'package:nomo/models/events_model.dart';

void preloadImages(List<Event> events, int preloadCount, context) {
  for (var i = 0; i < preloadCount && i < events.length; i++) {
    precacheImage(NetworkImage(events[i].imageUrl), context);
  }
}

void preloadRecommendedImages(
    BuildContext context, List<dynamic> events, int startIndex, int count) {
  for (var i = startIndex; i < startIndex + count && i < events.length; i++) {
    precacheImage(NetworkImage(events[i].imageUrl), context);
  }
}
