import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/cooperative_model.dart';

class CooperativeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _coopsRef => _db.collection(AppConstants.cooperativesCollection);
  CollectionReference get _usersRef => _db.collection(AppConstants.usersCollection);

  // Create a new Cooperative Society
  Future<String> createCooperative(CooperativeModel coop) async {
    final docRef = _coopsRef.doc();
    final now = DateTime.now();
    final newCoop = coop.copyWith(updatedAt: now);
    
    final Map<String, dynamic> data = newCoop.toMap();
    data['createdAt'] = Timestamp.fromDate(now);

    await docRef.set(data);
    return docRef.id;
  }

  // Update existing Cooperative Society
  Future<void> updateCooperative(CooperativeModel coop) async {
    await _coopsRef.doc(coop.id).update(coop.toMap());
  }

  // Stream List of All Cooperative Societies
  Stream<List<CooperativeModel>> streamCooperatives() {
    return _coopsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CooperativeModel.fromDocument(doc)).toList();
    });
  }

  // Stream Single Cooperative by ID
  Stream<CooperativeModel?> streamCooperativeById(String id) {
    if (id.isEmpty) return Stream.value(null);
    return _coopsRef.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return CooperativeModel.fromDocument(doc);
    });
  }

  // Get Single Cooperative Future
  Future<CooperativeModel?> getCooperativeById(String id) async {
    if (id.isEmpty) return null;
    final doc = await _coopsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return CooperativeModel.fromDocument(doc);
  }

  // Toggle Active / Inactive Status
  Future<void> toggleCooperativeStatus(String id, String currentStatus) async {
    final newStatus = (currentStatus == AppConstants.statusActive)
        ? AppConstants.statusInactive
        : AppConstants.statusActive;

    await _coopsRef.doc(id).update({
      'status': newStatus,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Assign Cooperative Head to a Cooperative Society
  Future<void> assignCooperativeHead({
    required String cooperativeId,
    required String userId,
    required String serviceArea,
  }) async {
    final batch = _db.batch();

    // 1. Update Cooperative Document
    final coopDocRef = _coopsRef.doc(cooperativeId);
    batch.update(coopDocRef, {
      'cooperativeHeadId': userId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    // 2. Update User Document -> change role to cooperative_head and link cooperativeId & serviceArea
    final userDocRef = _usersRef.doc(userId);
    batch.update(userDocRef, {
      'role': AppConstants.roleCooperativeHead,
      'cooperativeId': cooperativeId,
      'serviceArea': serviceArea,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit();
  }

  // Unassign Cooperative Head from a Cooperative Society
  Future<void> unassignCooperativeHead({
    required String cooperativeId,
    required String userId,
  }) async {
    final batch = _db.batch();

    final coopDocRef = _coopsRef.doc(cooperativeId);
    batch.update(coopDocRef, {
      'cooperativeHeadId': null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    final userDocRef = _usersRef.doc(userId);
    batch.update(userDocRef, {
      'cooperativeId': null,
      'serviceArea': null,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit();
  }

  // Stream Cooperatives that offer a specific Service ID
  Stream<List<CooperativeModel>> streamCooperativesByServiceId(String serviceId) {
    return _coopsRef
        .where('serviceIds', arrayContains: serviceId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CooperativeModel.fromDocument(doc)).toList();
    });
  }
}
