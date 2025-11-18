import '../../../../core/models/base_model.dart';

class Photo extends BaseModel {
  final int id;
  final int property;
  final String image;
  final String? caption;
  final DateTime createdAt;

  Photo({
    required this.id,
    required this.property,
    required this.image,
    this.caption,
    required this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    String clean(dynamic v) {
      final s = v?.toString() ?? '';
      return s.replaceAll('`', '').replaceAll('"', '').trim();
    }
    return Photo(
      id: json['id'],
      property: json['property'],
      image: clean(json['image']),
      caption: json['caption'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property': property,
      'image': image,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'property': property,
      'caption': caption,
    };
  }
}
