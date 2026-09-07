import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppImageHelper {
  /// Returns an ImageProvider (MemoryImage for data URIs, NetworkImage for http/https)
  static ImageProvider? getImageProvider(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();

    if (trimmed.startsWith('data:')) {
      final commaIndex = trimmed.indexOf(',');
      if (commaIndex != -1) {
        try {
          final base64String = trimmed.substring(commaIndex + 1);
          final bytes = base64Decode(base64String);
          return MemoryImage(bytes);
        } catch (_) {
          return null;
        }
      }
    }

    return NetworkImage(trimmed);
  }

  /// Builds an Image widget from either a data URI or a network URL
  static Widget buildImage(
    String url, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    final trimmed = url.trim();

    if (trimmed.startsWith('data:')) {
      final commaIndex = trimmed.indexOf(',');
      if (commaIndex != -1) {
        try {
          final base64String = trimmed.substring(commaIndex + 1);
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: errorBuilder ??
                (context, error, stackTrace) => _defaultErrorWidget(),
          );
        } catch (_) {
          return _defaultErrorWidget();
        }
      }
    }

    return Image.network(
      trimmed,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          width: width,
          height: height ?? 160,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: errorBuilder ??
          (context, error, stackTrace) => _defaultErrorWidget(),
    );
  }

  static Widget _defaultErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.broken_image_rounded, size: 40, color: AppColors.textTertiary),
          SizedBox(height: 6),
          Text(
            'Unable to preview document image',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
