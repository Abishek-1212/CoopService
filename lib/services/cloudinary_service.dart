import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/cloudinary_config.dart';
import '../core/utils/image_compressor.dart';

class CloudinaryService {
  /// Upload a file (raw bytes or File) to Cloudinary and return the permanent secure HTTPS URL
  Future<String?> uploadFile({
    Uint8List? bytes,
    File? file,
    String? folder,
    String? filename,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      debugPrint('[CloudinaryService] Cloudinary credentials not configured.');
      return null;
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final uploadFolder = folder ?? 'coop_service';

      // Cloudinary signature generation:
      // Parameters must be sorted alphabetically by key ('folder' before 'timestamp')
      final toSign = 'folder=$uploadFolder&timestamp=$timestamp${CloudinaryConfig.apiSecret}';
      final signature = sha1.convert(utf8.encode(toSign)).toString();

      final uri = Uri.parse(CloudinaryConfig.uploadUrl);
      final request = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = CloudinaryConfig.apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['folder'] = uploadFolder
        ..fields['signature'] = signature;

      final resolvedFilename = filename ?? 'doc_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (bytes != null) {
        Uint8List uploadBytes = bytes;
        // On web, downscale oversized camera images (>150KB) for lightning-fast network transmission
        if (kIsWeb && uploadBytes.lengthInBytes > 150000 && !resolvedFilename.endsWith('.pdf')) {
          uploadBytes = await compressImageBytes(uploadBytes, maxDimension: 1200, quality: 0.75);
        }
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            uploadBytes,
            filename: resolvedFilename,
          ),
        );
      } else if (file != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            filename: resolvedFilename,
          ),
        );
      } else {
        return null;
      }

      debugPrint('[CloudinaryService] Uploading $resolvedFilename to Cloudinary ($uploadFolder)...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = data['secure_url'] as String?;
        debugPrint('[CloudinaryService] Upload success! CDN URL: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('[CloudinaryService] Upload failed (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e, st) {
      debugPrint('[CloudinaryService] Error during upload: $e\n$st');
      return null;
    }
  }

  // Helper methods for specific application media types

  Future<String?> uploadWorkerProfilePhoto({
    required String workerId,
    Uint8List? bytes,
    File? file,
  }) async {
    return await uploadFile(
      bytes: bytes,
      file: file,
      folder: 'coop_service/workers/$workerId/profile',
      filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  Future<String?> uploadWorkerIdentityDocument({
    required String workerId,
    required String docType,
    Uint8List? bytes,
    File? file,
  }) async {
    final sanitized = docType.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return await uploadFile(
      bytes: bytes,
      file: file,
      folder: 'coop_service/workers/$workerId/identity',
      filename: '${sanitized}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  Future<String?> uploadWorkerAddressProof({
    required String workerId,
    Uint8List? bytes,
    File? file,
  }) async {
    return await uploadFile(
      bytes: bytes,
      file: file,
      folder: 'coop_service/workers/$workerId/identity',
      filename: 'address_proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  Future<String?> uploadWorkerSkillCertificate({
    required String workerId,
    required String certName,
    Uint8List? bytes,
    File? file,
  }) async {
    final sanitized = certName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return await uploadFile(
      bytes: bytes,
      file: file,
      folder: 'coop_service/workers/$workerId/certificates',
      filename: '${sanitized}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  Future<String?> uploadCooperativeImage({
    required String coopId,
    required String type,
    Uint8List? bytes,
    File? file,
  }) async {
    return await uploadFile(
      bytes: bytes,
      file: file,
      folder: 'coop_service/cooperatives/$coopId/images',
      filename: '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  Future<String?> uploadCooperativeDocument({
    required String coopId,
    required String docName,
    Uint8List? bytes,
    File? file,
  }) async {
    final sanitized = docName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return await uploadFile(
      bytes: bytes,
      file: file,
      folder: 'coop_service/cooperatives/$coopId/documents',
      filename: '${sanitized}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Future<String?> uploadServiceImage({
    required String serviceId,
    required String type,
    Uint8List? bytes,
    File? file,
  }) async {
    return await uploadFile(
      bytes: bytes,
      file: file,
      folder: 'coop_service/services/$serviceId',
      filename: '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }
}
