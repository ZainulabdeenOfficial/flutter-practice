import 'package:flutter/material.dart';

class WatermarkDialog extends StatefulWidget {
  final String? initialText;
  final Function(String?) onWatermarkSet;

  const WatermarkDialog({
    super.key,
    this.initialText,
    required this.onWatermarkSet,
  });

  @override
  State<WatermarkDialog> createState() => _WatermarkDialogState();
}

class _WatermarkDialogState extends State<WatermarkDialog> {
  late TextEditingController _controller;
  bool _enableWatermark = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _enableWatermark = widget.initialText?.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Watermark Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            SwitchListTile(
              title: const Text('Enable Watermark'),
              subtitle: const Text('Add text watermark to PDF pages'),
              value: _enableWatermark,
              onChanged: (value) {
                setState(() {
                  _enableWatermark = value;
                  if (!value) {
                    _controller.clear();
                  }
                });
              },
            ),
            
            if (_enableWatermark) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Watermark Text',
                  hintText: 'Enter watermark text',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.text_fields),
                ),
                maxLength: 50,
              ),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Text(
                              'PDF Content',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Transform.rotate(
                                angle: -0.3,
                                child: Opacity(
                                  opacity: 0.3,
                                  child: Text(
                                    _controller.text,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final watermarkText = _enableWatermark && _controller.text.isNotEmpty
                        ? _controller.text
                        : null;
                    widget.onWatermarkSet(watermarkText);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
