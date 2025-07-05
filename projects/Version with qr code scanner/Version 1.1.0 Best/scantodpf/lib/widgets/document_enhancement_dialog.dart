import 'package:flutter/material.dart';
import 'dart:io';
import '../models/document_page.dart';
import '../screens/document_scanner_screen.dart';
import '../services/document_processing_service.dart';

class DocumentEnhancementDialog extends StatefulWidget {
  final DocumentPage documentPage;
  final Function(DocumentPage) onEnhancementApplied;

  const DocumentEnhancementDialog({
    super.key,
    required this.documentPage,
    required this.onEnhancementApplied,
  });

  @override
  State<DocumentEnhancementDialog> createState() => _DocumentEnhancementDialogState();
}

class _DocumentEnhancementDialogState extends State<DocumentEnhancementDialog> {
  final DocumentProcessingService _processingService = DocumentProcessingService();
  String _currentImagePath = '';
  String _selectedFilter = 'original';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.documentPage.processedPath;
  }

  Future<void> _applyFilter(String filterType) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _selectedFilter = filterType;
    });

    try {
      String enhancedPath;
      
      switch (filterType) {
        case 'grayscale':
          enhancedPath = await _processingService.applyGrayscaleFilter(widget.documentPage.processedPath);
          break;
        case 'magic':
          enhancedPath = await _processingService.applyMagicFilter(widget.documentPage.processedPath);
          break;
        case 'blackwhite':
          enhancedPath = await _processingService.applyBlackWhiteFilter(widget.documentPage.processedPath);
          break;
        case 'color':
          enhancedPath = await _processingService.applyColorFilter(widget.documentPage.processedPath);
          break;
        default:
          enhancedPath = widget.documentPage.processedPath;
      }

      setState(() {
        _currentImagePath = enhancedPath;
        _isProcessing = false;
      });

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error applying filter: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveEnhancement() {
    final enhancedPage = widget.documentPage.copyWith(
      enhancedPath: _selectedFilter != 'original' ? _currentImagePath : null,
      filterType: _selectedFilter,
    );
    
    widget.onEnhancementApplied(enhancedPage);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Enhance Document',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Image preview
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _isProcessing
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Applying filter...'),
                            ],
                          ),
                        )
                      : Image.file(
                          File(_currentImagePath),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.error, size: 50, color: Colors.grey),
                            );
                          },
                        ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Filter options
            const Text(
              'Enhancement Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Expanded(
              flex: 1,
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3,
                children: [
                  _buildFilterButton(
                    'Original',
                    'original',
                    Icons.image,
                    Colors.grey,
                  ),
                  _buildFilterButton(
                    'Grayscale',
                    'grayscale',
                    Icons.filter_b_and_w,
                    Colors.blueGrey,
                  ),
                  _buildFilterButton(
                    'Magic Filter',
                    'magic',
                    Icons.auto_fix_high,
                    Colors.purple,
                  ),
                  _buildFilterButton(
                    'Black & White',
                    'blackwhite',
                    Icons.contrast,
                    Colors.black,
                  ),
                  _buildFilterButton(
                    'Color Enhance',
                    'color',
                    Icons.palette,
                    Colors.orange,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveEnhancement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String filterType, IconData icon, Color color) {
    final isSelected = _selectedFilter == filterType;
    
    return GestureDetector(
      onTap: () => _applyFilter(filterType),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
