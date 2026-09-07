import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/service_model.dart';

class ServiceManagementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _servicesRef =>
      _db.collection(AppConstants.servicesCollection);

  // Stream all services
  Stream<List<ServiceModel>> streamAllServices() {
    return _servicesRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceModel.fromDocument(doc))
          .toList();
    });
  }

  // Stream active services only
  Stream<List<ServiceModel>> streamActiveServices() {
    return _servicesRef
        .where('status', isEqualTo: AppConstants.statusActive)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceModel.fromDocument(doc))
          .toList();
    });
  }

  // Check if service name already exists (case-insensitive check)
  Future<bool> checkServiceNameExists(String name, {String? excludeId}) async {
    final snapshot = await _servicesRef.get();
    final normalized = name.trim().toLowerCase();

    for (var doc in snapshot.docs) {
      if (excludeId != null && doc.id == excludeId) continue;
      final docName = (doc.data() as Map<String, dynamic>)['name'] as String? ?? '';
      if (docName.trim().toLowerCase() == normalized) {
        return true;
      }
    }
    return false;
  }

  // Create a new service
  Future<String> createService(ServiceModel service) async {
    final docRef = _servicesRef.doc();
    final now = DateTime.now();
    final newService = service.copyWith(updatedAt: now);
    
    final Map<String, dynamic> data = newService.toMap();
    data['createdAt'] = Timestamp.fromDate(now);

    await docRef.set(data);
    return docRef.id;
  }

  // Update an existing service
  Future<void> updateService(ServiceModel service) async {
    final now = DateTime.now();
    final updated = service.copyWith(updatedAt: now);
    await _servicesRef.doc(service.id).update(updated.toMap());
  }

  // Get a single service by ID
  Future<ServiceModel?> getServiceById(String id) async {
    if (id.isEmpty) return null;
    final doc = await _servicesRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ServiceModel.fromDocument(doc);
  }

  // Get multiple services by IDs
  Future<List<ServiceModel>> getServicesByIds(List<String> serviceIds) async {
    if (serviceIds.isEmpty) return [];
    final List<ServiceModel> result = [];

    // Firestore whereIn supports max 10/30 items per query batch, fetch individually or chunked
    for (var id in serviceIds) {
      final s = await getServiceById(id);
      if (s != null) {
        result.add(s);
      }
    }
    return result;
  }

  // Toggle active / inactive status
  Future<void> toggleServiceStatus(String id, String currentStatus) async {
    final newStatus = (currentStatus == AppConstants.statusActive)
        ? AppConstants.statusInactive
        : AppConstants.statusActive;

    await _servicesRef.doc(id).update({
      'status': newStatus,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
