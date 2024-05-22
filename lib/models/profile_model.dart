class Profile {
  const Profile(
      {required this.profile_id,
      required this.avatar,
      required this.username,
      required this.profile_name,
      required this.interests});

  final String profile_id;
  final avatar;
  final String username;
  final String profile_name;
  final List<String> interests;
}
