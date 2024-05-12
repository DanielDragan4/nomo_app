
class Event {
  const Event({
    required this.eventId,
    required this.imageId,
    required this.title,
    required this.sdate,
    required this.edate,
    required this.host,
    required this.location,
    required this.description,
    required this.eventType,
    required this.attendees,
  });

  final eventId;
  final imageId;
  final String title;
  final String sdate;
  final String edate;
  final host;
  final String location;
  final String description;
  final String eventType;
  final List attendees;
}
