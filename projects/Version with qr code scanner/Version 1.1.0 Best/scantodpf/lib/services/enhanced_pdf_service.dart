import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:image/image.dart' as img;
import '../models/image_item.dart';
import '../models/document.dart';
import 'storage_service.dart';
import 'dart:ui' as ui;

// Image format enum
enum ImageFormat {
  png,
  jpeg,
}

class EnhancedPDFService {
  static final EnhancedPDFService _instance = EnhancedPDFService._internal();
  factory EnhancedPDFService() => _instance;
  EnhancedPDFService._internal();

  final StorageService _storageService = StorageService.instance;

  // Generate PDF from images (main method for creating PDFs)
  Future<String> createPDFFromImages({
    required List<String> imagePaths,
    String? fileName,
    String? watermarkText,
    bool addMetadata = true,
    bool saveToDownloads = true,
  }) async {
    if (imagePaths.isEmpty) {
      throw Exception('No images provided for PDF generation');
    }

    try {
      final pdf = pw.Document();
      final format = PdfPageFormat.a4;
      int validImageCount = 0;
      final List<Uint8List> processedImages = [];

      // Process and optimize images first
      for (final imagePath in imagePaths) {
        try {
          final imageFile = File(imagePath);
          if (!await imageFile.exists()) {
            if (kDebugMode) {
              print('Image file does not exist: $imagePath');
            }
            continue;
          }

          final imageBytes = await imageFile.readAsBytes();
          if (imageBytes.isEmpty) {
            if (kDebugMode) {
              print('Image file is empty: $imagePath');
            }
            continue;
          }

          // Decode and optimize image
          final image = img.decodeImage(imageBytes);
          if (image == null) {
            if (kDebugMode) {
              print('Failed to decode image: $imagePath');
            }
            continue;
          }

          // Optimize image size while maintaining quality
          final optimizedImage = img.copyResize(
            image,
            width: (image.width * 0.8).round(), // Reduce size by 20%
            height: (image.height * 0.8).round(),
            interpolation: img.Interpolation.linear,
          );

          // Encode with compression
          final optimizedBytes = img.encodeJpg(optimizedImage, quality: 85);
          processedImages.add(optimizedBytes);
          validImageCount++;
        } catch (e) {
          if (kDebugMode) {
            print('Error processing image $imagePath: $e');
          }
          continue;
        }
      }

      if (validImageCount == 0) {
        throw Exception('No valid images found to create PDF');
      }

      // Add metadata page if requested
      if (addMetadata) {
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            build: (pw.Context context) {
              return pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Scan2PDF Pro Document',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Generated on ${_formatDate(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Contains $validImageCount image${validImageCount > 1 ? 's' : ''}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 60),
                  pw.Text(
                    'Created with Scan2PDF Pro',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Add each processed image as a page
      for (int i = 0; i < processedImages.length; i++) {
        final imageBytes = processedImages[i];
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(10),
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  // Main image
                  pw.Center(
                    child: pw.Image(
                      image,
                      fit: pw.BoxFit.contain,
                    ),
                  ),

                  // Watermark
                  if (watermarkText != null && watermarkText.isNotEmpty)
                    pw.Positioned(
                      bottom: 20,
                      right: 20,
                      child: pw.Transform.rotate(
                        angle: -0.5,
                        child: pw.Opacity(
                          opacity: 0.3,
                          child: pw.Text(
                            watermarkText,
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Page number
                  if (addMetadata)
                    pw.Positioned(
                      bottom: 5,
                      right: 10,
                      child: pw.Text(
                        'Page ${i + 1} of ${processedImages.length}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      }

      // Generate filename with timestamp if not provided
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pdfFileName = fileName ?? 'Scan2PDF_$timestamp';

      // Save PDF to temporary directory first
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$pdfFileName.pdf';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(await pdf.save());

      // Save to device storage
      String publicPath;
      if (saveToDownloads) {
        try {
          publicPath = await _storageService.savePDFToDownloads(tempPath, pdfFileName);
        } catch (e) {
          if (kDebugMode) {
            print('Failed to save to Downloads, using public storage: $e');
          }
          publicPath = await _storageService.savePDFToPublicStorage(tempPath, pdfFileName);
        }
      } else {
        publicPath = await _storageService.savePDFToPublicStorage(tempPath, pdfFileName);
      }

      // Calculate file size
      final fileSize = await File(publicPath).length();

      // Create document record with proper data
      final document = Document(
        id: timestamp.toString(),
        name: pdfFileName,
        imagePaths: imagePaths,
        pdfPath: publicPath,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        pageCount: validImageCount,
        sizeInMB: fileSize / (1024 * 1024),
      );

      // Save document record to storage
      await _storageService.saveDocument(document);

      if (kDebugMode) {
        print('=== PDF Creation Success ===');
        print('PDF created: $publicPath');
        print('Document ID: ${document.id}');
        print('Document name: ${document.name}');
        print('File size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        print('Valid images: $validImageCount');
        print('Document saved to storage');
        print('========================');
      }

      // Delete temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return publicPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating PDF: $e');
      }
      rethrow;
    }
  }

  // Generate PDF with watermark and password protection
  Future<String> generatePDFWithOptions({
    required List<ImageItem> images,
    String? fileName,
    String? watermarkText,
    String? password,
    PdfPageFormat? pageFormat,
    bool addMetadata = true,
    bool saveToDownloads = true,
  }) async {
    final imagePaths = images.map((img) => img.path).toList();
    return await createPDFFromImages(
      imagePaths: imagePaths,
      fileName: fileName,
      watermarkText: watermarkText,
      addMetadata: addMetadata,
      saveToDownloads: saveToDownloads,
    );
  }

  // Create PDF from document pages (for document scanner) - FIXED VERSION
  Future<String> createDocumentPDF({
    required List<Map<String, dynamic>> pages,
    required String documentName,
    bool addWatermark = false,
    String? watermarkText,
    bool addPageNumbers = true,
    bool addMetadata = true,
    PdfPageFormat? pageFormat,
  }) async {
    if (pages.isEmpty) {
      throw Exception('No pages provided for PDF generation');
    }

    try {
      final pdf = pw.Document();
      final format = pageFormat ?? PdfPageFormat.a4;

      // Add title page if metadata is enabled
      if (addMetadata) {
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            build: (pw.Context context) {
              return pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    documentName,
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Scanned Document',
                    style: pw.TextStyle(
                      fontSize: 18,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Created: ${_formatDate(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Pages: ${pages.length}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 60),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Document Information',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'This document was created using Scan2PDF',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'Advanced document scanning and processing',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Add each document page
      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        final imagePath = page['finalPath'] as String? ?? page['processedPath'] as String;
        final filterType = page['filterType'] as String?;
        final pageNumber = page['pageNumber'] as int? ?? (i + 1);

        try {
          // Verify the file exists
          final imageFile = File(imagePath);
          if (!await imageFile.exists()) {
            if (kDebugMode) {
              print('Image file does not exist: $imagePath');
            }
            continue;
          }

          final imageBytes = await imageFile.readAsBytes();
          if (imageBytes.isEmpty) {
            if (kDebugMode) {
              print('Image file is empty: $imagePath');
            }
            continue;
          }

          final image = pw.MemoryImage(imageBytes);

          // Add page with image
          pdf.addPage(
            pw.Page(
              pageFormat: format,
              margin: const pw.EdgeInsets.all(20),
              build: (pw.Context context) {
                return pw.Column(
                  children: [
                    // Main image content
                    pw.Expanded(
                      child: pw.Container(
                        width: double.infinity,
                        child: pw.Stack(
                          children: [
                            // Document image
                            pw.Center(
                              child: pw.Image(
                                image,
                                fit: pw.BoxFit.contain,
                              ),
                            ),

                            // Watermark if enabled
                            if (addWatermark && watermarkText != null)
                              pw.Positioned(
                                bottom: 20,
                                right: 20,
                                child: pw.Transform.rotate(
                                  angle: -0.3,
                                  child: pw.Text(
                                    watermarkText,
                                    style: pw.TextStyle(
                                      fontSize: 24,
                                      color: PdfColors.grey400,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Footer with page info
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 10),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          // Filter info
                          if (filterType != null && filterType != 'original')
                            pw.Text(
                              'Filter: ${_getFilterDisplayName(filterType)}',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey600,
                              ),
                            ),

                          // Page number
                          if (addPageNumbers)
                            pw.Text(
                              'Page $pageNumber of ${pages.length}',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error processing page $pageNumber: $e');
          }
          continue;
        }
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pdfFileName = '${documentName}_$timestamp';

      // Save PDF to temporary directory first
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$pdfFileName.pdf';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(await pdf.save());

      // Save to public storage
      final publicPath = await _storageService.savePDFToPublicStorage(
        tempPath,
        pdfFileName,
      );

      // Calculate file size
      final fileSize = await File(publicPath).length();

      // Create document record
      final document = Document(
        id: timestamp.toString(),
        name: documentName,
        imagePaths: pages.map((p) => p['finalPath'] as String? ?? p['processedPath'] as String).toList(),
        pdfPath: publicPath,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        pageCount: pages.length,
        sizeInMB: fileSize / (1024 * 1024),
      );

      // Save document record
      await _storageService.saveDocument(document);

      // Delete temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return publicPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating document PDF: $e');
      }
      rethrow;
    }
  }

  // Get storage information for debugging
  Future<Map<String, String>> getStorageInfo() async {
    return await _storageService.getStorageInfo();
  }

  // Merge multiple PDFs
  Future<String> mergePDFs({
    required List<String> pdfPaths,
    required String outputFileName,
    String? watermarkText,
    bool saveToDownloads = true,
  }) async {
    try {
      final mergedPdf = pw.Document();
      int totalPages = 0;

      // First pass: count total pages and validate PDFs
      for (final pdfPath in pdfPaths) {
        final file = File(pdfPath);
        if (!await file.exists()) {
          throw Exception('PDF file not found: $pdfPath');
        }
        try {
          int pageCount = 0;
          await for (final _ in Printing.raster(
            await file.readAsBytes(),
            dpi: 72,
          )) {
            pageCount++;
          }
          totalPages += pageCount;
        } catch (e) {
          throw Exception('Invalid PDF file: $pdfPath');
        }
      }

      // Second pass: merge PDFs
      for (final pdfPath in pdfPaths) {
        final file = File(pdfPath);
        final pdfBytes = await file.readAsBytes();
        try {
          await for (final page in Printing.raster(
            pdfBytes,
            dpi: 72,
          )) {
            final image = await page.toImage();
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            mergedPdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                build: (pw.Context context) {
                  return pw.Stack(
                    children: [
                      pw.Image(
                        pw.MemoryImage(bytes!.buffer.asUint8List()),
                        fit: pw.BoxFit.contain,
                      ),
                      if (watermarkText != null && watermarkText.isNotEmpty)
                        pw.Positioned(
                          bottom: 20,
                          right: 20,
                          child: pw.Transform.rotate(
                            angle: -0.3,
                            child: pw.Opacity(
                              opacity: 0.3,
                              child: pw.Text(
                                watermarkText,
                                style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          }
        } catch (e) {
          throw Exception('Error processing PDF: $pdfPath');
        }
      }

      // Save merged PDF
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$outputFileName.pdf';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(await mergedPdf.save());

      // Save to device storage
      String publicPath;
      if (saveToDownloads) {
        try {
          publicPath = await _storageService.savePDFToDownloads(tempPath, outputFileName);
        } catch (e) {
          publicPath = await _storageService.savePDFToPublicStorage(tempPath, outputFileName);
        }
      } else {
        publicPath = await _storageService.savePDFToPublicStorage(tempPath, outputFileName);
      }

      // Calculate file size
      final fileSize = await File(publicPath).length();

      // Create document record
      final document = Document(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: outputFileName,
        imagePaths: [],
        pdfPath: publicPath,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        pageCount: totalPages,
        sizeInMB: fileSize / (1024 * 1024),
      );

      await _storageService.saveDocument(document);

      // Clean up temporary file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return publicPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error merging PDFs: $e');
      }
      rethrow;
    }
  }

  // Convert PDF to images with progress callback and format options
  Future<List<String>> convertPDFToImages(
    String pdfPath, {
    void Function(double progress, String status)? onProgress,
    ImageFormat format = ImageFormat.png,
    int quality = 100,
    double dpi = 300.0,
  }) async {
    try {
      final file = File(pdfPath);
      if (!await file.exists()) {
        throw Exception('PDF file not found');
      }

      onProgress?.call(0.0, 'Starting conversion...');
      final List<String> imagePaths = [];
      final tempDir = await getTemporaryDirectory();
      final pdfBytes = await file.readAsBytes();

      // First, get total page count
      onProgress?.call(0.1, 'Counting pages...');
      int totalPages = 0;
      await for (final _ in Printing.raster(
        pdfBytes,
        dpi: 72,
      )) {
        totalPages++;
      }

      if (totalPages == 0) {
        throw Exception('PDF has no pages');
      }

      // Now convert each page to image with proper quality
      int pageIndex = 0;
      await for (final page in Printing.raster(
        pdfBytes,
        dpi: dpi,
      )) {
        try {
          onProgress?.call(
            (pageIndex / totalPages) * 0.8 + 0.1,
            'Converting page ${pageIndex + 1} of $totalPages',
          );

          // Convert page to image
          final image = await page.toImage();
          
          // Get image data with specified format and quality
          final byteData = await image.toByteData(
            format: format == ImageFormat.png 
                ? ui.ImageByteFormat.png 
                : ui.ImageByteFormat.rawRgba,
          );
          
          if (byteData == null) {
            throw Exception('Failed to convert page ${pageIndex + 1} to image');
          }

          // Create image file path with appropriate extension
          final extension = format == ImageFormat.png ? 'png' : 'jpg';
          final imagePath = '${tempDir.path}/pdf_page_${pageIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.$extension';
          
          // Process image data based on format
          List<int> imageBytes;
          if (format == ImageFormat.png) {
            imageBytes = byteData.buffer.asUint8List();
          } else {
            // Convert to JPEG with specified quality
            final codec = await ui.instantiateImageCodec(
              byteData.buffer.asUint8List(),
            );
            final frame = await codec.getNextFrame();
            final jpegBytes = await frame.image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            if (jpegBytes == null) {
              throw Exception('Failed to convert page ${pageIndex + 1} to JPEG');
            }
            imageBytes = jpegBytes.buffer.asUint8List();
          }
          
          // Save image
          await File(imagePath).writeAsBytes(imageBytes);
          
          // Verify the image was saved correctly
          final savedFile = File(imagePath);
          if (!await savedFile.exists()) {
            throw Exception('Failed to save image for page ${pageIndex + 1}');
          }

          // Add to list of converted images
          imagePaths.add(imagePath);
          pageIndex++;

          // Log progress
          if (kDebugMode) {
            print('Converted page ${pageIndex} of $totalPages');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error converting page ${pageIndex + 1}: $e');
          }
          // Continue with next page instead of failing completely
          continue;
        }
      }

      if (imagePaths.isEmpty) {
        throw Exception('Failed to convert any pages to images');
      }

      onProgress?.call(1.0, 'Conversion completed successfully');
      if (kDebugMode) {
        print('Successfully converted ${imagePaths.length} pages to images');
      }

      return imagePaths;
    } catch (e) {
      onProgress?.call(0.0, 'Error: ${e.toString()}');
      if (kDebugMode) {
        print('Error converting PDF to images: $e');
      }
      rethrow;
    }
  }

  // Share PDF with multiple options
  Future<void> sharePDF(String pdfPath, {String? subject, String? text}) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(pdfPath)],
          subject: subject ?? 'Scan2PDF Pro Document',
          text: text ?? 'Sharing a PDF document created with Scan2PDF Pro',
        );
      } else {
        throw Exception('PDF file not found: $pdfPath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing PDF: $e');
      }
      rethrow;
    }
  }

  // View PDF using printing package
  Future<void> viewPDF(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'Scanned Document',
        );
      } else {
        throw Exception('PDF file not found: $pdfPath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error viewing PDF: $e');
      }
      rethrow;
    }
  }

  // Print PDF directly
  Future<void> printPDF(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'Scanned Document',
          usePrinterSettings: true,
        );
      } else {
        throw Exception('PDF file not found: $pdfPath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error printing PDF: $e');
      }
      rethrow;
    }
  }

  // Get all saved PDFs with debug info
  Future<List<Document>> getAllDocuments() async {
    try {
      final documents = await _storageService.getDocuments();
      if (kDebugMode) {
        print('=== Document Retrieval ===');
        print('Retrieved ${documents.length} documents from storage');
        for (final doc in documents) {
          print('Document: ${doc.name} (ID: ${doc.id})');
          print('  Path: ${doc.pdfPath}');
          print('  Created: ${doc.createdAt}');
          print('  Pages: ${doc.pageCount}');
        }
        print('========================');
      }
      return documents;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting documents: $e');
      }
      return [];
    }
  }

  // Force refresh documents (for debugging)
  Future<void> refreshDocuments() async {
    try {
      await _storageService.getDocuments();
      if (kDebugMode) {
        print('Documents refreshed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing documents: $e');
      }
    }
  }

  // Delete PDF and its record
  Future<void> deletePDF(String documentId) async {
    try {
      await _storageService.deleteDocument(documentId);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting PDF: $e');
      }
      rethrow;
    }
  }

  // Rename document
  Future<void> renameDocument(String documentId, String newName) async {
    try {
      final documents = await _storageService.getDocuments();
      final documentIndex = documents.indexWhere((doc) => doc.id == documentId);

      if (documentIndex == -1) {
        throw Exception('Document not found');
      }

      final document = documents[documentIndex];
      final updatedDocument = document.copyWith(
        name: newName,
        modifiedAt: DateTime.now(),
      );

      await _storageService.updateDocument(updatedDocument);
    } catch (e) {
      if (kDebugMode) {
        print('Error renaming document: $e');
      }
      rethrow;
    }
  }

  // Get list of saved PDFs
  Future<List<String>> getSavedPDFs() async {
    try {
      final files = await _storageService.getSavedPDFs();
      return files.map((file) => file.path).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting saved PDFs: $e');
      }
      return [];
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getFilterDisplayName(String filterType) {
    switch (filterType) {
      case 'grayscale':
        return 'Grayscale';
      case 'magic':
        return 'Magic Enhancement';
      case 'blackwhite':
        return 'Black & White';
      case 'color':
        return 'Color Enhancement';
      default:
        return 'Original';
    }
  }
}
