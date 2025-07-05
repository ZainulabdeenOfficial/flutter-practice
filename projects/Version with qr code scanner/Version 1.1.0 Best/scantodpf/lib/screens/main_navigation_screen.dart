import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/simple_app_drawer.dart';
import '../widgets/simple_bottom_nav_bar.dart';
import 'home_screen.dart' as home;
import 'camera_screen.dart';
import 'pdf_list_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(navigationProvider.currentTitle),
            actions: [
              if (navigationProvider.currentIndex == 0)
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {

                  },
                ),
            ],
          ),
          drawer: const SimpleAppDrawer(),
          body: IndexedStack(
            index: navigationProvider.currentIndex,
            children: [
              const home.HomeScreen(),
              const CameraScreen(),
              const PDFListScreen(),
            ],
          ),
          bottomNavigationBar: const SimpleBottomNavBar(),
          floatingActionButton: navigationProvider.currentIndex == 1
              ? FloatingActionButton(
            onPressed: () {

            },
            child: const Icon(Icons.camera_alt),
          )
              : null,
        );
      },
    );
  }
}

