import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class ServiceModel {
  final String id;
  final String name;
  final String shortDescription;
  final String? description;
  final String category;
  final String? iconUrl;
  final String? imageUrl;
  final List<String> requiredSkills;
  final String? priceRange;
  final String status; // active, inactive
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.name,
    required this.shortDescription,
    this.description,
    required this.category,
    this.iconUrl,
    this.imageUrl,
    this.requiredSkills = const [],
    this.priceRange,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == AppConstants.statusActive;

  factory ServiceModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return ServiceModel(
      id: docId,
      name: map['name'] ?? '',
      shortDescription: map['shortDescription'] ?? '',
      description: map['description'],
      category: map['category'] ?? 'General Services',
      iconUrl: map['iconUrl'],
      imageUrl: map['imageUrl'],
      requiredSkills: map['requiredSkills'] != null
          ? List<String>.from(map['requiredSkills'])
          : [],
      priceRange: map['priceRange'],
      status: map['status'] ?? AppConstants.statusActive,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  factory ServiceModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ServiceModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shortDescription': shortDescription,
      'description': description,
      'category': category,
      'iconUrl': iconUrl,
      'imageUrl': imageUrl,
      'requiredSkills': requiredSkills,
      'priceRange': priceRange,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ServiceModel copyWith({
    String? name,
    String? shortDescription,
    String? description,
    String? category,
    String? iconUrl,
    String? imageUrl,
    List<String>? requiredSkills,
    String? priceRange,
    String? status,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id,
      name: name ?? this.name,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      category: category ?? this.category,
      iconUrl: iconUrl ?? this.iconUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      priceRange: priceRange ?? this.priceRange,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
