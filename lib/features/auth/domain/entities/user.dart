import '../../../../core/models/base_model.dart';

class User extends BaseModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final DateTime dateJoined;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.dateJoined,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    final dynamic rawId = json['id'];
    final int parsedId = rawId is int
        ? rawId
        : int.tryParse((rawId?.toString() ?? '').trim()) ?? 0;
    final String username = (json['username'] ?? '').toString();
    final String email = (json['email'] ?? '').toString();
    final String firstName = (json['first_name'] ?? '').toString();
    final String lastName = (json['last_name'] ?? '').toString();
    final String dj = (json['date_joined'] ?? '').toString();
    final DateTime dateJoined = dj.isNotEmpty
        ? (DateTime.tryParse(dj) ?? DateTime.now())
        : DateTime.now();
    return User(
      id: parsedId,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      dateJoined: dateJoined,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'date_joined': dateJoined.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}
