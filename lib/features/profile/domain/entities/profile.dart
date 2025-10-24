import '../../../../core/models/base_model.dart';
import '../../../auth/domain/entities/user.dart';

class Profile extends BaseModel {
  final int id;
  final User user;
  final String userType;
  final String phone;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<int> favorites;
  final String? profileImage;

  Profile({
    required this.id,
    required this.user,
    required this.userType,
    required this.phone,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    required this.favorites,
    this.profileImage,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      user: User.fromJson(json['user']),
      userType: json['user_type'],
      phone: json['phone'],
      isVerified: json['is_verified'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      favorites: List<int>.from(json['favorites'] ?? []),
      profileImage: json['profile_picture'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'user_type': userType,
      'phone': phone,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'favorites': favorites,
      'profile_picture': profileImage,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'user_type': userType,
      'phone': phone,
      'favorites': favorites,
    };
  }
}
