import '../../../../core/models/base_model.dart';

class Property extends BaseModel {
  final int id;
  final String type;
  final String address;
  final double? latitude;
  final double? longitude;
  final double price;
  final double guarantee;
  final String description;
  final double size;
  final int bedrooms;
  final int bathrooms;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int owner;
  final int? agent;
  final List<int> amenities;
  final List<int> acceptedPaymentMethods;
  final DateTime? availabilityDate;
  // URL de la primera foto asociada, provista por el backend en listados
  final String? mainPhoto;

  Property({
    required this.id,
    required this.type,
    required this.address,
    this.latitude,
    this.longitude,
    required this.price,
    required this.guarantee,
    required this.description,
    required this.size,
    required this.bedrooms,
    required this.bathrooms,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.owner,
    this.agent,
    required this.amenities,
    required this.acceptedPaymentMethods,
    this.availabilityDate,
    this.mainPhoto,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    // Parse robusto para tipos que pueden venir como string en la API
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    bool parseBool(dynamic v, {bool defaultValue = true}) {
      if (v == null) return defaultValue;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
      return defaultValue;
    }

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    String clean(dynamic v) {
      final s = v?.toString() ?? '';
      return s.replaceAll('`', '').replaceAll('"', '').trim();
    }

    return Property(
      id: parseInt(json['id'] ?? json['pk']),
      type: json['type']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: json['latitude'] != null ? parseDouble(json['latitude']) : null,
      longitude: json['longitude'] != null ? parseDouble(json['longitude']) : null,
      price: parseDouble(json['price']),
      guarantee: parseDouble(json['guarantee']),
      description: json['description']?.toString() ?? '',
      size: parseDouble(json['size']),
      bedrooms: parseInt(json['bedrooms']),
      bathrooms: parseInt(json['bathrooms']),
      isActive: parseBool(json['is_active'], defaultValue: true),
      createdAt: json['created_at'] != null ? parseDate(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? parseDate(json['updated_at']) : DateTime.now(),
      owner: parseInt(json['owner']),
      agent: json['agent'] != null ? parseInt(json['agent']) : null,
      amenities: List<int>.from((json['amenities'] ?? []).map((e) => parseInt(e))),
      acceptedPaymentMethods: List<int>.from((json['accepted_payment_methods'] ?? []).map((e) => parseInt(e))),
      availabilityDate: json['availability_date'] != null
          ? parseDate(json['availability_date'])
          : null,
      mainPhoto: (clean(json['main_photo_url']).isNotEmpty) 
          ? clean(json['main_photo_url']) 
          : ((clean(json['main_photo']).isNotEmpty)
              ? clean(json['main_photo'])
              : null),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'price': price,
      'guarantee': guarantee,
      'description': description,
      'size': size,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'owner': owner,
      'agent': agent,
      'amenities': amenities,
      'accepted_payment_methods': acceptedPaymentMethods,
      'availability_date': availabilityDate?.toIso8601String(),
      'main_photo': mainPhoto,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'type': type,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'price': price,
      'guarantee': guarantee,
      'description': description,
      'size': size,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'amenities': amenities,
      'availability_date': availabilityDate?.toIso8601String(),
      'accepted_payment_methods': acceptedPaymentMethods,
    };
  }
}
