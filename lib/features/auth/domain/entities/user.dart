class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
  });
}