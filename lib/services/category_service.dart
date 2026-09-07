import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _categoriesRef =>
      _db.collection(AppConstants.categoriesCollection);

  // Stream active categories for customers and service creation
  Stream<List<CategoryModel>> streamActiveCategories() {
    return _categoriesRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CategoryModel.fromDocument(doc))
          .toList();
      // Sort in-memory by name ascending for consistent UI
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  // Stream all categories for admin management
  Stream<List<CategoryModel>> streamAllCategories() {
    return _categoriesRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CategoryModel.fromDocument(doc))
          .toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  // Check if a category name already exists (case-insensitive)
  Future<bool> checkCategoryNameExists(String name, {String? excludeId}) async {
    final snapshot = await _categoriesRef.get();
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

  // Create a new category
  Future<String> createCategory(CategoryModel category) async {
    final docRef = _categoriesRef.doc();
    final now = DateTime.now();
    final newCat = category.copyWith(updatedAt: now);

    final Map<String, dynamic> data = newCat.toMap();
    data['createdAt'] = Timestamp.fromDate(now);

    await docRef.set(data);
    return docRef.id;
  }

  // Update an existing category
  Future<void> updateCategory(CategoryModel category) async {
    final now = DateTime.now();
    final updated = category.copyWith(updatedAt: now);
    await _categoriesRef.doc(category.id).update(updated.toMap());
  }

  // Delete a category
  Future<void> deleteCategory(String id) async {
    await _categoriesRef.doc(id).delete();
  }

  // Toggle active / inactive status
  Future<void> toggleCategoryStatus(String id, bool currentStatus) async {
    await _categoriesRef.doc(id).update({
      'isActive': !currentStatus,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Seed default starter categories if collection is completely empty
  Future<void> seedDefaultCategoriesIfEmpty() async {
    try {
      final snap = await _categoriesRef.limit(1).get();
      if (snap.docs.isEmpty) {
        final now = DateTime.now();
        final defaultTrades = [
          {
            'name': 'Electrician',
            'description': 'Electrical repairs, wiring, switches, and installations',
            'iconKey': 'bolt',
          },
          {
            'name': 'Plumber',
            'description': 'Pipe repair, leakage fixing, taps, and sanitary fitting',
            'iconKey': 'plumbing',
          },
          {
            'name': 'Cleaning',
            'description': 'Full house deep cleaning, kitchen & bathroom sanitation',
            'iconKey': 'cleaning_services',
          },
          {
            'name': 'Carpentry',
            'description': 'Furniture repair, wood crafting, lock & door fitting',
            'iconKey': 'chair',
          },
          {
            'name': 'Painting',
            'description': 'Wall painting, waterproofing, and surface finishing',
            'iconKey': 'format_paint',
          },
          {
            'name': 'Appliance Repair',
            'description': 'Washing machine, refrigerator, microwave & appliance fixes',
            'iconKey': 'kitchen',
          },
          {
            'name': 'Gardening',
            'description': 'Lawn mowing, plant pruning, and outdoor maintenance',
            'iconKey': 'yard',
          },
          {
            'name': 'Home Maintenance',
            'description': 'General handyman fixes, fixture mounting, and minor repairs',
            'iconKey': 'handyman',
          },
          {
            'name': 'AC & HVAC',
            'description': 'Air conditioner servicing, gas refilling, and filter cleaning',
            'iconKey': 'ac_unit',
          },
        ];

        for (var t in defaultTrades) {
          final docRef = _categoriesRef.doc();
          await docRef.set({
            'name': t['name'],
            'description': t['description'],
            'iconKey': t['iconKey'],
            'isActive': true,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          });
        }
      }
    } catch (_) {
      // Best-effort seed
    }
  }
}
