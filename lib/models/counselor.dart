class Counselor {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String specialization;
  final String availabilityStatus;
  final String? bio;
  final String? profilePicture;

  Counselor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.specialization,
    required this.availabilityStatus,
    this.bio,
    this.profilePicture,
  });

  String get fullName => '$firstName $lastName';

  factory Counselor.fromJson(Map<String, dynamic> json) {
    return Counselor(
      id: json['counselor_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      specialization: json['specialization'],
      availabilityStatus: json['availability_status'],
      bio: json['bio'],
      profilePicture: json['profile_picture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'counselor_id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'specialization': specialization,
      'availability_status': availabilityStatus,
      'bio': bio,
      'profile_picture': profilePicture,
    };
  }
}
