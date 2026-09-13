import 'package:farmer_app/screens/homepage.dart';
import 'package:flutter/material.dart';
//import 'package:farmer_app/screens/select_language.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
// import 'dart:math' as math;

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
      home: const CropDropSplashScreen(),
    );
  }
}

class CropDropSplashScreen extends StatefulWidget {
  const CropDropSplashScreen({super.key});

  @override
  State<CropDropSplashScreen> createState() => _CropDropSplashScreenState();
}

class _CropDropSplashScreenState extends State<CropDropSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CropDropApp()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap Scaffold with WillPopScope to handle back button behavior
    return WillPopScope(
      onWillPop: () async => true, // allows popping to previous screen
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/bg3.png', fit: BoxFit.cover),
            ),
            // Main Centered Content
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 250),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),

                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.2),
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

            // Bottom Progress Bar and Text
            Positioned(
              bottom: 40,
              left: 32,
              right: 32,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _controller.value,
                          minHeight: 8,
                          backgroundColor: primaryColor.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
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
                      color: primaryColor.withOpacity(0.8),
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

// class _BackgroundLeaf extends StatelessWidget {
//   final String svgPath;
//   final double? top;
//   final double? bottom;
//   final double? left;
//   final double? right;
//   final double size;
//   final double angle;
//   final double scale;

  // const _BackgroundLeaf({
  //   required this.svgPath,
  //   this.top,
  //   this.bottom,
  //   this.left,
  //   this.right,
  //   required this.size,
  //   required this.angle,
  //   required this.scale,
  // });

//   @override
//   Widget build(BuildContext context) {
//     final screen = MediaQuery.of(context).size;
//     final double? topPos = top != null ? screen.height * top! : null;
//     final double? bottomPos = bottom != null ? screen.height * bottom! : null;
//     final double? leftPos = left != null ? screen.width * left! : null;
//     final double? rightPos = right != null ? screen.width * right! : null;

//     return Positioned(
//       top: topPos,
//       bottom: bottomPos,
//       left: leftPos,
//       right: rightPos,
//       child: Transform.scale(
//         scale: scale,
//         child: Transform.rotate(
//           angle: angle * (math.pi / 180),
//           child: SvgPicture.string(
//             svgPath,
//             width: size,
//             height: size,
//             colorFilter: ColorFilter.mode(
//               primaryColor.withOpacity(0.1),
//               BlendMode.srcIn,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// const String _leafPath1 =
//     '<svg viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10c2.17 0 4.19-.68 5.86-1.86.34-.23.53-.64.44-1.04-.09-.4-.44-.7-.86-.7H16c-3.31 0-6-2.69-6-6V4.41c0-.42-.3-.77-.72-.86-.4-.09-.81.1-1.04.44C7.48 4.67 6.8 6.69 6.8 8.86c0 3.31 2.69 6 6 6h1.59c.42 0 .77.3.86.72.09.4-.1.81-.44 1.04C16.19 21.32 14.17 22 12 22 6.48 22 2 17.52 2 12S6.48 2 12 2z"></path></svg>';

// const String _leafPath2 =
//     '<svg viewBox="0 0 24 24"><path d="M17.07 14.28c-.46-2.28-2.48-4-4.9-4-2.76 0-5 2.24-5 5s2.24 5 5 5c2.42 0 4.44-1.72 4.9-4h3.1v-1h-3.1zM12.17 2.01L12 2c-5.52 0-10 4.48-10 10 0 .55.08 1.08.23 1.58.55-4.49 4.26-8.08 8.78-8.52.55-.05 1.08-.08 1.58-.08.96 0 1.88.14 2.75.4C14.73 4.44 13.17 2.89 12.17 2.01z"></path></svg>';
