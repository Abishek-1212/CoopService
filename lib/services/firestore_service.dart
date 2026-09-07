import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _usersRef => _db.collection(AppConstants.usersCollection);

  // Save User Document
  Future<void> createUserProfile(AppUser user) async {
    // Security check: normal user creation must only allow 'customer' or 'worker'
    if (user.role != AppConstants.roleCustomer && user.role != AppConstants.roleWorker) {
      throw Exception('Invalid role specified. Registration only permits Customer or Worker accounts.');
    }

    await _usersRef.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  // Get User Profile by UID
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      debugPrint('>>> [FirestoreService] Getting user document for uid=$uid');
      final doc = await _usersRef.doc(uid).get();
      debugPrint('>>> [FirestoreService] Document retrieved for uid=$uid, exists=${doc.exists}');
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return AppUser.fromDocument(doc);
    } catch (e, stack) {
      debugPrint('>>> [FirestoreService] getUserProfile ERROR for uid=$uid: $e\n$stack');
      rethrow;
    }
  }

  // Stream User Profile by UID
  Stream<AppUser?> streamUserProfile(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return AppUser.fromDocument(doc);
    });
  }

  // Stream All Users
  Stream<List<AppUser>> streamAllUsers() {
    return _usersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromDocument(doc)).toList();
    });
  }

  // Stream Users Eligible for Cooperative Head Assignment (exclude admin)
  Stream<List<AppUser>> streamCandidateHeadUsers() {
    return _usersRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromDocument(doc))
          .where((user) => user.role != AppConstants.roleAdmin)
          .toList();
    });
  }

  // Stream Workers Belonging to a Cooperative Unit
  Stream<List<AppUser>> streamWorkersByCooperative(String coopId) {
    return _usersRef
        .where('role', isEqualTo: AppConstants.roleWorker)
        .where('cooperativeId', isEqualTo: coopId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromDocument(doc)).toList();
    });
  }

  // Stream All Workers
  Stream<List<AppUser>> streamAllWorkers() {
    return _usersRef
        .where('role', isEqualTo: AppConstants.roleWorker)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AppUser.fromDocument(doc)).toList();
    });
  }

  // Check if User Document Exists
  Future<bool> userProfileExists(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    return doc.exists;
  }

  // Update Worker Verification & KYC Documents
  Future<void> updateWorkerDocuments({
    required String uid,
    required String aadhaarNumber,
    required String idProofType,
    required String idProofNumber,
    required String bankAccountNumber,
    required String bankIfsc,
    required String bankName,
  }) async {
    await _usersRef.doc(uid).update({
      'aadhaarNumber': aadhaarNumber.trim(),
      'idProofType': idProofType,
      'idProofNumber': idProofNumber.trim(),
      'bankAccountNumber': bankAccountNumber.trim(),
      'bankIfsc': bankIfsc.trim().toUpperCase(),
      'bankName': bankName.trim(),
      'documentsSubmitted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
