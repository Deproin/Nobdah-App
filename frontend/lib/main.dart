import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const NobdahApp(),
    ),
  );
}

class NobdahApp extends StatelessWidget {
  const NobdahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'نبضة - Nobdah',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme.copyWith(
            textTheme: GoogleFonts.outfitTextTheme(themeProvider.currentTheme.textTheme),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
