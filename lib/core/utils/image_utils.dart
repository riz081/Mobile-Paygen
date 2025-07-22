import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  static Future<File?> compressImage(File file, {int maxSizeKB = 5000}) async {
    try {
      // Check initial size
      final initialSize = await file.length();
      if (initialSize <= maxSizeKB * 1024) {
        return file; // No need to compress
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Compress image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 85, // Adjust quality (0-100)
        minWidth: 1024, // Adjust as needed
        minHeight: 1024, // Adjust as needed
      );

      if (result == null) return null;

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();

      if (compressedSize > maxSizeKB * 1024) {
        // If still too large, compress again with lower quality
        return await compressImage(compressedFile, maxSizeKB: maxSizeKB);
      }

      return compressedFile;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }
}