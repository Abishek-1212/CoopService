// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

Future<Uint8List> compressImageBytes(
  Uint8List bytes, {
  int maxDimension = 600,
  double quality = 0.5,
}) async {
  try {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final img = html.ImageElement();
    final completer = Completer<Uint8List>();

    img.onLoad.listen((_) {
      html.Url.revokeObjectUrl(url);
      int width = img.naturalWidth;
      int height = img.naturalHeight;

      if (width <= 0 || height <= 0) {
        width = 600;
        height = 600;
      }

      if (width > maxDimension || height > maxDimension) {
        if (width > height) {
          height = (height * (maxDimension / width)).round();
          width = maxDimension;
        } else {
          width = (width * (maxDimension / height)).round();
          height = maxDimension;
        }
      }

      final canvas = html.CanvasElement(width: width, height: height);
      final ctx = canvas.context2D;
      ctx.drawImageScaled(img, 0, 0, width, height);

      final dataUrl = canvas.toDataUrl('image/jpeg', quality);
      final comma = dataUrl.indexOf(',');
      if (comma != -1) {
        final base64String = dataUrl.substring(comma + 1);
        final compressed = base64Decode(base64String);
        debugPrint('[ImageCompressor] Compressed from ${bytes.lengthInBytes} bytes to ${compressed.lengthInBytes} bytes ($width x $height)');
        completer.complete(compressed);
      } else {
        completer.complete(bytes);
      }
    });

    img.onError.listen((_) {
      html.Url.revokeObjectUrl(url);
      completer.complete(bytes);
    });

    img.src = url;
    return await completer.future;
  } catch (e) {
    debugPrint('[ImageCompressor] Error: $e');
    return bytes;
  }
}
