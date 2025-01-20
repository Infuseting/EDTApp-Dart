import 'package:flutter/material.dart';
import 'cacheManager.dart';

class ThemeManager {
  Future<Color> getPrimaryColor() async {
    bool isDarkMode = (await CacheHelper.isDarkModeEnabled()) ?? false;
    return isDarkMode
        ? const Color.fromRGBO(2, 22, 39, 1)
        : const Color.fromRGBO(242, 239, 234, 1);
  }

  Future<Color> getSecondaryColor() async {
    bool isDarkMode = (await CacheHelper.isDarkModeEnabled()) ?? false;
    return isDarkMode
        ? const Color.fromRGBO(242, 239, 234, 1)
        : const Color.fromRGBO(2, 22, 39, 1);
  }
}
