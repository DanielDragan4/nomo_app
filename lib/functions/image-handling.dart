import 'package:flutter/material.dart';

// Handles pre-caching of event images on various screens for improved load times.
//
// Parameters:
// - 'events': The list of events for which images should be loaded as the user scrolls
// - 'startIndex': The event index from which the function should begin precaching images
// - 'count': The number of images after, and including, startIndex set to be pre-cached

void preloadImages(BuildContext context, List<dynamic> events, int startIndex, int count) {
  for (var i = startIndex; i < startIndex + count && i < events.length; i++) {
    precacheImage(NetworkImage(events[i].imageUrl), context);
  }
}
