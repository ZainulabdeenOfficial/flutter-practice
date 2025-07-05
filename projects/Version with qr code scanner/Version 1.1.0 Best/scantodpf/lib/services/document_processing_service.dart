import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class DocumentProcessingService {
  static final DocumentProcessingService _instance =
  DocumentProcessingService._internal();
  factory DocumentProcessingService() => _instance;
  DocumentProcessingService._internal();

  // Maximum image size for processing to prevent memory issues
  static const int maxProcessingSize = 2048;
  static const int maxImageSize = 4096;


  Future<String> autoCropDocument(String imagePath) async {
    return _processImageSafely(imagePath, 'cropped', (image) {
      return _cropDocument(image);
    });
  }


  Future<String> applyGrayscaleFilter(String imagePath) async {
    return _processImageSafely(imagePath, 'grayscale', (image) {
      // Resize if too large
      image = _resizeIfNeeded(image);

      // Convert to grayscale using optimized method
      _convertToGrayscaleOptimized(image);

      // Enhance contrast
      _enhanceDocumentContrast(image);

      // Apply gamma correction
      _applyGammaCorrection(image, 1.2);

      return image;
    });
  }


  Future<String> applyMagicFilter(String imagePath) async {
    return _processImageSafely(imagePath, 'magic', (image) {
      // Resize if too large
      image = _resizeIfNeeded(image);

      // Apply optimizations step by step
      _normalizeDocumentBrightness(image);
      _applyAdaptiveHistogramEqualizationOptimized(image);
      _enhanceTextEdgesOptimized(image);
      _applyDocumentSharpeningOptimized(image);
      _optimizeDocumentContrast(image);

      return image;
    });
  }


  Future<String> applyBlackWhiteFilter(String imagePath) async {
    return _processImageSafely(imagePath, 'bw', (image) {
      // Resize if too large to prevent crashes
      image = _resizeIfNeeded(image);

      // Step 1: Convert to grayscale efficiently
      _convertToGrayscaleOptimized(image);

      // Step 2: Enhance contrast with bounds checking
      _enhanceContrastSafely(image);

      // Step 3: Apply optimized adaptive thresholding
      _applyAdaptiveThresholdOptimized(image);

      // Step 4: Apply noise removal with safety checks
      _removeNoiseSafely(image);

      return image;
    });
  }


  Future<String> applyColorFilter(String imagePath) async {
    return _processImageSafely(imagePath, 'color', (image) {
      // Resize if too large
      image = _resizeIfNeeded(image);

      _enhanceDocumentColors(image);
      _enhanceDocumentContrast(image);
      _applyDocumentSharpeningOptimized(image);
      _reduceColorNoise(image);

      return image;
    });
  }

  
  Future<String> _processImageSafely(
      String imagePath,
      String prefix,
      img.Image Function(img.Image) processor,
      ) async {
    try {
      // Check file exists and size
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize > 50 * 1024 * 1024) { // 50MB limit
        throw Exception('Image file too large');
      }

      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Could not decode image');
      }

      // Check image dimensions
      if (image.width > maxImageSize || image.height > maxImageSize) {
        image = img.copyResize(
          image,
          width: image.width > maxImageSize ? maxImageSize : null,
          height: image.height > maxImageSize ? maxImageSize : null,
        );
      }

      // Process the image
      image = processor(image);

      // Save processed image
      final directory = await getTemporaryDirectory();
      final processedPath =
          '${directory.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final processedFile = File(processedPath);

      await processedFile.writeAsBytes(img.encodeJpg(image, quality: 90));

      return processedPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error processing image: $e');
      }
      return imagePath; // Return original path on error
    }
  }

  /// Resize image if it's too large for processing
  img.Image _resizeIfNeeded(img.Image image) {
    if (image.width > maxProcessingSize || image.height > maxProcessingSize) {
      final aspectRatio = image.width / image.height;
      int newWidth, newHeight;

      if (aspectRatio > 1) {
        newWidth = maxProcessingSize;
        newHeight = (maxProcessingSize / aspectRatio).round();
      } else {
        newHeight = maxProcessingSize;
        newWidth = (maxProcessingSize * aspectRatio).round();
      }

      return img.copyResize(image, width: newWidth, height: newHeight);
    }
    return image;
  }

  /// Optimized grayscale conversion
  void _convertToGrayscaleOptimized(img.Image image) {
    final width = image.width;
    final height = image.height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        // Use integer arithmetic for better performance - fixed bit shift error
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final gray = ((r * 77 + g * 151 + b * 28) ~/ 256).clamp(0, 255);
        image.setPixel(x, y, img.ColorRgb8(gray, gray, gray));
      }
    }
  }

  /// Enhanced contrast with safety bounds
  void _enhanceContrastSafely(img.Image image) {
    final width = image.width;
    final height = image.height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final luma = img.getLuminance(pixel).toInt();
        final enhanced = ((luma - 128) * 1.5 + 128).clamp(0, 255).toInt();
        image.setPixelRgba(x, y, enhanced, enhanced, enhanced, 255);
      }
    }
  }

  /// Optimized adaptive thresholding with reduced block size for performance
  void _applyAdaptiveThresholdOptimized(img.Image image) {
    final width = image.width;
    final height = image.height;
    final blockSize = math.min(11, math.min(width ~/ 10, height ~/ 10)); // Adaptive block size
    final offset = 8;

    // Create lookup table for faster processing
    final integralImage = _createIntegralImage(image);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final halfBlock = blockSize ~/ 2;
        final x1 = math.max(0, x - halfBlock);
        final y1 = math.max(0, y - halfBlock);
        final x2 = math.min(width - 1, x + halfBlock);
        final y2 = math.min(height - 1, y + halfBlock);

        final area = (x2 - x1 + 1) * (y2 - y1 + 1);
        final sum = _getIntegralSum(integralImage, x1, y1, x2, y2);
        final avg = sum ~/ area;

        final current = img.getLuminance(image.getPixel(x, y)).toInt();
        final color = current < (avg - offset) ? 0 : 255;
        image.setPixelRgba(x, y, color, color, color, 255);
      }
    }
  }

  /// Create integral image for fast area sum calculation
  List<List<int>> _createIntegralImage(img.Image image) {
    final width = image.width;
    final height = image.height;
    final integral = List.generate(height, (_) => List.filled(width, 0));

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = img.getLuminance(image.getPixel(x, y)).toInt();
        integral[y][x] = pixel;

        if (x > 0) integral[y][x] += integral[y][x - 1];
        if (y > 0) integral[y][x] += integral[y - 1][x];
        if (x > 0 && y > 0) integral[y][x] -= integral[y - 1][x - 1];
      }
    }

    return integral;
  }

  /// Get sum of area using integral image
  int _getIntegralSum(List<List<int>> integral, int x1, int y1, int x2, int y2) {
    int sum = integral[y2][x2];
    if (x1 > 0) sum -= integral[y2][x1 - 1];
    if (y1 > 0) sum -= integral[y1 - 1][x2];
    if (x1 > 0 && y1 > 0) sum += integral[y1 - 1][x1 - 1];
    return sum;
  }

  /// Safe noise removal with bounds checking
  void _removeNoiseSafely(img.Image image) {
    final width = image.width;
    final height = image.height;
    final tempImage = img.Image.from(image);

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        int blackPixels = 0;

        // Check 3x3 neighborhood
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && ny >= 0 && nx < width && ny < height) {
              final pixel = img.getLuminance(tempImage.getPixel(nx, ny)).toInt();
              if (pixel < 128) blackPixels++;
            }
          }
        }

        final newColor = (blackPixels >= 5) ? 0 : 255;
        image.setPixelRgba(x, y, newColor, newColor, newColor, 255);
      }
    }
  }

  /// Optimized adaptive histogram equalization
  void _applyAdaptiveHistogramEqualizationOptimized(img.Image image) {
    final tileSize = math.min(32, math.min(image.width ~/ 4, image.height ~/ 4));
    final originalImageCopy = img.Image.from(image);

    for (int tileY = 0; tileY < image.height; tileY += tileSize) {
      for (int tileX = 0; tileX < image.width; tileX += tileSize) {
        final endX = math.min(tileX + tileSize, image.width);
        final endY = math.min(tileY + tileSize, image.height);

        final histogram = List<int>.filled(256, 0);

        // Calculate histogram for this tile
        for (int y = tileY; y < endY; y++) {
          for (int x = tileX; x < endX; x++) {
            final pixel = originalImageCopy.getPixel(x, y);
            final gray = img.getLuminance(pixel).round().clamp(0, 255);
            histogram[gray]++;
          }
        }

        // Calculate cumulative distribution
        final cdf = List<int>.filled(256, 0);
        cdf[0] = histogram[0];
        for (int i = 1; i < 256; i++) {
          cdf[i] = cdf[i - 1] + histogram[i];
        }

        final totalPixels = (endX - tileX) * (endY - tileY);
        if (totalPixels == 0) continue;

        // Apply equalization to tile
        for (int y = tileY; y < endY; y++) {
          for (int x = tileX; x < endX; x++) {
            final pixel = originalImageCopy.getPixel(x, y);
            final gray = img.getLuminance(pixel).round().clamp(0, 255);
            final newGray = (cdf[gray] * 255 ~/ totalPixels).clamp(0, 255);

            // Avoid division by zero
            if (gray > 0) {
              final factor = newGray.toDouble() / gray.toDouble();
              final newR = (pixel.r.toDouble() * factor).round().clamp(0, 255);
              final newG = (pixel.g.toDouble() * factor).round().clamp(0, 255);
              final newB = (pixel.b.toDouble() * factor).round().clamp(0, 255);
              image.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
            }
          }
        }
      }
    }
  }

  /// Optimized text edge enhancement
  void _enhanceTextEdgesOptimized(img.Image image) {
    final originalImageCopy = img.Image.from(image);
    final width = image.width;
    final height = image.height;

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        // Simplified Sobel operator
        final gx = img.getLuminance(originalImageCopy.getPixel(x + 1, y)) -
            img.getLuminance(originalImageCopy.getPixel(x - 1, y));
        final gy = img.getLuminance(originalImageCopy.getPixel(x, y + 1)) -
            img.getLuminance(originalImageCopy.getPixel(x, y - 1));

        final magnitude = math.sqrt(gx * gx + gy * gy);
        final originalPixel = originalImageCopy.getPixel(x, y);

        final enhancement = (magnitude * 0.2).clamp(0, 30);
        final newR = (originalPixel.r.toDouble() + enhancement).clamp(0, 255).round();
        final newG = (originalPixel.g.toDouble() + enhancement).clamp(0, 255).round();
        final newB = (originalPixel.b.toDouble() + enhancement).clamp(0, 255).round();

        image.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
      }
    }
  }

  /// Optimized document sharpening
  void _applyDocumentSharpeningOptimized(img.Image image) {
    final originalImageCopy = img.Image.from(image);
    final width = image.width;
    final height = image.height;

    // Simplified sharpening kernel
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final center = originalImageCopy.getPixel(x, y);
        final top = originalImageCopy.getPixel(x, y - 1);
        final bottom = originalImageCopy.getPixel(x, y + 1);
        final left = originalImageCopy.getPixel(x - 1, y);
        final right = originalImageCopy.getPixel(x + 1, y);

        final newR = (center.r.toDouble() * 5 - top.r.toDouble() - bottom.r.toDouble() - left.r.toDouble() - right.r.toDouble()).clamp(0, 255).round();
        final newG = (center.g.toDouble() * 5 - top.g.toDouble() - bottom.g.toDouble() - left.g.toDouble() - right.g.toDouble()).clamp(0, 255).round();
        final newB = (center.b.toDouble() * 5 - top.b.toDouble() - bottom.b.toDouble() - left.b.toDouble() - right.b.toDouble()).clamp(0, 255).round();

        image.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
      }
    }
  }

  // Keep other existing methods with minimal changes for compatibility
  void _enhanceDocumentContrast(img.Image image) {
    final histogram = List<int>.filled(256, 0);
    final width = image.width;
    final height = image.height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = img.getLuminance(pixel).round().clamp(0, 255);
        histogram[gray]++;
      }
    }

    int minVal = 0, maxVal = 255;
    final totalPixels = width * height;
    int cumulative = 0;

    for (int i = 0; i < 256; i++) {
      cumulative += histogram[i];
      if (cumulative > totalPixels * 0.02 && minVal == 0) {
        minVal = i;
      }
      if (cumulative > totalPixels * 0.98 && maxVal == 255) {
        maxVal = i;
        break;
      }
    }

    final range = maxVal - minVal;
    if (range > 0) {
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final pixel = image.getPixel(x, y);
          final newR = ((pixel.r.toDouble() - minVal) * 255 / range).round().clamp(0, 255);
          final newG = ((pixel.g.toDouble() - minVal) * 255 / range).round().clamp(0, 255);
          final newB = ((pixel.b.toDouble() - minVal) * 255 / range).round().clamp(0, 255);
          image.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
        }
      }
    }
  }

  void _normalizeDocumentBrightness(img.Image image) {
    int totalBrightness = 0;
    final totalPixels = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        totalBrightness += img.getLuminance(pixel).round();
      }
    }

    final avgBrightness = totalBrightness / totalPixels;
    final targetBrightness = 180;
    final adjustment = targetBrightness - avgBrightness;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = (pixel.r.toDouble() + adjustment).clamp(0, 255).round();
        final g = (pixel.g.toDouble() + adjustment).clamp(0, 255).round();
        final b = (pixel.b.toDouble() + adjustment).clamp(0, 255).round();
        image.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }
  }

  void _optimizeDocumentContrast(img.Image image) {
    img.adjustColor(image, contrast: 1.2, brightness: 1.03, gamma: 1.05);
  }

  void _enhanceDocumentColors(img.Image image) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final newR = _enhanceChannel(pixel.r.toInt(), 1.15, 1.05);
        final newG = _enhanceChannel(pixel.g.toInt(), 1.15, 1.05);
        final newB = _enhanceChannel(pixel.b.toInt(), 1.15, 1.05);
        image.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
      }
    }
  }

  void _reduceColorNoise(img.Image image) {
    img.gaussianBlur(image, radius: 0.8.toInt());
  }

  void _applyGammaCorrection(img.Image image, double gamma) {
    final gammaTable = List<int>.generate(256,
            (i) => (255 * math.pow(i / 255.0, 1.0 / gamma)).round().clamp(0, 255));

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = gammaTable[pixel.r.toInt()];
        final g = gammaTable[pixel.g.toInt()];
        final b = gammaTable[pixel.b.toInt()];
        image.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }
  }

  int _enhanceChannel(int value, double contrast, double brightness) {
    final enhanced = (value * contrast + (brightness - 1) * 128);
    return enhanced.round().clamp(0, 255);
  }

  img.Image _cropDocument(img.Image image) {
    if (image.width > 1000 || image.height > 1000) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? 1000 : null,
        height: image.height > image.width ? 1000 : null,
      );
    }

    final grayImage = img.grayscale(img.Image.from(image));
    img.gaussianBlur(grayImage, radius: 1.5.toInt());
    final edges = _detectEdges(grayImage);
    final cropRect = _findDocumentBounds(edges);

    final padding = 15;
    final cropX = (cropRect.left.toDouble() - padding).clamp(0, image.width.toDouble()).toInt();
    final cropY = (cropRect.top.toDouble() - padding).clamp(0, image.height.toDouble()).toInt();
    final cropWidth = (cropRect.width.toDouble() + 2 * padding).clamp(0, (image.width - cropX).toDouble()).toInt();
    final cropHeight = (cropRect.height.toDouble() + 2 * padding).clamp(0, (image.height - cropY).toDouble()).toInt();

    return img.copyCrop(image, x: cropX, y: cropY, width: cropWidth, height: cropHeight);
  }

  img.Image _detectEdges(img.Image image) {
    final edges = img.Image(width: image.width, height: image.height);

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        final gx = img.getLuminance(image.getPixel(x + 1, y)) -
            img.getLuminance(image.getPixel(x - 1, y));
        final gy = img.getLuminance(image.getPixel(x, y + 1)) -
            img.getLuminance(image.getPixel(x, y - 1));

        final magnitude = math.sqrt(gx * gx + gy * gy);
        final intensity = (magnitude * 255).clamp(0, 255).toInt();
        edges.setPixel(x, y, img.ColorRgb8(intensity, intensity, intensity));
      }
    }

    return edges;
  }

  Rectangle<int> _findDocumentBounds(img.Image edges) {
    int minX = edges.width;
    int maxX = 0;
    int minY = edges.height;
    int maxY = 0;

    for (int y = 0; y < edges.height; y++) {
      for (int x = 0; x < edges.width; x++) {
        final pixel = edges.getPixel(x, y);
        final intensity = img.getLuminance(pixel);

        if (intensity > 40) {
          minX = math.min(minX, x);
          maxX = math.max(maxX, x);
          minY = math.min(minY, y);
          maxY = math.max(maxY, y);
        }
      }
    }

    if (minX >= maxX || minY >= maxY) {
      final centerX = edges.width ~/ 4;
      final centerY = edges.height ~/ 4;
      return Rectangle(centerX, centerY, edges.width ~/ 2, edges.height ~/ 2);
    }

    return Rectangle(minX, minY, maxX - minX, maxY - minY);
  }
}

class Rectangle<T extends num> {
  final T left;
  final T top;
  final T width;
  final T height;

  Rectangle(this.left, this.top, this.width, this.height);

  num get right => left + width;
  num get bottom => top + height;
}