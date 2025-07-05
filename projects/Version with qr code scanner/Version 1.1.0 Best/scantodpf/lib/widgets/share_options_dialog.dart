import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class ShareOptionsDialog extends StatelessWidget {
  final String pdfPath;
  final String fileName;

  const ShareOptionsDialog({
    super.key,
    required this.pdfPath,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.share,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Share Document',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fileName,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildShareOption(
                  context,
                  icon: Icons.email,
                  label: 'Email',
                  color: Colors.red,
                  onTap: () => _shareViaEmail(),
                ),
                _buildShareOption(
                  context,
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: Colors.green,
                  onTap: () => _shareViaWhatsApp(),
                ),
                _buildShareOption(
                  context,
                  icon: Icons.cloud_upload,
                  label: 'Drive',
                  color: Colors.blue,
                  onTap: () => _shareViaGoogleDrive(),
                ),
                _buildShareOption(
                  context,
                  icon: Icons.share,
                  label: 'More',
                  color: Colors.grey,
                  onTap: () => _shareGeneral(),
                ),
                _buildShareOption(
                  context,
                  icon: Icons.link,
                  label: 'Copy Link',
                  color: Colors.orange,
                  onTap: () => _copyLink(context),
                ),
                _buildShareOption(
                  context,
                  icon: Icons.print,
                  label: 'Print',
                  color: Colors.purple,
                  onTap: () => _printDocument(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareViaEmail() async {
    try {
      // Since we can't use url_launcher, we'll use the general share functionality
      await Share.shareXFiles(
        [XFile(pdfPath)],
        subject: 'Document: $fileName',
        text: 'Please find the attached PDF document.',
      );
    } catch (e) {
      print('Error sharing via email: $e');
    }
  }

  Future<void> _shareViaWhatsApp() async {
    try {
      await Share.shareXFiles(
        [XFile(pdfPath)],
        subject: 'Document: $fileName',
        text: 'Sharing PDF document: $fileName',
      );
    } catch (e) {
      print('Error sharing via WhatsApp: $e');
    }
  }

  Future<void> _shareViaGoogleDrive() async {
    try {
      // For Google Drive integration, you would typically use Google Drive API
      // For now, we'll use the general share functionality
      await Share.shareXFiles(
        [XFile(pdfPath)],
        subject: 'Upload to Google Drive: $fileName',
        text: 'Document: $fileName',
      );
    } catch (e) {
      print('Error sharing to Google Drive: $e');
    }
  }

  Future<void> _shareGeneral() async {
    try {
      await Share.shareXFiles(
        [XFile(pdfPath)],
        subject: 'Document: $fileName',
        text: 'Sharing PDF document created with Scan2PDF Pro',
      );
    } catch (e) {
      print('Error sharing document: $e');
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    // In a real implementation, you might upload to cloud storage and get a link
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link functionality coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _printDocument() async {
    try {
      // Print functionality would be implemented here
      // For now, show a placeholder message
      print('Print document: $pdfPath');
    } catch (e) {
      print('Error printing document: $e');
    }
  }
}

