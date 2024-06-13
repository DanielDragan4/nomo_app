
class Comment {
  const Comment({
    required this.comment_id,
    required this.profileUrl,
    required this.username,
    required this.comment_text,
    required this.profile_id,
    this.reply_comments,
    required this.timeStamp,
  });

  final String comment_id;
  final String profileUrl;
  final String username;
  final String comment_text;
  final String profile_id;
  final reply_comments; 
  final String timeStamp;
  
}
