import 'package:flutter/material.dart';
import '../services/enhanced_pdf_service.dart';

class PDFGenerationDialog extends StatefulWidget {
  final List<String> imagePaths;
  final VoidCallback? onPDFGenerated;

  const PDFGenerationDialog({
    super.key,
    required this.imagePaths,
    this.onPDFGenerated,
  });

  @override
  State<PDFGenerationDialog> createState() => _PDFGenerationDialogState();
}

class _PDFGenerationDialogState extends State<PDFGenerationDialog> {
  final TextEditingController _fileNameController = TextEditingController();
  final TextEditingController _watermarkController = TextEditingController();
  bool _isGenerating = false;
  bool _addMetadata = true;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _fileNameController.text = 'Scan2PDF_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _watermarkController.dispose();
    super.dispose();
  }

  Future<void> _generatePDF() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _progress = 0.0;
    });

    try {
      final pdfService = EnhancedPDFService();

      final fileName = _fileNameController.text.trim().isEmpty
          ? 'Scan2PDF_${DateTime.now().millisecondsSinceEpoch}'
          : _fileNameController.text.trim();

      final watermark = _watermarkController.text.trim().isEmpty
          ? null
          : _watermarkController.text.trim();

      // Simulate progress updates
      for (int i = 0; i <= 100; i += 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _progress = i / 100;
          });
        }
      }

      final pdfPath = await pdfService.createPDFFromImages(
        imagePaths: widget.imagePaths,
        fileName: fileName.endsWith('.pdf') ? fileName : '$fileName.pdf',
        watermarkText: watermark,
        addMetadata: _addMetadata,
        saveToDownloads: true,
      );

      if (mounted) {
        setState(() {
          _progress = 1.0;
        });

        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.of(context).pop(pdfPath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF created: ${fileName.replaceAll('.pdf', '')}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/pdf-list');
              },
            ),
          ),
        );

        // Call the callback if provided
        widget.onPDFGenerated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _progress = 0.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'Generate PDF',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creating PDF from ${widget.imagePaths.length} image${widget.imagePaths.length > 1 ? 's' : ''}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            // File name input
            TextField(
              controller: _fileNameController,
              enabled: !_isGenerating,
              decoration: const InputDecoration(
                labelText: 'File Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),

            // Watermark input
            TextField(
              controller: _watermarkController,
              enabled: !_isGenerating,
              decoration: const InputDecoration(
                labelText: 'Watermark (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.water),
                hintText: 'Enter watermark text',
              ),
            ),
            const SizedBox(height: 16),

            // Add metadata checkbox
            CheckboxListTile(
              title: const Text('Add metadata page'),
              subtitle: const Text('Include document information'),
              value: _addMetadata,
              onChanged: _isGenerating ? null : (value) {
                setState(() {
                  _addMetadata = value ?? true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            // Progress indicator
            if (_isGenerating) ...[
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.hourglass_empty, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Generating PDF...',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isGenerating ? null : _generatePDF,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isGenerating
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Text('Generate PDF'),
        ),
      ],
    );
  }
}


