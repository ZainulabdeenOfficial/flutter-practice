import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // FAQ Section
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Frequently Asked Questions'),
              children: [
                _buildFAQItem(
                  'How do I scan a document?',
                  'Tap the camera icon on the home screen or go to the Scanner tab. Point your camera at the document and tap the capture button.',
                ),
                _buildFAQItem(
                  'How do I create a PDF?',
                  'After scanning images, tap the "Create PDF" button. You can combine multiple images into a single PDF document.',
                ),
                _buildFAQItem(
                  'Where are my files saved?',
                  'All scanned documents and PDFs are saved locally on your device in the app\'s secure storage.',
                ),
                _buildFAQItem(
                  'Can I edit scanned images?',
                  'Yes, you can enhance and edit your scanned images using the built-in editing tools.',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Getting Started
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Getting Started'),
              children: [
                _buildHelpItem(
                  Icons.camera_alt,
                  'Scanning Documents',
                  'Use the camera to capture documents. The app will automatically detect edges and enhance the image quality.',
                ),
                _buildHelpItem(
                  Icons.picture_as_pdf,
                  'Creating PDFs',
                  'Combine multiple scanned images into a single PDF document for easy sharing and storage.',
                ),
                _buildHelpItem(
                  Icons.folder,
                  'Managing Files',
                  'View, organize, and manage all your scanned documents and PDFs in one place.',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tips & Tricks
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('Tips & Tricks'),
              children: [
                _buildTipItem(
                  'For best results, scan documents in good lighting conditions.',
                ),
                _buildTipItem(
                  'Hold your device steady and parallel to the document.',
                ),
                _buildTipItem(
                  'Use the auto-enhancement feature for clearer text.',
                ),
                _buildTipItem(
                  'Organize your documents with descriptive names.',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Contact Support
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.support_agent),
                      const SizedBox(width: 12),
                      Text(
                        'Contact Support',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Need more help? We\'re here to assist you!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contact support feature coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.email),
                      label: const Text('Send Feedback'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
