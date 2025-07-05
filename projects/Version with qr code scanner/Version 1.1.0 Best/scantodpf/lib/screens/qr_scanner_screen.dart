import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with TickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  String? scannedCode;
  bool isFlashOn = false;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scanLineAnimation;
  late Animation<double> _cornerAnimation;
  late Animation<double> _pulseAnimation;
  bool _isScanning = true;
  bool _isProcessing = false;
  double _frameSize = 250.0; // Default frame size
  final double _minFrameSize = 150.0;
  final double _maxFrameSize = 300.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _cornerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _adjustFrameSize(Size screenSize) {
    // Gradually adjust frame size based on scanning success
    double newFrameSize = _frameSize;
    if (_isProcessing) {
      newFrameSize = _frameSize * 0.95; // Slightly decrease size when processing
    } else {
      newFrameSize = _frameSize * 1.05; // Slightly increase size when scanning
    }
    newFrameSize = newFrameSize.clamp(_minFrameSize, _maxFrameSize);

    if ((newFrameSize - _frameSize).abs() > 5) { // Only update if change is significant
      setState(() {
        _frameSize = newFrameSize;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              setState(() {
                isFlashOn = !isFlashOn;
                controller.toggleTorch();
              });
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.switch_camera, color: Colors.white),
            ),
            onPressed: () => controller.switchCamera(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (!_isScanning || _isProcessing) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                setState(() {
                  scannedCode = barcode.rawValue;
                  _isScanning = false;
                  _isProcessing = true;
                });
                _adjustFrameSize(screenSize);
                _showScanResult(barcode.rawValue ?? 'Unknown');
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                      _isScanning = true;
                    });
                    _adjustFrameSize(screenSize);
                  }
                });
              }
            },
          ),
          // Overlay with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
          // Scanner Frame
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: _frameSize,
                    height: _frameSize,
                    child: Stack(
                      children: [
                        // Scanner Frame
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        // Corner Decorations with Animation
                        ..._buildAnimatedCornerDecorations(),
                        // Scanning Line
                        AnimatedBuilder(
                          animation: _scanLineAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: _scanLineAnimation.value * _frameSize,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Theme.of(context).primaryColor.withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Processing Indicator
                        if (_isProcessing)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Bottom UI Elements
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Instructions
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 0.95 + (_pulseAnimation.value * 0.05),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white.withOpacity(0.8),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Position the QR code within the frame',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Success Message
                if (scannedCode != null)
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.95 + (_pulseAnimation.value * 0.05),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.8),
                                Colors.green.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              const Text(
                                'QR Code Detected!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnimatedCornerDecorations() {
    const double cornerSize = 20;
    const double cornerThickness = 3;
    const Color cornerColor = Colors.white;

    return [
      // Top Left
      Positioned(
        top: 0,
        left: 0,
        child: AnimatedBuilder(
          animation: _cornerAnimation,
          builder: (context, child) {
            return Row(
              children: [
                Container(
                  width: cornerSize,
                  height: cornerThickness,
                  color: cornerColor.withOpacity(0.8 + (_cornerAnimation.value * 0.2)),
                ),
                Container(
                  width: cornerThickness,
                  height: cornerSize,
                  color: cornerColor.withOpacity(0.8 + (_cornerAnimation.value * 0.2)),
                ),
              ],
            );
          },
        ),
      ),
      // Top Right
      Positioned(
        top: 0,
        right: 0,
        child: AnimatedBuilder(
          animation: _cornerAnimation,
          builder: (context, child) {
            return Row(
              children: [
                Container(
                  width: cornerThickness,
                  height: cornerSize,
                  color: cornerColor.withOpacity(0.8 + (_cornerAnimation.value * 0.2)),
                ),
                Container(
                  width: cornerSize,
                  height: cornerThickness,
                  color: cornerColor.withOpacity(0.8 + (_cornerAnimation.value * 0.2)),
                ),
              ],
            );
          },
        ),
      ),
      // Bottom Left
      Positioned(
        bottom: 0,
        left: 0,
        child: AnimatedBuilder(
          animation: _cornerAnimation,
          builder: (context, child) {
            return Row(
              children: [
                Container(
                  width: cornerThickness,
                  height: cornerSize,
                  color: cornerColor.withOpacity(0.8 + (_cornerAnimation.value * 0.2)),
                ),
                Container(
                  width: cornerSize,
                  height: cornerThickness,
                  color: cornerColor.withOpacity(0.8 + (_cornerAnimation.value * 0.2)),
                ),
              ],
            );
          },
        ),
      ),
      // Bottom Right
      Positioned(
        bottom: 0,
        right: 0,
        child: AnimatedBuilder(
          animation: _cornerAnimation,
          builder: (context, child) {
            return Row(
              children: [
                Container(
                  width: cornerSize,
                  height: cornerThickness,
                  color: cornerColor.withOpacity(0.8 + (_cornerAnimation.value * 0.2)),
                ),
                Container(
                  width: cornerThickness,
                  height: cornerSize,
                  color: cornerColor.withOpacity(0.8 + (_cornerAnimation.value * 0.2)),
                ),
              ],
            );
          },
        ),
      ),
    ];
  }

  void _showScanResult(String result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.qr_code, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Scanned: $result',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Copy',
          textColor: Theme.of(context).primaryColor,
          onPressed: () {
            // TODO: Implement copy functionality
          },
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    controller.dispose();
    super.dispose();
  }
} 