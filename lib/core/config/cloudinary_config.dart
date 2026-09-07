import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryConfig {
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get apiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  // Base upload URL for auto detection (images, pdfs, etc.)
  static String get uploadUrl => 'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';

  static bool get isConfigured =>
      cloudName.isNotEmpty && apiKey.isNotEmpty && apiSecret.isNotEmpty;
}
