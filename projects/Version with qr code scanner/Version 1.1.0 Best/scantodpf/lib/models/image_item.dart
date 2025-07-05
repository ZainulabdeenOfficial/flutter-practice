import 'dart:io';

class ImageItem {
  final String id;
  final String path;
  final String name;
  final int size;
  final DateTime createdAt;

  ImageItem({
    required this.id,
    required this.path,
    required this.name,
    required this.size,
    required this.createdAt,
  });

  // Add this getter
  File get file => File(path);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'size': size,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ImageItem.fromJson(Map<String, dynamic> json) {
    return ImageItem(
      id: json['id'],
      path: json['path'],
      name: json['name'],
      size: json['size'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  String get sizeFormatted {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

