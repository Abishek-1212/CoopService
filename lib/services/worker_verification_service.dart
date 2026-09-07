import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/cooperative_join_request_model.dart';
import '../models/cooperative_model.dart';
import '../models/user_model.dart';

class WorkerVerificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _usersRef => _db.collection(AppConstants.usersCollection);
  CollectionReference get _coopsRef => _db.collection(AppConstants.cooperativesCollection);
  CollectionReference get _requestsRef => _db.collection(AppConstants.cooperativeJoinRequestsCollection);

  // Get dynamic unique districts where active cooperatives are operating
  Future<List<String>> getAvailableDistricts() async {
    try {
      final snapshot = await _coopsRef
          .where('status', isEqualTo: AppConstants.statusActive)
          .get();

      final Set<String> districts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final district = data['district'] as String?;
        if (district != null && district.trim().isNotEmpty) {
          districts.add(district.trim());
        }
      }

      // Add popular districts as well so the user always has a comprehensive selectable list
      for (var d in AppConstants.popularDistricts) {
        districts.add(d);
      }

      final list = districts.toList()..sort();
      return list;
    } catch (e) {
      return AppConstants.popularDistricts;
    }
  }

  // Stream active cooperatives by selected district and worker primary service ID
  Stream<List<CooperativeModel>> streamCooperativesByDistrictAndService({
    required String district,
    required String serviceId,
  }) {
    return _coopsRef
        .where('status', isEqualTo: AppConstants.statusActive)
        .where('serviceIds', arrayContains: serviceId)
        .snapshots()
        .map((snapshot) {
      final all = snapshot.docs.map((doc) => CooperativeModel.fromDocument(doc)).toList();

      if (district.isEmpty || district.toLowerCase() == 'all') {
        return all;
      }

      final normalizedDistrict = district.trim().toLowerCase();

      // Filter by district or coverage in service area / city / additionalServiceAreas
      return all.where((c) {
        final cDistrict = (c.district ?? '').trim().toLowerCase();
        final cArea = c.primaryServiceArea.toLowerCase();
        final cCity = (c.city ?? '').toLowerCase();
        final addAreas = c.additionalServiceAreas.map((a) => a.toLowerCase()).toList();

        return cDistrict == normalizedDistrict ||
            cArea.contains(normalizedDistrict) ||
            cCity.contains(normalizedDistrict) ||
            addAreas.any((a) => a.contains(normalizedDistrict));
      }).toList();
    });
  }

  // Save/Update worker verification profile details & documents
  Future<void> saveWorkerVerificationProfile(AppUser user) async {
    await _usersRef.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  // Submit Worker Join Request
  Future<String> submitJoinRequest({
    required AppUser worker,
    required CooperativeModel cooperative,
  }) async {
    // Check if worker already has a pending or active request
    final existingSnapshot = await _requestsRef
        .where('workerId', isEqualTo: worker.uid)
        .get();

    DocumentReference docRef;
    if (existingSnapshot.docs.isNotEmpty) {
      docRef = existingSnapshot.docs.first.reference;
    } else {
      docRef = _requestsRef.doc();
    }

    final request = CooperativeJoinRequestModel(
      requestId: docRef.id,
      workerId: worker.uid,
      cooperativeId: cooperative.id,
      cooperativeHeadId: cooperative.cooperativeHeadId,
      workerName: worker.fullName,
      workerEmail: worker.email,
      workerPhone: worker.phone,
      workerState: worker.state,
      workerDistrict: worker.district,
      workerCity: worker.city,
      workerPincode: worker.pincode,
      primaryServiceId: worker.primaryServiceId ?? '',
      secondaryServiceIds: worker.secondaryServiceIds ?? [],
      profilePhotoUrl: worker.profilePhotoUrl,
      identityType: worker.identityType,
      identityDocumentUrl: worker.identityDocumentUrl,
      addressProofUrl: worker.addressProofUrl,
      skillCertificateUrls: worker.skillCertificateUrls ?? [],
      experienceCertificateUrls: worker.experienceCertificateUrls ?? [],
      otherDocumentUrls: worker.otherDocumentUrls ?? [],
      status: AppConstants.membershipPending,
      submittedAt: DateTime.now(),
      reviewedAt: null,
      reviewedBy: null,
      rejectionReason: null,
      requestedInfoMessage: null,
    );

    final batch = _db.batch();

    // 1. Set request document
    batch.set(docRef, request.toMap());

    // 2. Update user status
    final userRef = _usersRef.doc(worker.uid);
    batch.update(userRef, {
      'membershipStatus': AppConstants.membershipPending,
      'verificationStatus': AppConstants.statusPending,
      'availableForJobs': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return docRef.id;
  }

  // Stream active join request for a worker
  Stream<CooperativeJoinRequestModel?> streamWorkerJoinRequest(String workerId) {
    return _requestsRef
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      // Get the most recent request
      final doc = snapshot.docs.first;
      return CooperativeJoinRequestModel.fromDocument(doc);
    });
  }

  // Stream all join requests for a Cooperative Head's society
  Stream<List<CooperativeJoinRequestModel>> streamRequestsForCooperative(String cooperativeId) {
    return _requestsRef
        .where('cooperativeId', isEqualTo: cooperativeId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CooperativeJoinRequestModel.fromDocument(doc))
          .toList();
      // Sort newest first
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    });
  }

  // Approve Worker Request
  Future<void> approveWorkerRequest({
    required String requestId,
    required String workerId,
    required String cooperativeId,
    required String cooperativeHeadId,
    required String primaryServiceId,
  }) async {
    final batch = _db.batch();

    // 1. Update Join Request
    final requestRef = _requestsRef.doc(requestId);
    batch.update(requestRef, {
      'status': AppConstants.membershipApproved,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': cooperativeHeadId,
      'rejectionReason': null,
    });

    // 2. Update Worker User profile
    final userRef = _usersRef.doc(workerId);
    batch.update(userRef, {
      'cooperativeId': cooperativeId,
      'membershipStatus': AppConstants.membershipApproved,
      'verificationStatus': AppConstants.statusVerified,
      'availableForJobs': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 3. Create subcollection entry: cooperatives/{coopId}/workers/{workerId}
    final coopWorkerRef = _coopsRef
        .doc(cooperativeId)
        .collection('workers')
        .doc(workerId);
    batch.set(coopWorkerRef, {
      'workerId': workerId,
      'joinedAt': FieldValue.serverTimestamp(),
      'primaryServiceId': primaryServiceId,
      'status': AppConstants.statusActive,
    });

    await batch.commit();
  }

  // Reject Worker Request
  Future<void> rejectWorkerRequest({
    required String requestId,
    required String workerId,
    required String cooperativeHeadId,
    required String rejectionReason,
  }) async {
    final batch = _db.batch();

    final requestRef = _requestsRef.doc(requestId);
    batch.update(requestRef, {
      'status': AppConstants.membershipRejected,
      'rejectionReason': rejectionReason,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': cooperativeHeadId,
    });

    final userRef = _usersRef.doc(workerId);
    batch.update(userRef, {
      'membershipStatus': AppConstants.membershipRejected,
      'verificationStatus': AppConstants.statusRejected,
      'availableForJobs': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Request More Information from Worker
  Future<void> requestMoreInformation({
    required String requestId,
    required String workerId,
    required String cooperativeHeadId,
    required String message,
  }) async {
    final batch = _db.batch();

    final requestRef = _requestsRef.doc(requestId);
    batch.update(requestRef, {
      'status': AppConstants.membershipMoreInfoRequired,
      'requestedInfoMessage': message,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': cooperativeHeadId,
    });

    final userRef = _usersRef.doc(workerId);
    batch.update(userRef, {
      'membershipStatus': AppConstants.membershipMoreInfoRequired,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Resubmit Worker Request with updated docs
  Future<void> resubmitJoinRequest({
    required String requestId,
    required String workerId,
    required AppUser updatedWorker,
  }) async {
    final batch = _db.batch();

    final requestRef = _requestsRef.doc(requestId);
    batch.update(requestRef, {
      'status': AppConstants.membershipPending,
      'submittedAt': FieldValue.serverTimestamp(),
      'identityType': updatedWorker.identityType,
      'identityDocumentUrl': updatedWorker.identityDocumentUrl,
      'addressProofUrl': updatedWorker.addressProofUrl,
      'profilePhotoUrl': updatedWorker.profilePhotoUrl,
      'skillCertificateUrls': updatedWorker.skillCertificateUrls ?? [],
      'experienceCertificateUrls': updatedWorker.experienceCertificateUrls ?? [],
      'otherDocumentUrls': updatedWorker.otherDocumentUrls ?? [],
    });

    final userRef = _usersRef.doc(workerId);
    batch.update(userRef, {
      'membershipStatus': AppConstants.membershipPending,
      'verificationStatus': AppConstants.statusPending,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Stream verified/enrolled workers belonging to a cooperative society
  Stream<List<AppUser>> streamWorkersForCooperative(String cooperativeId) {
    if (cooperativeId.isEmpty) return Stream.value([]);
    return _usersRef
        .where('cooperativeId', isEqualTo: cooperativeId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AppUser.fromDocument(doc))
          .where((u) => u.role == AppConstants.roleWorker)
          .toList();
      // Sort: verified/approved members first, then by name
      list.sort((a, b) {
        if (a.membershipStatus == AppConstants.membershipApproved &&
            b.membershipStatus != AppConstants.membershipApproved) {
          return -1;
        }
        if (a.membershipStatus != AppConstants.membershipApproved &&
            b.membershipStatus == AppConstants.membershipApproved) {
          return 1;
        }
        return a.fullName.compareTo(b.fullName);
      });
      return list;
    });
  }

  // Stream all active cooperatives
  Stream<List<CooperativeModel>> streamActiveCooperatives() {
    return _coopsRef
        .where('status', isEqualTo: AppConstants.statusActive)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((d) => CooperativeModel.fromDocument(d)).toList());
  }

  // Resolve Cooperative Society for a Cooperative Head
  Future<CooperativeModel?> getCooperativeForHead(
    String userId, {
    String? preferredCooperativeId,
  }) async {
    try {
      // 1. If preferred ID is provided and valid, fetch it
      if (preferredCooperativeId != null && preferredCooperativeId.isNotEmpty) {
        final doc = await _coopsRef.doc(preferredCooperativeId).get();
        if (doc.exists && doc.data() != null) {
          return CooperativeModel.fromDocument(doc);
        }
      }

      // 2. Query cooperatives where cooperativeHeadId == userId
      final headQuery = await _coopsRef
          .where('cooperativeHeadId', isEqualTo: userId)
          .limit(1)
          .get();
      if (headQuery.docs.isNotEmpty) {
        final coop = CooperativeModel.fromDocument(headQuery.docs.first);
        // Link to user profile if missing
        await _usersRef.doc(userId).set({
          'cooperativeId': coop.id,
          'serviceArea': coop.primaryServiceArea,
        }, SetOptions(merge: true));
        return coop;
      }

      // 3. Fallback to the first active cooperative in Firestore
      final anyCoop = await _coopsRef
          .where('status', isEqualTo: AppConstants.statusActive)
          .limit(1)
          .get();
      if (anyCoop.docs.isNotEmpty) {
        final coop = CooperativeModel.fromDocument(anyCoop.docs.first);
        return coop;
      }

      // 4. If no active, try any cooperative
      final fallbackQuery = await _coopsRef.limit(1).get();
      if (fallbackQuery.docs.isNotEmpty) {
        return CooperativeModel.fromDocument(fallbackQuery.docs.first);
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }
}
