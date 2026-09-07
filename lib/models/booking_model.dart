import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class BookingModel {
  final String id;
  final String bookingNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String? customerCity;
  final String? customerDistrict;
  final String serviceId;
  final String serviceName;
  final String serviceCategory;
  final String? serviceIconUrl;
  final String? cooperativeId;
  final String? cooperativeName;
  final String? workerId;
  final String? workerName;
  final String? workerPhone;
  final String? workerPhotoUrl;
  final DateTime scheduledDate;
  final String timeSlot; // e.g. "09:00 AM - 12:00 PM"
  final String? problemDescription;
  final String status; // pending, confirmed, in_progress, completed, cancelled
  final String? estimatedPrice;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.bookingNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.customerCity,
    this.customerDistrict,
    required this.serviceId,
    required this.serviceName,
    required this.serviceCategory,
    this.serviceIconUrl,
    this.cooperativeId,
    this.cooperativeName,
    this.workerId,
    this.workerName,
    this.workerPhone,
    this.workerPhotoUrl,
    required this.scheduledDate,
    required this.timeSlot,
    this.problemDescription,
    this.status = AppConstants.bookingPending,
    this.estimatedPrice,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == AppConstants.bookingPending;
  bool get isConfirmed => status == AppConstants.bookingConfirmed;
  bool get isInProgress => status == AppConstants.bookingInProgress;
  bool get isCompleted => status == AppConstants.bookingCompleted;
  bool get isCancelled => status == AppConstants.bookingCancelled;

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return BookingModel(
      id: docId,
      bookingNumber: map['bookingNumber'] ?? 'BK-${docId.substring(0, 6).toUpperCase()}',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerAddress: map['customerAddress'] ?? '',
      customerCity: map['customerCity'],
      customerDistrict: map['customerDistrict'],
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      serviceCategory: map['serviceCategory'] ?? '',
      serviceIconUrl: map['serviceIconUrl'],
      cooperativeId: map['cooperativeId'],
      cooperativeName: map['cooperativeName'],
      workerId: map['workerId'],
      workerName: map['workerName'],
      workerPhone: map['workerPhone'],
      workerPhotoUrl: map['workerPhotoUrl'],
      scheduledDate: parseDateTime(map['scheduledDate']),
      timeSlot: map['timeSlot'] ?? '09:00 AM - 12:00 PM',
      problemDescription: map['problemDescription'],
      status: map['status'] ?? AppConstants.bookingPending,
      estimatedPrice: map['estimatedPrice'],
      cancellationReason: map['cancellationReason'],
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  factory BookingModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BookingModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'bookingNumber': bookingNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerCity': customerCity,
      'customerDistrict': customerDistrict,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'serviceCategory': serviceCategory,
      'serviceIconUrl': serviceIconUrl,
      'cooperativeId': cooperativeId,
      'cooperativeName': cooperativeName,
      'workerId': workerId,
      'workerName': workerName,
      'workerPhone': workerPhone,
      'workerPhotoUrl': workerPhotoUrl,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'timeSlot': timeSlot,
      'problemDescription': problemDescription,
      'status': status,
      'estimatedPrice': estimatedPrice,
      'cancellationReason': cancellationReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BookingModel copyWith({
    String? bookingNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? customerCity,
    String? customerDistrict,
    String? serviceId,
    String? serviceName,
    String? serviceCategory,
    String? serviceIconUrl,
    String? cooperativeId,
    String? cooperativeName,
    String? workerId,
    String? workerName,
    String? workerPhone,
    String? workerPhotoUrl,
    DateTime? scheduledDate,
    String? timeSlot,
    String? problemDescription,
    String? status,
    String? estimatedPrice,
    String? cancellationReason,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      customerCity: customerCity ?? this.customerCity,
      customerDistrict: customerDistrict ?? this.customerDistrict,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      serviceIconUrl: serviceIconUrl ?? this.serviceIconUrl,
      cooperativeId: cooperativeId ?? this.cooperativeId,
      cooperativeName: cooperativeName ?? this.cooperativeName,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      workerPhone: workerPhone ?? this.workerPhone,
      workerPhotoUrl: workerPhotoUrl ?? this.workerPhotoUrl,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeSlot: timeSlot ?? this.timeSlot,
      problemDescription: problemDescription ?? this.problemDescription,
      status: status ?? this.status,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
