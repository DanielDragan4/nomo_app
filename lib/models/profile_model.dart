class Profile {
  Profile(
      {required this.profile_id,
      required this.avatar,
      required this.username,
      required this.profile_name,
      required this.interests,
      required this.availability,
      required this.private});

  final String profile_id;
  final avatar;
  final String username;
  final String profile_name;
  List interests;
  final List availability;
  bool private;
}
