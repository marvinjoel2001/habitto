import '../../../../core/models/base_model.dart';

class Amenity extends BaseModel {
  final int id;
  final String name;

  Amenity({
    required this.id,
    required this.name,
  });

  factory Amenity.fromJson(Map<String, dynamic> json) {
    return Amenity(
      id: json['id'],
      name: json['name'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
    };
  }
}
