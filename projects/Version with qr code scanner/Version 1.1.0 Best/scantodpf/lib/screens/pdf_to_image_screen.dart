import 'package:flutter/material.dart';
import 'dart:io';
import '../services/enhanced_pdf_service.dart';
import '../models/document.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PDFToImageScreen extends StatefulWidget {
  final Document document;

  const PDFToImageScreen({super.key, required this.document});

  @override
  State<PDFToImageScreen> createState() => _PDFToImageScreenState();
}

class _PDFToImageScreenState extends State<PDFToImageScreen> {
  final EnhancedPDFService _pdfService = EnhancedPDFService();
  List<String> _extractedImages = [];
  bool _isConverting = false;
  bool _isCompleted = false;
  String _currentStatus = '';
  double _progress = 0.0;
  String? _pdfPath;
  ImageFormat _selectedFormat = ImageFormat.png;
  int _selectedQuality = 100;
  double _selectedDpi = 300.0;

  @override
  void initState() {
    super.initState();
    _pdfPath = widget.document.pdfPath;
    _convertPDFToImages();
  }

  Future<void> _convertPDFToImages() async {
    if (_pdfPath == null) return;

    setState(() {
      _isConverting = true;
      _isCompleted = false;
      _currentStatus = 'Starting conversion...';
      _progress = 0.0;
    });

    try {
      final imagePaths = await _pdfService.convertPDFToImages(
        _pdfPath!,
        onProgress: (progress, status) {
          setState(() {
            _progress = progress;
            _currentStatus = status;
          });
        },
        format: _selectedFormat,
        quality: _selectedQuality,
        dpi: _selectedDpi,
      );

      setState(() {
        _isConverting = false;
        _isCompleted = true;
        _currentStatus = 'Conversion completed';
        _progress = 1.0;
        _extractedImages = imagePaths;
      });
    } catch (e) {
      setState(() {
        _isConverting = false;
        _currentStatus = 'Error: ${e.toString()}';
        _progress = 0.0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to convert PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pdfPath = result.files.first.path;
          _isCompleted = false;
          _extractedImages = [];
        });
        _convertPDFToImages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareImage(String imagePath) async {
    try {
      final file = XFile(imagePath);
      await Share.shareXFiles(
        [file],
        text: 'Image from PDF',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareAllImages() async {
    try {
      final files = _extractedImages.map((path) => XFile(path)).toList();
      await Share.shareXFiles(
        files,
        text: 'Images from PDF',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing images: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveImage(String imagePath) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission not granted');
      }

      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found');
      }

      // Get the Pictures directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access external storage');
      }

      // Create Scan2PDF directory if it doesn't exist
      final scanDir = Directory('${directory.path}/Scan2PDF');
      if (!await scanDir.exists()) {
        await scanDir.create(recursive: true);
      }

      // Copy the file to the gallery directory
      final fileName = 'PDF_Page_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedFile = await file.copy('${scanDir.path}/$fileName');

      if (await savedFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image saved to gallery'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to save image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAllImages() async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission not granted');
      }

      setState(() {
        _isConverting = true;
        _currentStatus = 'Saving images to gallery...';
        _progress = 0.0;
      });

      // Get the Pictures directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access external storage');
      }

      // Create Scan2PDF directory if it doesn't exist
      final scanDir = Directory('${directory.path}/Scan2PDF');
      if (!await scanDir.exists()) {
        await scanDir.create(recursive: true);
      }

      for (int i = 0; i < _extractedImages.length; i++) {
        final imagePath = _extractedImages[i];
        final file = File(imagePath);
        if (!await file.exists()) {
          continue;
        }

        // Copy the file to the gallery directory
        final fileName = 'PDF_Page_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.png';
        await file.copy('${scanDir.path}/$fileName');

        setState(() {
          _progress = (i + 1) / _extractedImages.length;
          _currentStatus = 'Saving image ${i + 1} of ${_extractedImages.length}';
        });
      }

      setState(() {
        _isConverting = false;
        _currentStatus = 'All images saved successfully';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All images saved to gallery'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConverting = false;
        _currentStatus = 'Error saving images';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving images: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'PDF to Images',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
        actions: [
          if (_isCompleted) ...[
            IconButton(
              icon: const Icon(Icons.save_alt),
              onPressed: _saveAllImages,
              tooltip: 'Save All Images',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareAllImages,
              tooltip: 'Share All Images',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (!_isCompleted && !_isConverting)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<ImageFormat>(
                    value: _selectedFormat,
                    decoration: const InputDecoration(
                      labelText: 'Image Format',
                      border: OutlineInputBorder(),
                    ),
                    items: ImageFormat.values.map((format) {
                      return DropdownMenuItem(
                        value: format,
                        child: Text(format.toString().split('.').last.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedFormat = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedFormat == ImageFormat.jpeg)
                    DropdownButtonFormField<int>(
                      value: _selectedQuality,
                      decoration: const InputDecoration(
                        labelText: 'Image Quality',
                        border: OutlineInputBorder(),
                      ),
                      items: [60, 70, 80, 90, 100].map((quality) {
                        return DropdownMenuItem(
                          value: quality,
                          child: Text('$quality%'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedQuality = value);
                        }
                      },
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<double>(
                    value: _selectedDpi,
                    decoration: const InputDecoration(
                      labelText: 'Image Resolution (DPI)',
                      border: OutlineInputBorder(),
                    ),
                    items: [150.0, 200.0, 300.0, 400.0, 600.0].map((dpi) {
                      return DropdownMenuItem(
                        value: dpi,
                        child: Text('$dpi DPI'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedDpi = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _selectPDF,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Select PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
          if (_isConverting)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 8),
                  Text(_currentStatus),
                ],
              ),
            ),
          if (_isCompleted)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Extracted ${_extractedImages.length} images',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: _extractedImages.length,
                        itemBuilder: (context, index) {
                          final imagePath = _extractedImages[index];
                          final fileName = path.basename(imagePath);
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Container(
                                    color: Colors.grey[100],
                                    child: File(imagePath).existsSync()
                                        ? Image.file(
                                            File(imagePath),
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(
                                            Icons.image,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Page ${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        fileName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.share, size: 20),
                                            onPressed: () => _shareImage(imagePath),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.save_alt, size: 20),
                                            onPressed: () => _saveImage(imagePath),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
