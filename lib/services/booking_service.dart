import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _bookingsRef =>
      _db.collection(AppConstants.bookingsCollection);

  // Create a new service booking
  Future<String> createBooking(BookingModel booking) async {
    final docRef = _bookingsRef.doc();
    final now = DateTime.now();

    // Generate readable booking reference e.g. BK-7832
    final randomDigits = 1000 + Random().nextInt(9000);
    final bookingNumber = 'BK-$randomDigits';

    final newBooking = booking.copyWith(
      bookingNumber: bookingNumber,
      updatedAt: now,
    );

    final Map<String, dynamic> data = newBooking.toMap();
    data['createdAt'] = Timestamp.fromDate(now);

    await docRef.set(data);
    return docRef.id;
  }

  // Stream all bookings for a specific customer (sorted newest first)
  Stream<List<BookingModel>> streamCustomerBookings(String customerId) {
    if (customerId.isEmpty) return Stream.value([]);
    return _bookingsRef
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BookingModel.fromDocument(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Stream a single booking by ID
  Stream<BookingModel?> streamBookingById(String bookingId) {
    if (bookingId.isEmpty) return Stream.value(null);
    return _bookingsRef.doc(bookingId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return BookingModel.fromDocument(doc);
    });
  }

  // Stream bookings assigned to a cooperative society
  Stream<List<BookingModel>> streamBookingsForCooperative(String cooperativeId) {
    if (cooperativeId.isEmpty) return Stream.value([]);
    return _bookingsRef
        .where('cooperativeId', isEqualTo: cooperativeId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BookingModel.fromDocument(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Helper to check if worker trade/skills match customer booking service
  static bool _tradeMatches({
    required String workerTrade,
    required String workerPrimaryService,
    required List<String> workerSkills,
    required String bookingServiceName,
    required String bookingCategory,
    required String bookingServiceId,
  }) {
    final wTrade = workerTrade.toLowerCase().trim();
    final wPri = workerPrimaryService.toLowerCase().trim();
    final bName = bookingServiceName.toLowerCase().trim();
    final bCat = bookingCategory.toLowerCase().trim();
    final bId = bookingServiceId.toLowerCase().trim();

    // If worker has no specified trade, receive all requests
    if (wTrade.isEmpty && wPri.isEmpty && workerSkills.isEmpty) return true;

    // Direct ID or name match
    if (wPri.isNotEmpty && (wPri == bId || bCat.contains(wPri) || bName.contains(wPri))) {
      return true;
    }
    if (wTrade.isNotEmpty) {
      if (bCat.contains(wTrade) || wTrade.contains(bCat)) return true;
      if (bName.contains(wTrade) || wTrade.contains(bName)) return true;
      if (bId.contains(wTrade) || wTrade.contains(bId)) return true;
    }

    // Skills check
    for (final skill in workerSkills) {
      final s = skill.toLowerCase().trim();
      if (s.length >= 3 && (bCat.contains(s) || bName.contains(s) || s.contains(bCat) || s.contains(bName))) {
        return true;
      }
    }

    // Stem matching for common trades where noun and adjective forms differ:
    // e.g. electrician vs electrical; plumber vs plumbing; carpenter vs carpentry; painter vs painting; cleaner vs cleaning
    final tradeStems = [
      'electr',   // electrician, electrical, electronic
      'plumb',    // plumber, plumbing
      'carpent',  // carpenter, carpentry
      'paint',    // painter, painting
      'clean',    // cleaner, cleaning, housekeeping
      'housekeep',// housekeeping
      'appliance',// appliance repair
      'ac',       // ac repair, air conditioner
      'garden',   // gardening, gardener
      'pest',     // pest control
      'lock',     // locksmith
      'mason',    // masonry
      'welder',   // welding
      'mechanic', // mechanical, mechanic
    ];

    for (final stem in tradeStems) {
      final workerHasStem = wTrade.contains(stem) || wPri.contains(stem);
      final bookingHasStem = bCat.contains(stem) || bName.contains(stem) || bId.contains(stem);
      if (workerHasStem && bookingHasStem) {
        return true;
      }
    }

    // Word token overlap for multi-word categories
    final tokens = wTrade.split(RegExp(r'[\s&,/]+')).where((t) => t.length > 3);
    for (final token in tokens) {
      if (bCat.contains(token) || bName.contains(token)) return true;
    }

    return false;
  }

  // Stream all bookings relevant to a Worker:
  // 1) Bookings directly assigned to the worker (workerId == worker.uid)
  // 2) New/pending requests matching the worker's cooperative or trade
  Stream<List<BookingModel>> streamBookingsForWorker(AppUser worker) {
    return _bookingsRef.snapshots().map((snapshot) {
      final all = snapshot.docs
          .map((doc) => BookingModel.fromDocument(doc))
          .toList();

      final filtered = all.where((b) {
        // Direct assignment to this worker
        if (b.workerId == worker.uid) return true;

        // If booking is already assigned to a different worker, do not show
        if (b.workerId != null && b.workerId!.isNotEmpty && b.workerId != worker.uid) {
          return false;
        }

        // Otherwise, only pending requests are open for workers to accept
        if (b.status != AppConstants.bookingPending) return false;

        // If worker belongs to a cooperative, match that cooperative
        final matchesCoop = worker.cooperativeId == null ||
            worker.cooperativeId!.isEmpty ||
            b.cooperativeId == null ||
            b.cooperativeId!.isEmpty ||
            b.cooperativeId == worker.cooperativeId;

        if (!matchesCoop) return false;

        // Match the worker's trade / service category
        return _tradeMatches(
          workerTrade: worker.serviceCategory ?? '',
          workerPrimaryService: worker.primaryServiceId ?? '',
          workerSkills: worker.skills ?? [],
          bookingServiceName: b.serviceName,
          bookingCategory: b.serviceCategory,
          bookingServiceId: b.serviceId,
        );
      }).toList();

      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    });
  }

  // Worker accepts a new customer service request
  Future<void> acceptJob({
    required String bookingId,
    required AppUser worker,
  }) async {
    await _bookingsRef.doc(bookingId).update({
      'workerId': worker.uid,
      'workerName': worker.fullName,
      'workerPhone': worker.phone,
      'workerPhotoUrl': worker.profilePhotoUrl,
      'status': AppConstants.bookingConfirmed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Worker starts service
  Future<void> startJob(String bookingId) async {
    await _bookingsRef.doc(bookingId).update({
      'status': AppConstants.bookingInProgress,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Worker completes service
  Future<void> completeJob(String bookingId) async {
    await _bookingsRef.doc(bookingId).update({
      'status': AppConstants.bookingCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Worker declines an assigned job
  Future<void> declineJob(String bookingId) async {
    await _bookingsRef.doc(bookingId).update({
      'workerId': null,
      'workerName': null,
      'workerPhone': null,
      'workerPhotoUrl': null,
      'status': AppConstants.bookingPending,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Cancel a booking
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    await _bookingsRef.doc(bookingId).update({
      'status': AppConstants.bookingCancelled,
      'cancellationReason': reason ?? 'Cancelled by customer',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _bookingsRef.doc(bookingId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
