class Friend {
  Friend(
      {required this.friendProfileId,
      required this.avatar,
      required this.friendUsername,
      this.friendProfileName,
      });

  final String friendProfileId;
  final avatar;
  final String friendUsername;
  var friendProfileName;
}