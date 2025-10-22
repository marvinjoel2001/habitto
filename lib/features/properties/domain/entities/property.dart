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
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      type: json['type'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      price: json['price'].toDouble(),
      guarantee: json['guarantee'].toDouble(),
      description: json['description'],
      size: json['size'].toDouble(),
      bedrooms: json['bedrooms'],
      bathrooms: json['bathrooms'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      owner: json['owner'],
      agent: json['agent'],
      amenities: List<int>.from(json['amenities'] ?? []),
      acceptedPaymentMethods: List<int>.from(json['accepted_payment_methods'] ?? []),
      availabilityDate: json['availability_date'] != null
          ? DateTime.parse(json['availability_date'])
          : null,
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
