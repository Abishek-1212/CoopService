import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/config/cloudinary_config.dart';
import '../core/utils/image_compressor.dart';
import 'cloudinary_service.dart';

class StorageService {
  final CloudinaryService _cloudinaryService = CloudinaryService();

  /// Primary upload method: Uploads file to Cloudinary and returns permanent CDN HTTPS URL
  Future<String?> uploadFile({
    required String path,
    Uint8List? bytes,
    File? file,
  }) async {
    // Determine folder and filename from the logical path
    final segments = path.split('/');
    final filename = segments.isNotEmpty ? segments.last : 'file_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final folder = segments.length > 1
        ? 'coop_service/${segments.sublist(0, segments.length - 1).join('/')}'
        : 'coop_service';

    // 1. If Cloudinary is configured, upload directly to Cloudinary
    if (CloudinaryConfig.isConfigured) {
      final cloudinaryUrl = await _cloudinaryService.uploadFile(
        bytes: bytes,
        file: file,
        folder: folder,
        filename: filename,
      );

      if (cloudinaryUrl != null && cloudinaryUrl.isNotEmpty) {
        return cloudinaryUrl;
      }
    }

    // 2. Fallback: If offline or Cloudinary unavailable, safely return compressed Data URI on Web
    if (kIsWeb && bytes != null) {
      Uint8List compressed = bytes;
      if (compressed.lengthInBytes > 60000) {
        compressed = await compressImageBytes(compressed, maxDimension: 600, quality: 0.5);
      }
      final mimeType = path.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg';
      final base64String = base64Encode(compressed);
      debugPrint('[StorageService] Fallback to compressed Data URI: ${compressed.lengthInBytes} bytes');
      return 'data:$mimeType;base64,$base64String';
    }

    return null;
  }

  // Upload Cooperative Document
  Future<String?> uploadCooperativeDocument({
    required String coopId,
    required String docName,
    Uint8List? bytes,
    File? file,
  }) async {
    return await _cloudinaryService.uploadCooperativeDocument(
      coopId: coopId,
      docName: docName,
      bytes: bytes,
      file: file,
    );
  }

  // Upload Cooperative Logo or Cover Image
  Future<String?> uploadCooperativeImage({
    required String coopId,
    required String type, // 'logo' or 'cover'
    Uint8List? bytes,
    File? file,
  }) async {
    return await _cloudinaryService.uploadCooperativeImage(
      coopId: coopId,
      type: type,
      bytes: bytes,
      file: file,
    );
  }

  // Upload Service Icon or Banner Image
  Future<String?> uploadServiceImage({
    required String serviceId,
    required String type, // 'icon' or 'banner'
    Uint8List? bytes,
    File? file,
  }) async {
    return await _cloudinaryService.uploadServiceImage(
      serviceId: serviceId,
      type: type,
      bytes: bytes,
      file: file,
    );
  }

  // Upload Worker Profile Photo
  Future<String?> uploadWorkerProfilePhoto({
    required String workerId,
    Uint8List? bytes,
    File? file,
  }) async {
    return await _cloudinaryService.uploadWorkerProfilePhoto(
      workerId: workerId,
      bytes: bytes,
      file: file,
    );
  }

  // Upload Worker Identity Document (Aadhaar, Voter ID, Driving Licence, etc.)
  Future<String?> uploadWorkerIdentityDocument({
    required String workerId,
    required String docType,
    Uint8List? bytes,
    File? file,
  }) async {
    return await _cloudinaryService.uploadWorkerIdentityDocument(
      workerId: workerId,
      docType: docType,
      bytes: bytes,
      file: file,
    );
  }

  // Upload Worker Address Proof
  Future<String?> uploadWorkerAddressProof({
    required String workerId,
    Uint8List? bytes,
    File? file,
  }) async {
    return await _cloudinaryService.uploadWorkerAddressProof(
      workerId: workerId,
      bytes: bytes,
      file: file,
    );
  }

  // Upload Worker Skill / Trade Certificate
  Future<String?> uploadWorkerSkillCertificate({
    required String workerId,
    required String certName,
    Uint8List? bytes,
    File? file,
  }) async {
    return await _cloudinaryService.uploadWorkerSkillCertificate(
      workerId: workerId,
      certName: certName,
      bytes: bytes,
      file: file,
    );
  }
}
