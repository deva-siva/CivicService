import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Utilities for compressing images before upload.
class ImageUtils {
  static const _maxBytes = 900 * 1024; // 900 KB target (leaves headroom for multipart overhead)

  /// Compress [file] so it is under 1 MB.
  ///
  /// Tries progressive quality reduction until the file fits.
  /// Returns the original file if it already fits, or if compression fails.
  static Future<File> compressUnder1MB(File file) async {
    final originalSize = await file.length();
    if (originalSize <= _maxBytes) return file; // already small enough

    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Calculate starting quality from original size ratio
    final ratio = _maxBytes / originalSize;
    int quality = (ratio * 100).clamp(15, 82).toInt();

    XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      minWidth: 1280,
      minHeight: 1280,
      keepExif: false,
    );

    if (result == null) return file;

    // Check if still over limit — if so, try harder with lower quality
    final compressedFile = File(result.path);
    final compressedSize = await compressedFile.length();
    if (compressedSize > _maxBytes) {
      final targetPath2 =
          '${dir.path}/compressed2_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ratio2 = _maxBytes / compressedSize;
      final quality2 = (ratio2 * quality).clamp(10, 50).toInt();

      final result2 = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath2,
        quality: quality2,
        minWidth: 800,
        minHeight: 800,
        keepExif: false,
      );
      if (result2 != null) return File(result2.path);
    }

    return compressedFile;
  }

  /// Returns a human-readable file size string (e.g. "840 KB", "2.1 MB").
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
