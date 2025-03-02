import 'package:flutter/material.dart';

class AppConstants {
  // App name
  static const String appName = 'Billable';
  
  // Routes
  static const String homeRoute = '/';
  static const String newEntryRoute = '/new-entry';
  static const String editEntryRoute = '/edit-entry';
  static const String exportRoute = '/export';
  static const String statisticsRoute = '/statistics';
  static const String settingsRoute = '/settings';

  // Colors
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color accentColor = Color(0xFF26C6DA);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color successColor = Color(0xFF66BB6A);
  static const Color warningColor = Color(0xFFFFCA28);
  static const Color errorColor = Color(0xFFEF5350);
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16.0,
    color: textPrimaryColor,
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontSize: 14.0,
    color: textSecondaryColor,
  );

  // Form Field Decorations
  static InputDecoration inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      // Float labels to avoid dark mode overlap issues
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2.0),
      ),
      filled: true,
      // Using null for fillColor to respect theme colors (light/dark)
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      // Better label styling for visibility in both themes
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);

  // Spacing values
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
  
  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    side: const BorderSide(color: primaryColor),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
