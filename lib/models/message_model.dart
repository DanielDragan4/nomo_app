class Message {
  const Message({
    required this.message,
    required this.senderId,
    required this.timeStamp,
    required this.isMine
  });

  final String message;
  final String senderId;
  final String timeStamp;  
  final bool isMine;
}
