import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/document.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance!;

  late Directory _appDirectory;
  late Directory _documentsDirectory;
  late Directory _imagesDirectory;
  late Directory _pdfsDirectory;
  late Directory _publicPdfsDirectory;

  static Future<void> initialize() async {
    _instance = StorageService._();
    await _instance!._init();
  }

  StorageService._();

  Future<void> _init() async {
    // Request storage permissions
    await _requestStoragePermissions();

    // Get app-specific directory
    _appDirectory = await getApplicationDocumentsDirectory();
    _documentsDirectory = Directory('${_appDirectory.path}/documents');
    _imagesDirectory = Directory('${_appDirectory.path}/images');
    _pdfsDirectory = Directory('${_appDirectory.path}/pdfs');

    // Get public storage directory for PDFs
    try {
      // Try to get external storage directory (Android)
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        _publicPdfsDirectory = Directory('${externalDir.path}/Scan2PDF');
      } else {
        // Fallback to downloads directory
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          _publicPdfsDirectory = Directory('${downloadsDir.path}/Scan2PDF');
        } else {
          // Final fallback to app directory
          _publicPdfsDirectory = Directory('${_appDirectory.path}/pdfs');
        }
      }
    } catch (e) {
      print('Error getting external storage: $e');
      _publicPdfsDirectory = Directory('${_appDirectory.path}/pdfs');
    }

    // Create directories if they don't exist
    await _documentsDirectory.create(recursive: true);
    await _imagesDirectory.create(recursive: true);
    await _pdfsDirectory.create(recursive: true);
    await _publicPdfsDirectory.create(recursive: true);

    print('Storage initialized:');
    print('App directory: ${_appDirectory.path}');
    print('Public PDFs directory: ${_publicPdfsDirectory.path}');
  }

  Future<void> _requestStoragePermissions() async {
    try {
      // Request storage permissions for Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isDenied) {
          print('Storage permission denied');
        }

        // For Android 11+ (API 30+), request MANAGE_EXTERNAL_STORAGE
        final manageStatus = await Permission.manageExternalStorage.request();
        if (manageStatus.isDenied) {
          print('Manage external storage permission denied');
        }
      }
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  // Document operations
  Future<List<Document>> getDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final documentsJson = prefs.getStringList('documents') ?? [];

      return documentsJson.map((json) {
        final Map<String, dynamic> data = jsonDecode(json);
        return Document.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error loading documents: $e');
      return [];
    }
  }

  Future<void> saveDocument(Document document) async {
    try {
      final documents = await getDocuments();
      final existingIndex = documents.indexWhere((d) => d.id == document.id);

      if (existingIndex >= 0) {
        documents[existingIndex] = document;
      } else {
        documents.add(document);
      }

      final prefs = await SharedPreferences.getInstance();
      final documentsJson = documents.map((doc) => jsonEncode(doc.toJson())).toList();
      await prefs.setStringList('documents', documentsJson);

      print('Document saved: ${document.name} at ${document.pdfPath}');
    } catch (e) {
      print('Error saving document: $e');
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      final documents = await getDocuments();
      final document = documents.firstWhere((d) => d.id == documentId);

      // Delete associated files
      for (final imagePath in document.imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      if (document.pdfPath != null) {
        final pdfFile = File(document.pdfPath!);
        if (await pdfFile.exists()) {
          await pdfFile.delete();
        }
      }

      // Remove from list
      documents.removeWhere((d) => d.id == documentId);

      final prefs = await SharedPreferences.getInstance();
      final documentsJson = documents.map((doc) => jsonEncode(doc.toJson())).toList();
      await prefs.setStringList('documents', documentsJson);
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  Future<void> updateDocument(Document document) async {
    try {
      final documents = await getDocuments();
      final documentIndex = documents.indexWhere((doc) => doc.id == document.id);

      if (documentIndex != -1) {
        documents[documentIndex] = document;
        final prefs = await SharedPreferences.getInstance();
        final documentsJson = documents.map((doc) => jsonEncode(doc.toJson())).toList();
        await prefs.setStringList('documents', documentsJson);
      } else {
        throw Exception('Document not found for update');
      }
    } catch (e) {
      print('Error updating document: $e');
      rethrow;
    }
  }

  // File operations
  Future<String> saveImageFile(File imageFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = File('${_imagesDirectory.path}/$fileName');
    await imageFile.copy(savedFile.path);
    return savedFile.path;
  }

  // Save PDF to public device storage (accessible by other apps)
  Future<String> savePDFToPublicStorage(String tempPath, String fileName) async {
    try {
      // Ensure the filename has .pdf extension
      if (!fileName.toLowerCase().endsWith('.pdf')) {
        fileName = '$fileName.pdf';
      }

      // Create unique filename if file already exists
      String finalFileName = fileName;
      int counter = 1;
      while (await File('${_publicPdfsDirectory.path}/$finalFileName').exists()) {
        final nameWithoutExt = fileName.replaceAll('.pdf', '');
        finalFileName = '${nameWithoutExt}_$counter.pdf';
        counter++;
      }

      final savedFile = File('${_publicPdfsDirectory.path}/$finalFileName');
      await File(tempPath).copy(savedFile.path);

      print('PDF saved to public storage: ${savedFile.path}');

      // Also save a copy to app-specific directory as backup
      final backupFile = File('${_pdfsDirectory.path}/$finalFileName');
      await File(tempPath).copy(backupFile.path);

      return savedFile.path;
    } catch (e) {
      print('Error saving PDF to public storage: $e');
      // Fallback to app-specific directory
      final fallbackFile = File('${_pdfsDirectory.path}/$fileName');
      await File(tempPath).copy(fallbackFile.path);
      return fallbackFile.path;
    }
  }

  // Save PDF to Downloads folder (more accessible)
  Future<String> savePDFToDownloads(String tempPath, String fileName) async {
    try {
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        // Try to get Downloads directory
        downloadsDir = Directory('/storage/emulated/0/Download/Scan2PDF');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
      } else if (Platform.isIOS) {
        // For iOS, use Documents directory
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir != null) {
        // Ensure the filename has .pdf extension
        if (!fileName.toLowerCase().endsWith('.pdf')) {
          fileName = '$fileName.pdf';
        }

        final savedFile = File('${downloadsDir.path}/$fileName');
        await File(tempPath).copy(savedFile.path);

        print('PDF saved to Downloads: ${savedFile.path}');
        return savedFile.path;
      } else {
        throw Exception('Could not access Downloads directory');
      }
    } catch (e) {
      print('Error saving to Downloads: $e');
      // Fallback to public storage method
      return await savePDFToPublicStorage(tempPath, fileName);
    }
  }

  Future<List<File>> getImageFiles() async {
    try {
      final files = _imagesDirectory.listSync()
          .where((entity) => entity is File && entity.path.toLowerCase().endsWith('.jpg'))
          .cast<File>()
          .toList();

      // Sort by modification date (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return files;
    } catch (e) {
      print('Error getting image files: $e');
      return [];
    }
  }

  Future<List<File>> getSavedPDFs() async {
    try {
      final List<File> allPdfs = [];

      // Get PDFs from public directory
      if (await _publicPdfsDirectory.exists()) {
        final publicFiles = _publicPdfsDirectory.listSync()
            .where((entity) => entity is File && entity.path.toLowerCase().endsWith('.pdf'))
            .cast<File>()
            .toList();
        allPdfs.addAll(publicFiles);
      }

      // Get PDFs from app directory (backup)
      if (await _pdfsDirectory.exists()) {
        final appFiles = _pdfsDirectory.listSync()
            .where((entity) => entity is File && entity.path.toLowerCase().endsWith('.pdf'))
            .cast<File>()
            .toList();

        // Add only files that don't already exist in public directory
        for (final file in appFiles) {
          final fileName = file.path.split('/').last;
          final existsInPublic = allPdfs.any((pdf) => pdf.path.endsWith(fileName));
          if (!existsInPublic) {
            allPdfs.add(file);
          }
        }
      }

      // Sort by modification date (newest first)
      allPdfs.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      return allPdfs;
    } catch (e) {
      print('Error getting PDF files: $e');
      return [];
    }
  }

  // Get storage info
  Future<Map<String, String>> getStorageInfo() async {
    return {
      'appDirectory': _appDirectory.path,
      'publicPdfsDirectory': _publicPdfsDirectory.path,
      'documentsDirectory': _documentsDirectory.path,
      'imagesDirectory': _imagesDirectory.path,
    };
  }

  // Check if file exists in public storage
  Future<bool> fileExistsInPublicStorage(String fileName) async {
    final file = File('${_publicPdfsDirectory.path}/$fileName');
    return await file.exists();
  }

  // Directory getters
  Directory get documentsDirectory => _documentsDirectory;
  Directory get imagesDirectory => _imagesDirectory;
  Directory get pdfsDirectory => _pdfsDirectory;
  Directory get publicPdfsDirectory => _publicPdfsDirectory;
}

