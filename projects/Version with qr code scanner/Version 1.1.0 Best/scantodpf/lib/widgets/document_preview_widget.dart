import 'package:flutter/material.dart';
import 'dart:io';
import '../models/document_page.dart';
import '../screens/document_scanner_screen.dart';

class DocumentPreviewWidget extends StatelessWidget {
  final DocumentPage documentPage;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const DocumentPreviewWidget({
    super.key,
    required this.documentPage,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          // Image preview
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(documentPage.finalPath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.error,
                              color: Colors.grey,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Remove button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                  
                  // Filter indicator
                  if (documentPage.filterType != null && documentPage.filterType != 'original')
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getFilterLabel(documentPage.filterType!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Page number
          Text(
            'Page ${documentPage.pageNumber}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(String filterType) {
    switch (filterType) {
      case 'grayscale':
        return 'GRAY';
      case 'magic':
        return 'MAGIC';
      case 'blackwhite':
        return 'B&W';
      case 'color':
        return 'COLOR';
      default:
        return 'ORIG';
    }
  }
}
