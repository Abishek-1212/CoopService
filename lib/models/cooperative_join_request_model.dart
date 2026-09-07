import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class CooperativeJoinRequestModel {
  final String requestId;
  final String workerId;
  final String cooperativeId;
  final String? cooperativeHeadId;

  // Worker Basic Info
  final String workerName;
  final String workerEmail;
  final String workerPhone;

  // Worker Location
  final String? workerState;
  final String? workerDistrict;
  final String? workerCity;
  final String? workerPincode;

  // Services
  final String primaryServiceId;
  final List<String> secondaryServiceIds;

  // Proof Documents
  final String? profilePhotoUrl;
  final String? identityType;
  final String? identityDocumentUrl;
  final String? addressProofUrl;
  final List<String> skillCertificateUrls;
  final List<String> experienceCertificateUrls;
  final List<String> otherDocumentUrls;

  // Request Review Info
  final String status; // pending, approved, rejected, more_information_required
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String? requestedInfoMessage;

  CooperativeJoinRequestModel({
    required this.requestId,
    required this.workerId,
    required this.cooperativeId,
    this.cooperativeHeadId,
    required this.workerName,
    required this.workerEmail,
    required this.workerPhone,
    this.workerState,
    this.workerDistrict,
    this.workerCity,
    this.workerPincode,
    required this.primaryServiceId,
    this.secondaryServiceIds = const [],
    this.profilePhotoUrl,
    this.identityType,
    this.identityDocumentUrl,
    this.addressProofUrl,
    this.skillCertificateUrls = const [],
    this.experienceCertificateUrls = const [],
    this.otherDocumentUrls = const [],
    this.status = AppConstants.membershipPending,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    this.requestedInfoMessage,
  });

  bool get isPending => status == AppConstants.membershipPending;
  bool get isApproved => status == AppConstants.membershipApproved;
  bool get isRejected => status == AppConstants.membershipRejected;
  bool get isMoreInfoRequired => status == AppConstants.membershipMoreInfoRequired;

  factory CooperativeJoinRequestModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    DateTime? parseNullableDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return CooperativeJoinRequestModel(
      requestId: id,
      workerId: map['workerId'] ?? '',
      cooperativeId: map['cooperativeId'] ?? '',
      cooperativeHeadId: map['cooperativeHeadId'],
      workerName: map['workerName'] ?? '',
      workerEmail: map['workerEmail'] ?? '',
      workerPhone: map['workerPhone'] ?? '',
      workerState: map['workerState'],
      workerDistrict: map['workerDistrict'],
      workerCity: map['workerCity'],
      workerPincode: map['workerPincode'],
      primaryServiceId: map['primaryServiceId'] ?? '',
      secondaryServiceIds: map['secondaryServiceIds'] != null
          ? List<String>.from(map['secondaryServiceIds'])
          : [],
      profilePhotoUrl: map['profilePhotoUrl'],
      identityType: map['identityType'],
      identityDocumentUrl: map['identityDocumentUrl'],
      addressProofUrl: map['addressProofUrl'],
      skillCertificateUrls: map['skillCertificateUrls'] != null
          ? List<String>.from(map['skillCertificateUrls'])
          : [],
      experienceCertificateUrls: map['experienceCertificateUrls'] != null
          ? List<String>.from(map['experienceCertificateUrls'])
          : [],
      otherDocumentUrls: map['otherDocumentUrls'] != null
          ? List<String>.from(map['otherDocumentUrls'])
          : [],
      status: map['status'] ?? AppConstants.membershipPending,
      submittedAt: parseDateTime(map['submittedAt']),
      reviewedAt: parseNullableDateTime(map['reviewedAt']),
      reviewedBy: map['reviewedBy'],
      rejectionReason: map['rejectionReason'],
      requestedInfoMessage: map['requestedInfoMessage'],
    );
  }

  factory CooperativeJoinRequestModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CooperativeJoinRequestModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'workerId': workerId,
      'cooperativeId': cooperativeId,
      'cooperativeHeadId': cooperativeHeadId,
      'workerName': workerName,
      'workerEmail': workerEmail,
      'workerPhone': workerPhone,
      'workerState': workerState,
      'workerDistrict': workerDistrict,
      'workerCity': workerCity,
      'workerPincode': workerPincode,
      'primaryServiceId': primaryServiceId,
      'secondaryServiceIds': secondaryServiceIds,
      'profilePhotoUrl': profilePhotoUrl,
      'identityType': identityType,
      'identityDocumentUrl': identityDocumentUrl,
      'addressProofUrl': addressProofUrl,
      'skillCertificateUrls': skillCertificateUrls,
      'experienceCertificateUrls': experienceCertificateUrls,
      'otherDocumentUrls': otherDocumentUrls,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
      'requestedInfoMessage': requestedInfoMessage,
    };
  }

  CooperativeJoinRequestModel copyWith({
    String? status,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    String? requestedInfoMessage,
    List<String>? skillCertificateUrls,
    List<String>? experienceCertificateUrls,
    List<String>? otherDocumentUrls,
    String? identityDocumentUrl,
    String? addressProofUrl,
    String? profilePhotoUrl,
  }) {
    return CooperativeJoinRequestModel(
      requestId: requestId,
      workerId: workerId,
      cooperativeId: cooperativeId,
      cooperativeHeadId: cooperativeHeadId,
      workerName: workerName,
      workerEmail: workerEmail,
      workerPhone: workerPhone,
      workerState: workerState,
      workerDistrict: workerDistrict,
      workerCity: workerCity,
      workerPincode: workerPincode,
      primaryServiceId: primaryServiceId,
      secondaryServiceIds: secondaryServiceIds,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      identityType: identityType,
      identityDocumentUrl: identityDocumentUrl ?? this.identityDocumentUrl,
      addressProofUrl: addressProofUrl ?? this.addressProofUrl,
      skillCertificateUrls: skillCertificateUrls ?? this.skillCertificateUrls,
      experienceCertificateUrls: experienceCertificateUrls ?? this.experienceCertificateUrls,
      otherDocumentUrls: otherDocumentUrls ?? this.otherDocumentUrls,
      status: status ?? this.status,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      requestedInfoMessage: requestedInfoMessage ?? this.requestedInfoMessage,
    );
  }
}
