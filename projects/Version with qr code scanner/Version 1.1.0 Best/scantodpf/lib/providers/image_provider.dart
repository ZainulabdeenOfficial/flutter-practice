// import 'package:flutter/material.dart';
// import 'dart:io';
// import '../models/image_item.dart';
// import '../services/storage_service.dart';
//
// class ImageProviderModel extends ChangeNotifier {
//   List<ImageItem> _images = [];
//   bool _isLoading = false;
//
//   List<ImageItem> get images => _images;
//   bool get isLoading => _isLoading;
//
//   Future<void> loadImages() async {
//     _isLoading = true;
//     notifyListeners();
//
//     try {
//       final imageFiles = await StorageService.instance.getImageFiles();
//       _images = imageFiles.map((file) => ImageItem(
//         id: file.path.hashCode.toString(),
//         path: file.path,
//         name: file.path.split('/').last,
//         size: file.lengthSync(),
//         createdAt: file.statSync().modified,
//       )).toList();
//     } catch (e) {
//       print('Error loading images: $e');
//       _images = [];
//     }
//
//     _isLoading = false;
//     notifyListeners();
//   }
//
//   Future<void> addImage(String imagePath) async {
//     final file = File(imagePath);
//     if (await file.exists()) {
//       final imageItem = ImageItem(
//         id: imagePath.hashCode.toString(),
//         path: imagePath,
//         name: imagePath.split('/').last,
//         size: await file.length(),
//         createdAt: DateTime.now(),
//       );
//
//       _images.insert(0, imageItem);
//       notifyListeners();
//     }
//   }
//
//   Future<void> removeImage(String imageId) async {
//     _images.removeWhere((image) => image.id == imageId);
//     notifyListeners();
//   }
//
//   void clearImages() {
//     _images.clear();
//     notifyListeners();
//   }
// }

import 'package:flutter/material.dart';
import 'dart:io';
import '../models/image_item.dart';
import '../services/storage_service.dart';

class ImageProviderModel extends ChangeNotifier {
  List<ImageItem> _images = [];
  bool _isLoading = false;

  List<ImageItem> get images => _images;
  bool get isLoading => _isLoading;

  Future<void> loadImages() async {
    _isLoading = true;
    notifyListeners();

    try {
      final imageFiles = await StorageService.instance.getImageFiles();
      _images = imageFiles.map((file) => ImageItem(
        id: file.path.hashCode.toString(),
        path: file.path,
        name: file.path.split('/').last,
        size: file.lengthSync(),
        createdAt: file.statSync().modified,
      )).toList();
    } catch (e) {
      print('Error loading images: $e');
      _images = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      final imageItem = ImageItem(
        id: imagePath.hashCode.toString(),
        path: imagePath,
        name: imagePath.split('/').last,
        size: await file.length(),
        createdAt: DateTime.now(),
      );

      _images.insert(0, imageItem);
      notifyListeners();
    }
  }

  Future<void> removeImage(String imageId) async {
    _images.removeWhere((image) => image.id == imageId);
    notifyListeners();
  }

  void clearImages() {
    _images.clear();
    notifyListeners();
  }
}
