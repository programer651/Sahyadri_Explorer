import 'package:flutter/foundation.dart';

class NavigationStateManager {
  // Singleton Pattern
  static final NavigationStateManager _instance = NavigationStateManager._internal();
  factory NavigationStateManager() => _instance;
  NavigationStateManager._internal();

  // ValueNotifier to hold current tab index
  // 0: Map, 1: Bookmarks, 2: Profile
  final ValueNotifier<int> selectedIndex = ValueNotifier<int>(0);

  void navigateToMap() {
    selectedIndex.value = 0;
  }

  void navigateToProfile() {
    selectedIndex.value = 2;
  }
}
