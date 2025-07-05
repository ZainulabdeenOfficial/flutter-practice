import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  String get currentTitle {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Camera';
      case 2:
        return 'PDFs';
      default:
        return 'Scan2PDF';
    }
  }
}
