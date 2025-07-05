import 'package:flutter/material.dart';
import 'dart:io';
import '../services/enhanced_pdf_service.dart';
import '../models/document.dart';
import '../widgets/watermark_dialog.dart';

class PDFMergeScreen extends StatefulWidget {
  final Document? initialDocument;

  const PDFMergeScreen({super.key, this.initialDocument});

  @override
  State<PDFMergeScreen> createState() => _PDFMergeScreenState();
}

class _PDFMergeScreenState extends State<PDFMergeScreen> {
  final EnhancedPDFService _pdfService = EnhancedPDFService();
  List<String> _selectedPDFs = [];
  bool _isLoading = false;
  bool _isMerging = false;
  String _outputFileName = '';
  String? _watermarkText;

  @override
  void initState() {
    super.initState();
    if (widget.initialDocument?.pdfPath != null) {
      _selectedPDFs.add(widget.initialDocument!.pdfPath!);
    }
    _outputFileName = 'Merged_PDF_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _pickPDFFiles() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get existing documents from the PDF service
      final documents = await _pdfService.getAllDocuments();

      if (documents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No documents available. Create some PDFs first.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show dialog to select documents
      final selectedDocs = await showDialog<List<Document>>(
        context: context,
        builder: (context) => _DocumentSelectionDialog(
          documents: documents,
          alreadySelected: _selectedPDFs,
        ),
      );

      if (selectedDocs != null) {
        setState(() {
          for (final doc in selectedDocs) {
            if (doc.pdfPath != null && !_selectedPDFs.contains(doc.pdfPath!)) {
              _selectedPDFs.add(doc.pdfPath!);
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading documents: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _mergePDFs() async {
    if (_selectedPDFs.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 PDF files to merge'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isMerging = true;
    });

    try {
      final outputPath = await _pdfService.mergePDFs(
        pdfPaths: _selectedPDFs,
        outputFileName: '$_outputFileName.pdf',
        watermarkText: _watermarkText,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('PDFs merged successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/pdf-list');
              },
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error merging PDFs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isMerging = false;
      });
    }
  }

  void _removePDF(int index) {
    setState(() {
      _selectedPDFs.removeAt(index);
    });
  }

  void _showWatermarkDialog() {
    showDialog(
      context: context,
      builder: (context) => WatermarkDialog(
        initialText: _watermarkText,
        onWatermarkSet: (watermark) {
          setState(() {
            _watermarkText = watermark;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Merge PDFs',
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
      ),
      body: Column(
        children: [
          // Header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E88E5).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.merge_type,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Merge PDF Files',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedPDFs.length} PDFs selected',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Options
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Output Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Output File Name',
                    border: OutlineInputBorder(),
                    suffixText: '.pdf',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _outputFileName = value.isNotEmpty ? value : 'Merged_PDF_${DateTime.now().millisecondsSinceEpoch}';
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showWatermarkDialog,
                        icon: const Icon(Icons.water_drop),
                        label: Text(_watermarkText?.isEmpty ?? true
                            ? 'Add Watermark'
                            : 'Watermark: $_watermarkText'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // PDF List
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Selected PDFs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _pickPDFFiles,
                          icon: _isLoading
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.add),
                          label: const Text('Add PDFs'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _selectedPDFs.isEmpty
                        ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No PDFs selected',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap "Add PDFs" to select files',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _selectedPDFs.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = _selectedPDFs.removeAt(oldIndex);
                          _selectedPDFs.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final pdfPath = _selectedPDFs[index];
                        final fileName = pdfPath.split('/').last;

                        return Card(
                          key: ValueKey(pdfPath),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                              ),
                            ),
                            title: Text(
                              fileName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('Position: ${index + 1}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.drag_handle),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _removePDF(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Merge Button
          if (_selectedPDFs.length >= 2)
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isMerging ? null : _mergePDFs,
                  icon: _isMerging
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.merge_type),
                  label: Text(_isMerging ? 'Merging PDFs...' : 'Merge PDFs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocumentSelectionDialog extends StatefulWidget {
  final List<Document> documents;
  final List<String> alreadySelected;

  const _DocumentSelectionDialog({
    required this.documents,
    required this.alreadySelected,
  });

  @override
  State<_DocumentSelectionDialog> createState() => _DocumentSelectionDialogState();
}

class _DocumentSelectionDialogState extends State<_DocumentSelectionDialog> {
  final Set<Document> _selectedDocuments = {};

  @override
  Widget build(BuildContext context) {
    final availableDocuments = widget.documents
        .where((doc) => doc.pdfPath != null && !widget.alreadySelected.contains(doc.pdfPath!))
        .toList();

    return AlertDialog(
      title: const Text('Select Documents to Merge'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: availableDocuments.isEmpty
            ? const Center(
          child: Text('No additional documents available'),
        )
            : ListView.builder(
          itemCount: availableDocuments.length,
          itemBuilder: (context, index) {
            final document = availableDocuments[index];
            final isSelected = _selectedDocuments.contains(document);

            return CheckboxListTile(
              value: isSelected,
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedDocuments.add(document);
                  } else {
                    _selectedDocuments.remove(document);
                  }
                });
              },
              title: Text(document.name),
              subtitle: Text('${document.pageCount} pages'),
              secondary: const Icon(Icons.picture_as_pdf, color: Colors.red),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedDocuments.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selectedDocuments.toList()),
          child: Text('Select (${_selectedDocuments.length})'),
        ),
      ],
    );
  }
}
