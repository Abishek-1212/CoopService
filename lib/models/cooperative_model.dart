import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class CooperativeModel {
  final String id;
  final String name;
  final String registrationNumber;
  final String primaryServiceArea;
  final String contactPhone;
  final String contactEmail;
  final String? address;
  final String? description;
  final String? state;
  final String? district;
  final String? city;
  final String? pincode;
  final List<String> serviceIds;
  final String? registrationDocumentUrl;
  final List<String> supportingDocumentUrls;
  final String? logoUrl;
  final String? coverImageUrl;
  final String status; // active, inactive
  final String? cooperativeHeadId;
  final List<String> additionalServiceAreas;
  final DateTime createdAt;
  final DateTime updatedAt;

  CooperativeModel({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.primaryServiceArea,
    required this.contactPhone,
    required this.contactEmail,
    this.address,
    this.description,
    this.state,
    this.district,
    this.city,
    this.pincode,
    this.serviceIds = const [],
    this.registrationDocumentUrl,
    this.supportingDocumentUrls = const [],
    this.logoUrl,
    this.coverImageUrl,
    required this.status,
    this.cooperativeHeadId,
    this.additionalServiceAreas = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == AppConstants.statusActive;
  bool get hasHead => cooperativeHeadId != null && cooperativeHeadId!.isNotEmpty;

  factory CooperativeModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return CooperativeModel(
      id: docId,
      name: map['name'] ?? '',
      registrationNumber: map['registrationNumber'] ?? '',
      primaryServiceArea: map['primaryServiceArea'] ?? map['serviceArea'] ?? '',
      contactPhone: map['contactPhone'] ?? map['phone'] ?? '',
      contactEmail: map['contactEmail'] ?? map['email'] ?? '',
      address: map['address'],
      description: map['description'],
      state: map['state'],
      district: map['district'],
      city: map['city'],
      pincode: map['pincode'],
      serviceIds: map['serviceIds'] != null ? List<String>.from(map['serviceIds']) : [],
      registrationDocumentUrl: map['registrationDocumentUrl'],
      supportingDocumentUrls: map['supportingDocumentUrls'] != null ? List<String>.from(map['supportingDocumentUrls']) : [],
      logoUrl: map['logoUrl'],
      coverImageUrl: map['coverImageUrl'],
      status: map['status'] ?? AppConstants.statusActive,
      cooperativeHeadId: map['cooperativeHeadId'],
      additionalServiceAreas: map['additionalServiceAreas'] != null
          ? List<String>.from(map['additionalServiceAreas'])
          : [],
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  factory CooperativeModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CooperativeModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'registrationNumber': registrationNumber,
      'primaryServiceArea': primaryServiceArea,
      'serviceArea': primaryServiceArea,
      'contactPhone': contactPhone,
      'phone': contactPhone,
      'contactEmail': contactEmail,
      'email': contactEmail,
      'address': address,
      'description': description,
      'state': state,
      'district': district,
      'city': city,
      'pincode': pincode,
      'serviceIds': serviceIds,
      'registrationDocumentUrl': registrationDocumentUrl,
      'supportingDocumentUrls': supportingDocumentUrls,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
      'status': status,
      'cooperativeHeadId': cooperativeHeadId,
      'additionalServiceAreas': additionalServiceAreas,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CooperativeModel copyWith({
    String? name,
    String? registrationNumber,
    String? primaryServiceArea,
    String? contactPhone,
    String? contactEmail,
    String? address,
    String? description,
    String? state,
    String? district,
    String? city,
    String? pincode,
    List<String>? serviceIds,
    String? registrationDocumentUrl,
    List<String>? supportingDocumentUrls,
    String? logoUrl,
    String? coverImageUrl,
    String? status,
    String? cooperativeHeadId,
    List<String>? additionalServiceAreas,
    DateTime? updatedAt,
  }) {
    return CooperativeModel(
      id: id,
      name: name ?? this.name,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      primaryServiceArea: primaryServiceArea ?? this.primaryServiceArea,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      address: address ?? this.address,
      description: description ?? this.description,
      state: state ?? this.state,
      district: district ?? this.district,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      serviceIds: serviceIds ?? this.serviceIds,
      registrationDocumentUrl: registrationDocumentUrl ?? this.registrationDocumentUrl,
      supportingDocumentUrls: supportingDocumentUrls ?? this.supportingDocumentUrls,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      status: status ?? this.status,
      cooperativeHeadId: cooperativeHeadId ?? this.cooperativeHeadId,
      additionalServiceAreas: additionalServiceAreas ?? this.additionalServiceAreas,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
