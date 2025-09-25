import '../../../../core/models/base_model.dart';

class User extends BaseModel {
  final String id;
  final String email;
  final String name;
  final String? profileImage;
  final DateTime createdAt;
  
  User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImage,
    required this.createdAt,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      profileImage: json['profile_image'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profile_image': profileImage,
      'created_at': createdAt.toIso8601String(),
    };
  }
}