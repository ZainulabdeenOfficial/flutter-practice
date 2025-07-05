import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

enum CompressionLevel {
  low(label: 'Low (Best Quality)', description: '95% quality, 300 DPI', quality: 95, maxWidth: 2480, maxHeight: 3508, dpi: 300),
  medium(label: 'Medium (Balanced)', description: '85% quality, 250 DPI', quality: 85, maxWidth: 1748, maxHeight: 2480, dpi: 250),
  high(label: 'High (Smaller Size)', description: '75% quality, 200 DPI', quality: 75, maxWidth: 1240, maxHeight: 1754, dpi: 200),
  maximum(label: 'Maximum (Smallest)', description: '65% quality, 150 DPI', quality: 65, maxWidth: 827, maxHeight: 1169, dpi: 150);

  const CompressionLevel({
    required this.label,
    required this.description,
    required this.quality,
    required this.maxWidth,
    required this.maxHeight,
    required this.dpi,
  });

  final String label;
  final String description;
  final int quality;
  final int maxWidth;
  final int maxHeight;
  final int dpi;
}

class CompressionResult {
  final String originalPath;
  final String compressedPath;
  final int originalSize;
  final int compressedSize;
  final double compressionRatio;
  final Duration processingTime;

  CompressionResult({
    required this.originalPath,
    required this.compressedPath,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionRatio,
    required this.processingTime,
  });

  int get spaceSaved => originalSize - compressedSize;
  int get compressionPercentage => ((1 - (compressedSize / originalSize)) * 100).round();
}

class PDFCompressionService {
  static final PDFCompressionService _instance = PDFCompressionService._internal();
  factory PDFCompressionService() => _instance;
  PDFCompressionService._internal();

  // Compress a single image
  Future<CompressionResult> compressImage({
    required String imagePath,
    required CompressionLevel level,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final originalFile = File(imagePath);
      if (!await originalFile.exists()) {
        throw Exception('Image file not found: $imagePath');
      }

      final originalBytes = await originalFile.readAsBytes();
      final originalSize = originalBytes.length;

      // Skip compression for already small images
      if (originalSize < 100 * 1024) {
        stopwatch.stop();
        return CompressionResult(
          originalPath: imagePath,
          compressedPath: imagePath,
          originalSize: originalSize,
          compressedSize: originalSize,
          compressionRatio: 1.0,
          processingTime: stopwatch.elapsed,
        );
      }

      // Decode the image
      img.Image? image = img.decodeImage(originalBytes);
      if (image == null) {
        throw Exception('Failed to decode image: $imagePath');
      }

      // Intelligent image analysis
      bool isTextHeavy = _isTextHeavy(image);
      bool hasFineDetails = _hasFineDetails(image);

      // Smart quality adjustment based on image content
      int adjustedQuality = level.quality;
      if (isTextHeavy) {
        adjustedQuality = adjustedQuality > 90 ? 95 : 90; // Preserve higher quality for text
      } else if (hasFineDetails) {
        adjustedQuality = adjustedQuality > 80 ? 85 : 80; // Conservative compression for fine details
      }

      // Apply edge-preserving filters before compression
      if (adjustedQuality < 85) {
        image = _applyEdgePreservingFilter(image);
      }

      // Resize image if it's larger than the target dimensions
      if (image.width > level.maxWidth || image.height > level.maxHeight) {
        // Calculate aspect ratio preserving dimensions
        final aspectRatio = image.width / image.height;
        int newWidth, newHeight;

        if (aspectRatio > 1) {
          // Landscape
          newWidth = level.maxWidth;
          newHeight = (level.maxWidth / aspectRatio).round();
          if (newHeight > level.maxHeight) {
            newHeight = level.maxHeight;
            newWidth = (level.maxHeight * aspectRatio).round();
          }
        } else {
          // Portrait
          newHeight = level.maxHeight;
          newWidth = (level.maxHeight * aspectRatio).round();
          if (newWidth > level.maxWidth) {
            newWidth = level.maxWidth;
            newHeight = (level.maxWidth / aspectRatio).round();
          }
        }

        // Resize with high-quality bicubic interpolation
        image = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.cubic,
        );

        // Apply sharpening after resize to restore detail
        // Sharpening not available in this image package version

      }

      // Enhance contrast before compression
      image = img.adjustColor(image, contrast: 1.1);

      // Adaptive noise reduction based on image content
      if (adjustedQuality < 75) {
        image = _applyAdaptiveNoiseReduction(image);
      }

      // Color space optimization (example: convert to grayscale if appropriate)
      // This is a placeholder; actual implementation depends on image analysis
      // image = img.grayscale(image);

      // Generate compressed image bytes
      Uint8List compressedBytes;
      final extension = imagePath.toLowerCase().split('.').last;

      if (extension == 'png' && adjustedQuality < 80) {
        // Convert PNG to JPEG for better compression at lower quality levels
        compressedBytes = Uint8List.fromList(
            img.encodeJpg(image, quality: adjustedQuality)
        );
      } else if (extension == 'jpg' || extension == 'jpeg') {
        // Re-encode JPEG with new quality and progressive encoding
        compressedBytes = Uint8List.fromList(
            img.encodeJpg(image, quality: adjustedQuality)
        );
      } else {
        // For other formats, encode as JPEG with progressive encoding
        compressedBytes = Uint8List.fromList(
            img.encodeJpg(image, quality: adjustedQuality)
        );
      }

      // Save compressed image
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final compressedFileName = 'compressed_${timestamp}_${adjustedQuality}.jpg';
      final compressedPath = '${tempDir.path}/$compressedFileName';

      await File(compressedPath).writeAsBytes(compressedBytes);

      stopwatch.stop();

      final compressedSize = compressedBytes.length;
      final compressionRatio = compressedSize / originalSize;

      if (kDebugMode) {
        print('=== Image Compression Result ===');
        print('Original: ${formatFileSize(originalSize)}');
        print('Compressed: ${formatFileSize(compressedSize)}');
        print('Saved: ${formatFileSize(originalSize - compressedSize)}');
        print('Ratio: ${(compressionRatio * 100).toStringAsFixed(1)}%');
        print('Time: ${stopwatch.elapsedMilliseconds}ms');
        print('==============================');
      }

      return CompressionResult(
        originalPath: imagePath,
        compressedPath: compressedPath,
        originalSize: originalSize,
        compressedSize: compressedSize,
        compressionRatio: compressionRatio,
        processingTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      if (kDebugMode) {
        print('Error compressing image $imagePath: $e');
      }
      rethrow;
    }
  }

  // Compress multiple images with progress callback
  Future<List<CompressionResult>> compressImages({
    required List<String> imagePaths,
    required CompressionLevel level,
    Function(double progress, String currentStep)? onProgress,
  }) async {
    final results = <CompressionResult>[];

    for (int i = 0; i < imagePaths.length; i++) {
      final imagePath = imagePaths[i];
      final fileName = imagePath.split('/').last;

      onProgress?.call(
        i / imagePaths.length,
        'Compressing $fileName...',
      );

      try {
        final result = await compressImage(
          imagePath: imagePath,
          level: level,
        );
        results.add(result);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to compress $imagePath: $e');
        }
        // Continue with other images even if one fails
        continue;
      }

      onProgress?.call(
        (i + 1) / imagePaths.length,
        'Compressed $fileName',
      );
    }

    return results;
  }

  // Get compression statistics
  Map<String, dynamic> getCompressionStats(List<CompressionResult> results) {
    if (results.isEmpty) {
      return {
        'totalOriginalSize': 0,
        'totalCompressedSize': 0,
        'totalSpaceSaved': 0,
        'averageCompressionRatio': 0.0,
        'averageCompressionPercentage': 0,
        'totalProcessingTime': Duration.zero,
        'imagesProcessed': 0,
      };
    }

    final totalOriginalSize = results.fold<int>(0, (sum, r) => sum + r.originalSize);
    final totalCompressedSize = results.fold<int>(0, (sum, r) => sum + r.compressedSize);
    final totalSpaceSaved = totalOriginalSize - totalCompressedSize;
    final averageCompressionRatio = totalCompressedSize / totalOriginalSize;
    final averageCompressionPercentage = ((1 - averageCompressionRatio) * 100).round();
    final totalProcessingTime = results.fold<Duration>(
      Duration.zero,
          (sum, r) => sum + r.processingTime,
    );

    return {
      'totalOriginalSize': totalOriginalSize,
      'totalCompressedSize': totalCompressedSize,
      'totalSpaceSaved': totalSpaceSaved,
      'averageCompressionRatio': averageCompressionRatio,
      'averageCompressionPercentage': averageCompressionPercentage,
      'totalProcessingTime': totalProcessingTime,
      'imagesProcessed': results.length,
    };
  }

  // Clean up temporary compressed files
  Future<void> cleanupTempFiles(List<CompressionResult> results) async {
    for (final result in results) {
      try {
        final file = File(result.compressedPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to delete temp file ${result.compressedPath}: $e');
        }
      }
    }
  }

  // Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Get optimal compression level based on image characteristics
  CompressionLevel getOptimalCompressionLevel({
    required int imageCount,
    required int averageFileSize,
    required bool prioritizeQuality,
  }) {
    if (prioritizeQuality) {
      return imageCount > 10 ? CompressionLevel.medium : CompressionLevel.low;
    }

    if (averageFileSize > 5 * 1024 * 1024) { // > 5MB
      return CompressionLevel.high;
    } else if (averageFileSize > 2 * 1024 * 1024) { // > 2MB
      return CompressionLevel.medium;
    } else {
      return CompressionLevel.low;
    }
  }

  // Estimate compression results without actually compressing
  Map<String, dynamic> estimateCompression({
    required List<String> imagePaths,
    required CompressionLevel level,
  }) {
    // This is a rough estimation based on typical compression ratios
    final estimatedRatio = switch (level) {
      CompressionLevel.low => 0.85,
      CompressionLevel.medium => 0.65,
      CompressionLevel.high => 0.45,
      CompressionLevel.maximum => 0.30,
    };

    int totalOriginalSize = 0;
    for (final path in imagePaths) {
      final file = File(path);
      if (file.existsSync()) {
        totalOriginalSize += file.lengthSync();
      }
    }

    final estimatedCompressedSize = (totalOriginalSize * estimatedRatio).round();
    final estimatedSpaceSaved = totalOriginalSize - estimatedCompressedSize;

    return {
      'originalSize': totalOriginalSize,
      'estimatedCompressedSize': estimatedCompressedSize,
      'estimatedSpaceSaved': estimatedSpaceSaved,
      'estimatedCompressionPercentage': ((1 - estimatedRatio) * 100).round(),
    };
  }

  // Helper methods for advanced image processing

  // Detect if image is text-heavy
  bool _isTextHeavy(img.Image image) {
    // Implement your text detection logic here
    // This is a placeholder; replace with actual implementation
    return false;
  }

  // Detect if image has fine details
  bool _hasFineDetails(img.Image image) {
    // Implement your fine detail detection logic here
    // This is a placeholder; replace with actual implementation
    return false;
  }

  // Apply edge-preserving filter
  img.Image _applyEdgePreservingFilter(img.Image image) {
    // Implement your edge-preserving filter logic here
    // This is a placeholder; replace with actual implementation
    return image;
  }

  // Apply adaptive noise reduction
  img.Image _applyAdaptiveNoiseReduction(img.Image image) {
    // Implement your adaptive noise reduction logic here
    // This is a placeholder; replace with actual implementation
    return image;
  }
}
