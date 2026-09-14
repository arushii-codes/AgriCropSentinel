import 'package:farmer_app/screens/homepage.dart';
import 'package:farmer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

const Color primaryColor = Color(0xFF2E7D32);
const Color backgroundLight = Color(0xFFF6F8F6);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Drop',

      // ==============================
      // LOCALIZATION
      // ==============================
      localizationsDelegates:
          AppLocalizations.localizationsDelegates,

      supportedLocales:
          AppLocalizations.supportedLocales,

      // ==============================
      // THEME
      // ==============================
      theme: ThemeData(
        textTheme: GoogleFonts.getTextTheme('Roboto'),
        scaffoldBackgroundColor: backgroundLight,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      debugShowCheckedModeBanner: false,

      // ==============================
      // SPLASH SCREEN
      // ==============================
      home: const CropDropSplashScreen(),
    );
  }
}

class CropDropSplashScreen extends StatefulWidget {
  const CropDropSplashScreen({super.key});

  @override
  State<CropDropSplashScreen> createState() =>
      _CropDropSplashScreenState();
}

class _CropDropSplashScreenState
    extends State<CropDropSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    Timer(
      const Duration(milliseconds: 3500),
      () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/bg3.png',
                fit: BoxFit.cover,
              ),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 250),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:
                            primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/app_logo.png',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Crop Drop",
                      style: GoogleFonts.roboto(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 40,
              left: 32,
              right: 32,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.all(
                      Radius.circular(999),
                    ),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _controller.value,
                          minHeight: 8,
                          backgroundColor:
                              primaryColor.withOpacity(0.2),
                          valueColor:
                              const AlwaysStoppedAnimation<
                                  Color>(
                            primaryColor,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    "Analyzing your fields...",
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color:
                          primaryColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}