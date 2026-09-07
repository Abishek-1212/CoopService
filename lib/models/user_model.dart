import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String location;
  final String? profileImageUrl;
  final String role; // customer, worker, cooperative_head, admin
  final DateTime createdAt;
  final DateTime updatedAt;

  // Cooperative Head & Worker properties
  final String? cooperativeId;
  final String? serviceArea;

  // Worker Address & Location Details
  final String? fullAddress;
  final String? state;
  final String? district;
  final String? city;
  final String? pincode;

  // Worker Services & Experience
  final String? primaryServiceId;
  final List<String>? secondaryServiceIds;
  final String? serviceCategory;
  final List<String>? skills;
  final String? experience;
  final int? yearsOfExperience;
  final String? certifications;
  final String? bio;
  final String? previousWorkExperience;
  final List<String>? languagesKnown;

  // Worker Proof of Identity & Documents
  final String? identityType; // Aadhaar, Voter ID, Driving Licence, Passport, Other
  final String? identityDocumentUrl;
  final String? addressProofUrl;
  final String? profilePhotoUrl;
  final List<String>? skillCertificateUrls;
  final List<String>? experienceCertificateUrls;
  final List<String>? otherDocumentUrls;

  // Verification & Membership Status
  final String? verificationStatus; // pending, verified, rejected
  final String? membershipStatus; // not_requested, pending, approved, rejected, more_information_required
  final bool availableForJobs;

  // Legacy fields (kept for backward compatibility)
  final String? aadhaarNumber;
  final String? idProofType;
  final String? idProofNumber;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? bankName;
  final bool? documentsSubmitted;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.location,
    this.profileImageUrl,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.cooperativeId,
    this.serviceArea,
    this.fullAddress,
    this.state,
    this.district,
    this.city,
    this.pincode,
    this.primaryServiceId,
    this.secondaryServiceIds,
    this.serviceCategory,
    this.skills,
    this.experience,
    this.yearsOfExperience,
    this.certifications,
    this.bio,
    this.previousWorkExperience,
    this.languagesKnown,
    this.identityType,
    this.identityDocumentUrl,
    this.addressProofUrl,
    this.profilePhotoUrl,
    this.skillCertificateUrls,
    this.experienceCertificateUrls,
    this.otherDocumentUrls,
    this.verificationStatus,
    this.membershipStatus,
    this.availableForJobs = false,
    this.aadhaarNumber,
    this.idProofType,
    this.idProofNumber,
    this.bankAccountNumber,
    this.bankIfsc,
    this.bankName,
    this.documentsSubmitted,
  });

  bool get isCustomer => role == AppConstants.roleCustomer;
  bool get isWorker => role == AppConstants.roleWorker;
  bool get isCooperativeHead => role == AppConstants.roleCooperativeHead;
  bool get isAdmin => role == AppConstants.roleAdmin;
  bool get isVerifiedWorker =>
      isWorker &&
      verificationStatus == AppConstants.statusVerified &&
      membershipStatus == AppConstants.membershipApproved;

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    bool parseBool(dynamic value, [bool defaultValue = false]) {
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is num) return value != 0;
      return defaultValue;
    }

    List<String>? parseStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is String && value.isNotEmpty) {
        return [value];
      }
      return null;
    }

    return AppUser(
      uid: id,
      fullName: map['fullName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      profileImageUrl: map['profileImageUrl']?.toString() ?? map['profilePhotoUrl']?.toString(),
      role: map['role']?.toString() ?? AppConstants.roleCustomer,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
      cooperativeId: map['cooperativeId']?.toString(),
      serviceArea: map['serviceArea']?.toString(),
      fullAddress: map['fullAddress']?.toString() ?? map['address']?.toString(),
      state: map['state']?.toString(),
      district: map['district']?.toString(),
      city: map['city']?.toString(),
      pincode: map['pincode']?.toString(),
      primaryServiceId: map['primaryServiceId']?.toString(),
      secondaryServiceIds: parseStringList(map['secondaryServiceIds']),
      serviceCategory: map['serviceCategory']?.toString(),
      skills: parseStringList(map['skills']),
      experience: map['experience']?.toString(),
      yearsOfExperience: parseInt(map['yearsOfExperience']),
      certifications: map['certifications']?.toString(),
      bio: map['bio']?.toString(),
      previousWorkExperience: map['previousWorkExperience']?.toString(),
      languagesKnown: parseStringList(map['languagesKnown']),
      identityType: map['identityType']?.toString() ?? map['idProofType']?.toString(),
      identityDocumentUrl: map['identityDocumentUrl']?.toString(),
      addressProofUrl: map['addressProofUrl']?.toString(),
      profilePhotoUrl: map['profilePhotoUrl']?.toString() ?? map['profileImageUrl']?.toString(),
      skillCertificateUrls: parseStringList(map['skillCertificateUrls']),
      experienceCertificateUrls: parseStringList(map['experienceCertificateUrls']),
      otherDocumentUrls: parseStringList(map['otherDocumentUrls']),
      verificationStatus: map['verificationStatus']?.toString() ?? AppConstants.statusPending,
      membershipStatus: map['membershipStatus']?.toString() ?? AppConstants.membershipNotRequested,
      availableForJobs: parseBool(map['availableForJobs']),
      aadhaarNumber: map['aadhaarNumber']?.toString(),
      idProofType: map['idProofType']?.toString(),
      idProofNumber: map['idProofNumber']?.toString(),
      bankAccountNumber: map['bankAccountNumber']?.toString(),
      bankIfsc: map['bankIfsc']?.toString(),
      bankName: map['bankName']?.toString(),
      documentsSubmitted: map['documentsSubmitted'] != null ? parseBool(map['documentsSubmitted']) : null,
    );
  }

  factory AppUser.fromDocument(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return AppUser.fromMap(data, doc.id);
    } catch (e, stack) {
      debugPrint('>>> [AppUser.fromDocument ERROR] Failed to parse user doc ${doc.id}: $e\n$stack');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'location': location,
      'profileImageUrl': profileImageUrl ?? profilePhotoUrl,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'cooperativeId': cooperativeId,
      'serviceArea': serviceArea,
    };

    if (role == AppConstants.roleWorker) {
      data['fullAddress'] = fullAddress ?? '';
      data['state'] = state ?? '';
      data['district'] = district ?? '';
      data['city'] = city ?? '';
      data['pincode'] = pincode ?? '';
      data['primaryServiceId'] = primaryServiceId ?? '';
      data['secondaryServiceIds'] = secondaryServiceIds ?? [];
      data['serviceCategory'] = serviceCategory ?? '';
      data['skills'] = skills ?? [];
      data['experience'] = experience ?? '';
      data['yearsOfExperience'] = yearsOfExperience ?? 0;
      data['certifications'] = certifications ?? '';
      data['bio'] = bio ?? '';
      data['previousWorkExperience'] = previousWorkExperience ?? '';
      data['languagesKnown'] = languagesKnown ?? [];
      data['identityType'] = identityType ?? '';
      data['identityDocumentUrl'] = identityDocumentUrl ?? '';
      data['addressProofUrl'] = addressProofUrl ?? '';
      data['profilePhotoUrl'] = profilePhotoUrl ?? profileImageUrl ?? '';
      data['skillCertificateUrls'] = skillCertificateUrls ?? [];
      data['experienceCertificateUrls'] = experienceCertificateUrls ?? [];
      data['otherDocumentUrls'] = otherDocumentUrls ?? [];
      data['verificationStatus'] = verificationStatus ?? AppConstants.statusPending;
      data['membershipStatus'] = membershipStatus ?? AppConstants.membershipNotRequested;
      data['availableForJobs'] = availableForJobs;

      // Legacy fields
      data['aadhaarNumber'] = aadhaarNumber ?? '';
      data['idProofType'] = idProofType ?? '';
      data['idProofNumber'] = idProofNumber ?? '';
      data['bankAccountNumber'] = bankAccountNumber ?? '';
      data['bankIfsc'] = bankIfsc ?? '';
      data['bankName'] = bankName ?? '';
      data['documentsSubmitted'] = documentsSubmitted ?? false;
    }

    return data;
  }

  AppUser copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? location,
    String? profileImageUrl,
    String? role,
    DateTime? updatedAt,
    String? cooperativeId,
    String? serviceArea,
    String? fullAddress,
    String? state,
    String? district,
    String? city,
    String? pincode,
    String? primaryServiceId,
    List<String>? secondaryServiceIds,
    String? serviceCategory,
    List<String>? skills,
    String? experience,
    int? yearsOfExperience,
    String? certifications,
    String? bio,
    String? previousWorkExperience,
    List<String>? languagesKnown,
    String? identityType,
    String? identityDocumentUrl,
    String? addressProofUrl,
    String? profilePhotoUrl,
    List<String>? skillCertificateUrls,
    List<String>? experienceCertificateUrls,
    List<String>? otherDocumentUrls,
    String? verificationStatus,
    String? membershipStatus,
    bool? availableForJobs,
    String? aadhaarNumber,
    String? idProofType,
    String? idProofNumber,
    String? bankAccountNumber,
    String? bankIfsc,
    String? bankName,
    bool? documentsSubmitted,
  }) {
    return AppUser(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      cooperativeId: cooperativeId ?? this.cooperativeId,
      serviceArea: serviceArea ?? this.serviceArea,
      fullAddress: fullAddress ?? this.fullAddress,
      state: state ?? this.state,
      district: district ?? this.district,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      primaryServiceId: primaryServiceId ?? this.primaryServiceId,
      secondaryServiceIds: secondaryServiceIds ?? this.secondaryServiceIds,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      certifications: certifications ?? this.certifications,
      bio: bio ?? this.bio,
      previousWorkExperience: previousWorkExperience ?? this.previousWorkExperience,
      languagesKnown: languagesKnown ?? this.languagesKnown,
      identityType: identityType ?? this.identityType,
      identityDocumentUrl: identityDocumentUrl ?? this.identityDocumentUrl,
      addressProofUrl: addressProofUrl ?? this.addressProofUrl,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      skillCertificateUrls: skillCertificateUrls ?? this.skillCertificateUrls,
      experienceCertificateUrls: experienceCertificateUrls ?? this.experienceCertificateUrls,
      otherDocumentUrls: otherDocumentUrls ?? this.otherDocumentUrls,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      availableForJobs: availableForJobs ?? this.availableForJobs,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      idProofType: idProofType ?? this.idProofType,
      idProofNumber: idProofNumber ?? this.idProofNumber,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      bankName: bankName ?? this.bankName,
      documentsSubmitted: documentsSubmitted ?? this.documentsSubmitted,
    );
  }
}
