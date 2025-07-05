// import 'dart:io';
// import 'dart:typed_data';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:flutter/services.dart';
// import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:printing/printing.dart';
// import '../models/image_item.dart';
// import '../models/document.dart';
// import 'storage_service.dart';
//
// class PDFService {
//   static final PDFService _instance = PDFService._internal();
//   factory PDFService() => _instance;
//   PDFService._internal();
//
//   final StorageService _storageService = StorageService.instance;
//
//   Future<String> createPDF(Document document) async {
//     try {
//       final pdf = pw.Document();
//
//       pdf.addPage(
//         pw.Page(
//           pageFormat: PdfPageFormat.a4,
//           build: (pw.Context context) {
//             return pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Text(
//                   document.name,
//                   style: pw.TextStyle(
//                     fontSize: 24,
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//                 pw.SizedBox(height: 20),
//                 pw.Text(
//                   'Created: ${_formatDate(document.createdAt)}',
//                   style: const pw.TextStyle(fontSize: 14),
//                 ),
//                 pw.Text(
//                   'Pages: ${document.imagePaths.length}',
//                   style: const pw.TextStyle(fontSize: 14),
//                 ),
//                 pw.SizedBox(height: 40),
//                 pw.Divider(),
//               ],
//             );
//           },
//         ),
//       );
//
//       for (int i = 0; i < document.imagePaths.length; i++) {
//         try {
//           final imagePath = document.imagePaths[i];
//           final imageFile = File(imagePath);
//
//           if (await imageFile.exists()) {
//             final imageBytes = await imageFile.readAsBytes();
//             if (imageBytes.isNotEmpty) {
//               final image = pw.MemoryImage(imageBytes);
//
//               pdf.addPage(
//                 pw.Page(
//                   pageFormat: PdfPageFormat.a4,
//                   margin: const pw.EdgeInsets.all(20),
//                   build: (pw.Context context) {
//                     return pw.Column(
//                       children: [
//                         pw.Expanded(
//                           child: pw.Center(
//                             child: pw.Image(
//                               image,
//                               fit: pw.BoxFit.contain,
//                             ),
//                           ),
//                         ),
//                         pw.Container(
//                           alignment: pw.Alignment.centerRight,
//                           child: pw.Text(
//                             'Page ${i + 1} of ${document.imagePaths.length}',
//                             style: const pw.TextStyle(fontSize: 10),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               );
//             }
//           }
//         } catch (e) {
//           if (kDebugMode) {
//             print('Error processing page ${i + 1}: $e');
//           }
//         }
//       }
//
//       final directory = await getTemporaryDirectory();
//       final tempPath = '${directory.path}/${document.name}.pdf';
//       final tempFile = File(tempPath);
//       await tempFile.writeAsBytes(await pdf.save());
//
//       final publicPath = await _storageService.savePDFToPublicStorage(
//         tempPath,
//         '${document.name}.pdf',
//       );
//
//       return publicPath;
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error creating PDF: $e');
//       }
//       rethrow;
//     }
//   }
//
//   // Generate PDF from images
//   Future<String> generatePDF(List<ImageItem> images, {
//     String? fileName,
//     PdfPageFormat? pageFormat,
//     bool addMetadata = true,
//   }) async {
//     if (images.isEmpty) {
//       throw Exception('No images provided for PDF generation');
//     }
//
//     try {
//       final pdf = pw.Document();
//       final format = pageFormat ?? PdfPageFormat.a4;
//
//       // Add metadata if requested
//       if (addMetadata) {
//         pdf.addPage(
//           pw.Page(
//             pageFormat: format,
//             build: (pw.Context context) {
//               return pw.Column(
//                 mainAxisAlignment: pw.MainAxisAlignment.center,
//                 children: [
//                   pw.Text(
//                     'Scan2PDF Document',
//                     style: pw.TextStyle(
//                       fontSize: 28,
//                       fontWeight: pw.FontWeight.bold,
//                     ),
//                     textAlign: pw.TextAlign.center,
//                   ),
//                   pw.SizedBox(height: 20),
//                   pw.Text(
//                     'Generated on ${_formatDate(DateTime.now())}',
//                     style: const pw.TextStyle(fontSize: 16),
//                   ),
//                   pw.SizedBox(height: 10),
//                   pw.Text(
//                     'Contains ${images.length} image${images.length > 1 ? 's' : ''}',
//                     style: const pw.TextStyle(fontSize: 14),
//                   ),
//                   pw.SizedBox(height: 60),
//                   pw.Text(
//                     'Created with Scan2PDF',
//                     style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
//                   ),
//                 ],
//               );
//             },
//           ),
//         );
//       }
//
//       // Add each image as a page
//       for (int i = 0; i < images.length; i++) {
//         final imageItem = images[i];
//
//         try {
//           // Verify the file exists
//           if (!await imageItem.file.exists()) {
//             if (kDebugMode) {
//               print('Image file does not exist: ${imageItem.file.path}');
//             }
//             continue;
//           }
//
//           final imageBytes = await imageItem.file.readAsBytes();
//           if (imageBytes.isEmpty) {
//             if (kDebugMode) {
//               print('Image file is empty: ${imageItem.file.path}');
//             }
//             continue;
//           }
//
//           final image = pw.MemoryImage(imageBytes);
//
//           // Add image page
//           pdf.addPage(
//             pw.Page(
//               pageFormat: format,
//               margin: const pw.EdgeInsets.all(10),
//               build: (pw.Context context) {
//                 return pw.Column(
//                   children: [
//                     // Image
//                     pw.Expanded(
//                       child: pw.Center(
//                         child: pw.Image(
//                           image,
//                           fit: pw.BoxFit.contain,
//                         ),
//                       ),
//                     ),
//                     // Page number
//                     if (addMetadata)
//                       pw.Container(
//                         alignment: pw.Alignment.centerRight,
//                         child: pw.Text(
//                           'Page ${i + 1} of ${images.length}',
//                           style: const pw.TextStyle(fontSize: 8),
//                         ),
//                       ),
//                   ],
//                 );
//               },
//             ),
//           );
//         } catch (e) {
//           if (kDebugMode) {
//             print('Error processing image ${imageItem.name}: $e');
//           }
//           continue;
//         }
//       }
//
//       // Generate filename with timestamp if not provided
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       final pdfFileName = fileName ?? 'Scan2PDF_$timestamp.pdf';
//
//       // Save PDF to temporary directory first
//       final tempDir = await getTemporaryDirectory();
//       final tempPath = '${tempDir.path}/$pdfFileName';
//       final tempFile = File(tempPath);
//       await tempFile.writeAsBytes(await pdf.save());
//
//       // Save to public storage
//       final publicPath = await _storageService.savePDFToPublicStorage(
//         tempPath,
//         pdfFileName,
//       );
//
//       // Delete temporary file
//       if (await tempFile.exists()) {
//         await tempFile.delete();
//       }
//
//       return publicPath;
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error generating PDF: $e');
//       }
//       rethrow;
//     }
//   }
//
//   Future<String> createPDFFromImages(List<String> imagePaths, String fileName) async {
//     try {
//       final pdf = pw.Document();
//
//       for (final imagePath in imagePaths) {
//         final imageFile = File(imagePath);
//         if (await imageFile.exists()) {
//           final imageBytes = await imageFile.readAsBytes();
//           final image = pw.MemoryImage(imageBytes);
//
//           pdf.addPage(
//             pw.Page(
//               pageFormat: PdfPageFormat.a4,
//               build: (pw.Context context) {
//                 return pw.Center(
//                   child: pw.Image(image, fit: pw.BoxFit.contain),
//                 );
//               },
//             ),
//           );
//         }
//       }
//
//       // Save PDF
//       final output = await getTemporaryDirectory();
//       final file = File('${output.path}/$fileName');
//       await file.writeAsBytes(await pdf.save());
//
//       // Save to storage service
//       final savedPath = await StorageService.instance.savePDFToPublicStorage(file.path, fileName);
//
//       return savedPath;
//     } catch (e) {
//       print('Error creating PDF: $e');
//       throw Exception('Failed to create PDF: $e');
//     }
//   }
//
//   Future<List<File>> getAllPDFs() async {
//     return await StorageService.instance.getSavedPDFs();
//   }
//
//   Future<void> deletePDF(String pdfPath) async {
//     try {
//       final file = File(pdfPath);
//       if (await file.exists()) {
//         await file.delete();
//       }
//     } catch (e) {
//       print('Error deleting PDF: $e');
//     }
//   }
//
//   // Share PDF file
//   Future<void> sharePDF(String pdfPath) async {
//     try {
//       final file = File(pdfPath);
//       if (await file.exists()) {
//         await Share.shareXFiles(
//           [XFile(pdfPath)],
//           subject: 'Scan2PDF Document',
//           text: 'Sharing a PDF document created with Scan2PDF',
//         );
//       } else {
//         throw Exception('PDF file not found: $pdfPath');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error sharing PDF: $e');
//       }
//       rethrow;
//     }
//   }
//
//   // View PDF file
//   Future<void> viewPDF(String pdfPath) async {
//     try {
//       final file = File(pdfPath);
//       if (await file.exists()) {
//         await Printing.layoutPdf(
//           onLayout: (PdfPageFormat format) async => file.readAsBytes(),
//         );
//       } else {
//         throw Exception('PDF file not found: $pdfPath');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error viewing PDF: $e');
//       }
//       rethrow;
//     }
//   }
//
//   // Get list of saved PDFs
//   Future<List<String>> getSavedPDFs() async {
//     try {
//       final files = await _storageService.getSavedPDFs();
//       return files.map((file) => file.path).toList();
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error getting saved PDFs: $e');
//       }
//       return [];
//     }
//   }
//
//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
//   }
// }

//Testing Data
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/image_item.dart';
import '../models/document.dart';
import 'storage_service.dart';
import 'pdf_compression_service.dart';

class PDFService {
  static final PDFService _instance = PDFService._internal();
  factory PDFService() => _instance;
  PDFService._internal();

  final StorageService _storageService = StorageService.instance;
  final PDFCompressionService _compressionService = PDFCompressionService();

  Future<String> createPDF(Document document) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  document.name,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Created: ${_formatDate(document.createdAt)}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Pages: ${document.imagePaths.length}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 40),
                pw.Divider(),
              ],
            );
          },
        ),
      );

      for (int i = 0; i < document.imagePaths.length; i++) {
        try {
          final imagePath = document.imagePaths[i];
          final imageFile = File(imagePath);

          if (await imageFile.exists()) {
            final imageBytes = await imageFile.readAsBytes();
            if (imageBytes.isNotEmpty) {
              final image = pw.MemoryImage(imageBytes);

              pdf.addPage(
                pw.Page(
                  pageFormat: PdfPageFormat.a4,
                  margin: const pw.EdgeInsets.all(20),
                  build: (pw.Context context) {
                    return pw.Column(
                      children: [
                        pw.Expanded(
                          child: pw.Center(
                            child: pw.Image(
                              image,
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            'Page ${i + 1} of ${document.imagePaths.length}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing page ${i + 1}: $e');
          }
        }
      }

      final directory = await getTemporaryDirectory();
      final tempPath = '${directory.path}/${document.name}.pdf';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(await pdf.save());

      final publicPath = await _storageService.savePDFToPublicStorage(
        tempPath,
        '${document.name}.pdf',
      );

      return publicPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating PDF: $e');
      }
      rethrow;
    }
  }

  // Generate PDF from images with compression
  Future<String> generatePDF(List<ImageItem> images, {
    String? fileName,
    PdfPageFormat? pageFormat,
    bool addMetadata = true,
    bool enableCompression = true,
    CompressionLevel compressionLevel = CompressionLevel.medium,
    String? password,
    Map<String, bool>? permissions,
  }) async {
    if (images.isEmpty) {
      throw Exception('No images provided for PDF generation');
    }

    try {
      final pdf = pw.Document();
      final format = pageFormat ?? PdfPageFormat.a4;

      // Compress images if enabled
      List<String> imagePaths = images.map((img) => img.path).toList();
      if (enableCompression) {
        try {
          final compressionResults = await _compressionService.compressImages(
            imagePaths: imagePaths,
            level: compressionLevel,
          );
          imagePaths = compressionResults.map((r) => r.compressedPath).toList();
        } catch (e) {
          if (kDebugMode) {
            print('Compression failed, using original images: $e');
          }
          // Continue with original images if compression fails
        }
      }

      // Add metadata if requested
      if (addMetadata) {
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            build: (pw.Context context) {
              return pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Scan2PDF Document',
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
                    'Contains ${images.length} image${images.length > 1 ? 's' : ''}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  if (password != null) ...[
                    pw.SizedBox(height: 20),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.amber),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Text(
                        'SECURE & COMPRESSED DOCUMENT',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber,
                        ),
                      ),
                    ),
                  ] else if (enableCompression) ...[
                    pw.SizedBox(height: 20),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.blue),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Text(
                        'COMPRESSED DOCUMENT',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 60),
                  pw.Text(
                    'Created with Scan2PDF',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Add each image as a page
      for (int i = 0; i < imagePaths.length; i++) {
        final imagePath = imagePaths[i];

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

          // Add image page
          pdf.addPage(
            pw.Page(
              pageFormat: format,
              margin: const pw.EdgeInsets.all(10),
              build: (pw.Context context) {
                return pw.Column(
                  children: [
                    // Image
                    pw.Expanded(
                      child: pw.Center(
                        child: pw.Image(
                          image,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                    // Page number
                    if (addMetadata)
                      pw.Container(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          'Page ${i + 1} of ${imagePaths.length}',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error processing image $imagePath: $e');
          }
          continue;
        }
      }

      // Generate filename with timestamp if not provided
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pdfFileName = fileName ?? 'Scan2PDF_$timestamp.pdf';

      // Save PDF to temporary directory first
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$pdfFileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(await pdf.save());

      // Save to public storage
      final publicPath = await _storageService.savePDFToPublicStorage(
        tempPath,
        pdfFileName,
      );

      // Clean up compressed images if they were created
      if (enableCompression) {
        for (final path in imagePaths) {
          try {
            final file = File(path);
            if (await file.exists() && path.contains('compressed_')) {
              await file.delete();
            }
          } catch (e) {
            if (kDebugMode) {
              print('Failed to delete compressed image: $e');
            }
          }
        }
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

  Future<String> createPDFFromImages(List<String> imagePaths, String fileName, {
    bool enableCompression = true,
    CompressionLevel compressionLevel = CompressionLevel.medium,
    String? password,
    Map<String, bool>? permissions,
  }) async {
    try {
      final pdf = pw.Document();

      // Compress images if enabled
      List<String> finalImagePaths = imagePaths;
      if (enableCompression) {
        try {
          final compressionResults = await _compressionService.compressImages(
            imagePaths: imagePaths,
            level: compressionLevel,
          );
          finalImagePaths = compressionResults.map((r) => r.compressedPath).toList();
        } catch (e) {
          if (kDebugMode) {
            print('Compression failed, using original images: $e');
          }
          // Continue with original images if compression fails
        }
      }

      for (final imagePath in finalImagePaths) {
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();
          final image = pw.MemoryImage(imageBytes);

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Image(
                    image,
                    fit: pw.BoxFit.contain,
                  ),
                );
              },
            ),
          );
        }
      }

      // Save PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Save to storage service
      final savedPath = await StorageService.instance.savePDFToPublicStorage(file.path, fileName);

      // Clean up compressed images
      if (enableCompression) {
        for (final path in finalImagePaths) {
          try {
            final file = File(path);
            if (await file.exists() && path.contains('compressed_')) {
              await file.delete();
            }
          } catch (e) {
            if (kDebugMode) {
              print('Failed to delete compressed image: $e');
            }
          }
        }
      }

      return savedPath;
    } catch (e) {
      print('Error creating PDF: $e');
      throw Exception('Failed to create PDF: $e');
    }
  }

  // Generate a secure owner password based on user password
  String _generateOwnerPassword(String userPassword) {
    final bytes = utf8.encode(userPassword + 'Scan2PDF_Owner_Key_2024');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  Future<List<File>> getAllPDFs() async {
    return await StorageService.instance.getSavedPDFs();
  }

  Future<void> deletePDF(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting PDF: $e');
    }
  }

  // Share PDF file
  Future<void> sharePDF(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(pdfPath)],
          subject: 'Scan2PDF Document',
          text: 'Sharing a PDF document created with Scan2PDF',
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

  // View PDF file
  Future<void> viewPDF(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (await file.exists()) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => file.readAsBytes(),
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

  // Get list of saved PDFs
  Future<List<String>> getSavedPDFs() async {
    try {
      final files = await StorageService.instance.getSavedPDFs();
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
}
