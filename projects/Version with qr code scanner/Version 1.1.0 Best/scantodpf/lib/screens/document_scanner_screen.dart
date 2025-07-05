import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../models/image_item.dart';
import '../models/document_page.dart';
import '../services/document_processing_service.dart';
import '../services/enhanced_pdf_service.dart';
import '../widgets/document_enhancement_dialog.dart';
import '../widgets/document_preview_widget.dart';

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isProcessing = false;
  List<DocumentPage> _scannedPages = [];
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFlashOn = false;
  final DocumentProcessingService _processingService = DocumentProcessingService();
  final EnhancedPDFService _pdfService = EnhancedPDFService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
      _showErrorSnackBar('Failed to initialize camera: $e');
    }
  }

  Future<void> _captureDocument() async {
    if (!_controller!.value.isInitialized || _isCapturing || _isProcessing) return;

    setState(() {
      _isCapturing = true;
    });

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    try {
      // Capture image
      final XFile image = await _controller!.takePicture();

      setState(() {
        _isCapturing = false;
        _isProcessing = true;
      });

      // Process the captured image
      await _processDocument(image.path);

    } catch (e) {
      setState(() {
        _isCapturing = false;
        _isProcessing = false;
      });
      _showErrorSnackBar('Error capturing document: $e');
    }
  }

  Future<void> _processDocument(String imagePath) async {
    try {
      // Auto-crop the document
      final croppedPath = await _processingService.autoCropDocument(imagePath);

      // Create document page
      final documentPage = DocumentPage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        originalPath: imagePath,
        processedPath: croppedPath,
        pageNumber: _scannedPages.length + 1,
        createdAt: DateTime.now(),
      );

      setState(() {
        _scannedPages.add(documentPage);
        _isProcessing = false;
      });

      // Show enhancement options
      _showEnhancementDialog(documentPage);

      _showSuccessSnackBar('Document page ${_scannedPages.length} captured and processed!');

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorSnackBar('Error processing document: $e');
    }
  }

  void _showEnhancementDialog(DocumentPage page) {
    showDialog(
      context: context,
      builder: (context) => DocumentEnhancementDialog(
        documentPage: page,
        onEnhancementApplied: (enhancedPage) {
          setState(() {
            final index = _scannedPages.indexWhere((p) => p.id == page.id);
            if (index != -1) {
              _scannedPages[index] = enhancedPage;
            }
          });
        },
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (_controller != null) {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      await _controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    }
  }

  Future<void> _exportToPDF() async {
    if (_scannedPages.isEmpty) {
      _showErrorSnackBar('Please scan at least one document page first');
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      // Convert DocumentPage list to Map list for PDF service
      final pagesMaps = _scannedPages.map((page) => page.toMap()).toList();

      final pdfPath = await _pdfService.createDocumentPDF(
        pages: pagesMaps,
        documentName: 'Document_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        _isProcessing = false;
      });

      _showSuccessSnackBar('PDF exported successfully!');

      // Show options to view or share
      _showPDFOptionsDialog(pdfPath);

    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorSnackBar('Error exporting PDF: $e');
    }
  }

  void _showPDFOptionsDialog(String pdfPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('PDF Created Successfully!'),
        content: const Text('What would you like to do with your document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pdfService.sharePDF(pdfPath);
            },
            child: const Text('Share'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pdfService.viewPDF(pdfPath);
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  void _removePage(int index) {
    setState(() {
      _scannedPages.removeAt(index);
    });
  }

  void _clearAllPages() {
    setState(() {
      _scannedPages.clear();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _scannedPages.isNotEmpty),
        ),
        title: const Text(
          'Document Scanner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_scannedPages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: _exportToPDF,
              tooltip: 'Export to PDF',
            ),
        ],
      ),
      body: _isInitialized
          ? Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // Document detection overlay
          Positioned.fill(
            child: CustomPaint(
              painter: DocumentOverlayPainter(),
            ),
          ),

          // Top controls
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flash toggle
                _buildControlButton(
                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  onPressed: _toggleFlash,
                ),

                // Page counter
                if (_scannedPages.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_scannedPages.length} page${_scannedPages.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Scanned pages preview
          if (_scannedPages.isNotEmpty)
            Positioned(
              bottom: 140,
              left: 16,
              right: 16,
              child: Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _scannedPages.length,
                  itemBuilder: (context, index) {
                    return DocumentPreviewWidget(
                      documentPage: _scannedPages[index],
                      onRemove: () => _removePage(index),
                      onTap: () => _showEnhancementDialog(_scannedPages[index]),
                    );
                  },
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Clear all button
                  if (_scannedPages.isNotEmpty)
                    _buildActionButton(
                      icon: Icons.clear_all,
                      label: 'Clear All',
                      color: Colors.red,
                      onTap: _clearAllPages,
                    ),

                  // Capture button
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: _buildCaptureButton(),
                      );
                    },
                  ),

                  // Export button
                  if (_scannedPages.isNotEmpty)
                    _buildActionButton(
                      icon: Icons.picture_as_pdf,
                      label: 'Export PDF',
                      color: Colors.green,
                      onTap: _exportToPDF,
                    ),
                ],
              ),
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Processing document...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      )
          : const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _captureDocument,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.blue, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _isCapturing
            ? const CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        )
            : const Icon(
          Icons.document_scanner,
          color: Colors.blue,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Document overlay painter for visual guidance
class DocumentOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.6,
    );

    // Draw corner guides
    final cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
