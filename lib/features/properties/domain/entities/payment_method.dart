import '../../../../core/models/base_model.dart';

class PaymentMethod extends BaseModel {
  final int id;
  final String name;
  final int? user;

  PaymentMethod({
    required this.id,
    required this.name,
    this.user,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      name: json['name'],
      user: json['user'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'user': user,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'user': user,
    };
  }
}