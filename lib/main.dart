import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/app_colors.dart';
import 'utils/app_text_styles.dart';
import 'screens/experience_selection_screen.dart';

void main() {
  runApp(
    // Wrap with ProviderScope to enable Riverpod
    const ProviderScope(
      child: HotspotApp(),
    ),
  );
}

class HotspotApp extends StatelessWidget {
  const HotspotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotspot',
      debugShowCheckedModeBanner: false,
      
      // Theme Configuration using YOUR color palette
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.white, // #FAFAFA
        primaryColor: AppColors.blue75, // #2F5BFF
        useMaterial3: true,
        
        // AppBar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.black100),
          titleTextStyle: AppTextStyles.heading3,
        ),
        
        // Text Theme
        textTheme: TextTheme(
          displayLarge: AppTextStyles.heading1,
          displayMedium: AppTextStyles.heading2,
          displaySmall: AppTextStyles.heading3,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          bodySmall: AppTextStyles.bodySmall,
        ),
        
        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gray25),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.gray25),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.blue75, width: 2),
          ),
          hintStyle: AppTextStyles.hint,
          contentPadding: const EdgeInsets.all(16),
        ),
        
        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue75, // #2F5BFF
            foregroundColor: AppColors.pureWhite,
            textStyle: AppTextStyles.button,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
      
      // Start with Experience Selection Screen
      home: const ExperienceSelectionScreen(),
    );
  }
}
