
class Availability {
  const Availability({
    required this.availId,
    required this.userId,
    required this.sTime,
    required this.eTime,
    this.eventId,
    required this.blockTitle,
  });

  final String availId;
  final String userId;
  final DateTime sTime;
  final DateTime eTime;
  final eventId; 
  final String blockTitle;
  
}
