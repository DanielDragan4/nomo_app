class Profile {
  final String profile_id;
  final String? avatar;
  final String username;
  final String? profile_name;
  final List interests;
  final List availability;
  final bool private;
  //final String? university;

  Profile({
    required this.profile_id,
    this.avatar,
    required this.username,
    this.profile_name,
    required this.interests,
    required this.availability,
    required this.private,
    //this.university,
  });

  // Add this copyWith method
  Profile copyWith({
    String? profile_id,
    String? avatar,
    String? username,
    String? profile_name,
    List? interests,
    List? availability,
    bool? private,
    //String? university,
  }) {
    return Profile(
      profile_id: profile_id ?? this.profile_id,
      avatar: avatar ?? this.avatar,
      username: username ?? this.username,
      profile_name: profile_name ?? this.profile_name,
      interests: interests ?? this.interests,
      availability: availability ?? this.availability,
      private: private ?? this.private,
      //university: university ?? this.university,
    );
  }
}
