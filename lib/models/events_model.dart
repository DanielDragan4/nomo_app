class Event {
  Event({
    required this.eventId,
    required this.imageId,
    required this.imageUrl,
    required this.title,
    required this.sdate,
    required this.edate,
    required this.host,
    required this.location,
    required this.description,
    required this.eventType,
    required this.attendees,
    required this.hostUsername,
    required this.hostProfileUrl,
    required this.profileName,
    required this.bookmarked,
    required this.attending,
    required this.isHost,
    required this.friends,
    required this.numOfComments,
    required this.isVirtual,
    required this.isRecurring,
    required this.isTicketed,
    this.distanceAway,
    this.categories,
    this.otherHost,
    this.otherAttend,
    this.otherBookmark,
  });

  final eventId;
  var imageId;
  late final imageUrl;
  final String title;
  final String sdate;
  final String edate;
  final host;
  final location;
  final String description;
  final String eventType;
  final List attendees;
  final String hostUsername;
  late final hostProfileUrl;
  final String profileName;
  late bool bookmarked;
  late bool attending;
  late bool isHost;
  final friends;
  final int numOfComments;
  final bool isVirtual;
  final bool isRecurring;
  final bool isTicketed;
  var distanceAway;
  var categories;
  var otherHost;
  var otherAttend;
  var otherBookmark;
}
