import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';

class SimpleAppDrawer extends StatelessWidget {
  const SimpleAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.document_scanner,
                    size: 30,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Scan2PDF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Document Scanner',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Consumer<NavigationProvider>(
                  builder: (context, navigationProvider, child) {
                    return Column(
                      children: [
                        _buildDrawerItem(
                          context,
                          icon: Icons.home,
                          title: 'Home',
                          isSelected: navigationProvider.currentIndex == 0,
                          onTap: () {
                            navigationProvider.setCurrentIndex(0);
                            Navigator.pop(context);
                          },
                        ),
                        _buildDrawerItem(
                          context,
                          icon: Icons.camera_alt,
                          title: 'Camera',
                          isSelected: navigationProvider.currentIndex == 1,
                          onTap: () {
                            navigationProvider.setCurrentIndex(1);
                            // Navigator.pop(context);
                            // Navigator.pushNamed(context, '/main');
                            // Navigator.pushNamedAndRemoveUntil(context, '/camera', (route) => false);
                            //Navigator.pushReplacementNamed(context, '/camera');
                            // Provider.of<NavigationProvider>(context, listen: false).setCurrentIndex(1);
                            Navigator.pop(context); // Close drawer if needed
                            Navigator.pushReplacementNamed(context, '/camera');


                          },
                        ),
                        _buildDrawerItem(
                          context,
                          icon: Icons.picture_as_pdf,
                          title: 'PDFs',
                          isSelected: navigationProvider.currentIndex == 2,
                          onTap: () {
                            navigationProvider.setCurrentIndex(2);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    );
                  },
                ),
                
                const Divider(),
                
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.help,
                  title: 'Help',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/help');
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.info,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/about');
                  },
                ),
                
                const Divider(),
                
                // Theme toggle
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return SwitchListTile(
                      title: const Text('Dark Mode'),
                      secondary: Icon(
                        themeProvider.isDarkMode
                            ? Icons.dark_mode
                            : Icons.light_mode,
                      ),
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
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

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
}
