import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:farmer_app/l10n/app_localizations.dart';
import 'package:farmer_app/screens/weather.dart';
import 'package:farmer_app/screens/chatbot.dart';
import 'package:farmer_app/screens/npk_calc.dart';
import 'package:farmer_app/screens/profile_page.dart';
import 'package:farmer_app/screens/camera.dart';

import 'package:farmer_app/l10n/app_localizations.dart';
import '../services/api_service.dart';

// ============================================================
// LOCATION
// ============================================================

Future<Position> getCurrentLocation() async {
  final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    throw Exception('Location services are disabled.');
  }

  LocationPermission permission =
      await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied) {
    throw Exception('Location permission denied.');
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception(
      'Location permission permanently denied.',
    );
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

// ============================================================
// APP
// ============================================================

void main() {
  runApp(const CropDropApp());
}

class CropDropApp extends StatelessWidget {
  const CropDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Drop',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        scaffoldBackgroundColor:
            const Color(0xFFF6F7F1),

        primaryColor:
            const Color(0xFF285C2D),

        colorScheme:
            ColorScheme.fromSeed(
          seedColor:
              const Color(0xFF285C2D),
        ),

        textTheme:
            GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),

        useMaterial3: true,
      ),

      locale: const Locale('en'),

      localizationsDelegates:
          AppLocalizations.localizationsDelegates,

      supportedLocales:
          AppLocalizations.supportedLocales,

      home: const HomeScreen(),
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  void _onItemTapped(int index) {
    if (index == 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return;
    }

    if (index == 1) {
      setState(() {
        _selectedIndex = 1;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const NpkCalculatorPage(),
        ),
      );

      return;
    }

    if (index == 2) {
      setState(() {
        _selectedIndex = 2;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const WeatherApp(),
        ),
      );

      return;
    }

    if (index == 3) {
      setState(() {
        _selectedIndex = 3;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ProfilePage(),
        ),
      );
    }
  }

  // ==========================================================
  // CAMERA
  // ==========================================================

  void _openCamera() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration:
            const Duration(milliseconds: 450),

        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return const CameraScreen();
        },

        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final curvedAnimation =
              CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );

          return ScaleTransition(
            scale: curvedAnimation,
            alignment:
                Alignment.bottomCenter,
            child: FadeTransition(
              opacity: curvedAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final loc =
        AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7F1),

      // ======================================================
      // BODY
      // ======================================================

      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              physics:
                  const BouncingScrollPhysics(),

              slivers: [

                // ==================================================
                // HEADER
                // ==================================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      24,
                      20,
                      24,
                      0,
                    ),

                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              Text(
                                'Welcome back! 👋',
                                style:
                                    GoogleFonts.poppins(
                                  fontSize: 29,
                                  fontWeight:
                                      FontWeight.w700,
                                  color:
                                      const Color(
                                    0xFF285C2D,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                'Grow smarter with AI-powered farming',
                                style:
                                    GoogleFonts.poppins(
                                  fontSize: 15,
                                  color:
                                      Colors.grey.shade600,
                                  fontWeight:
                                      FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Notification
                        Container(
                          width: 52,
                          height: 52,

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFE2ECC7,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                          ),

                          child: IconButton(
                            onPressed: () {
                              _showNotificationDialog(
                                context,
                              );
                            },

                            icon:
                                const Icon(
                              Icons
                                  .notifications_none_rounded,
                              color:
                                  Color(0xFF285C2D),
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ==================================================
                // HERO CARD
                // ==================================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 28,
                    ),
                    child:
                        _buildHeroCard(),
                  ),
                ),

                // ==================================================
                // WEATHER + CROP HEALTH
                // ==================================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 24,
                    ),

                    child: SizedBox(
                      height: 205,

                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,

                        children: [

                          Expanded(
                            child:
                                _buildWeatherCard(),
                          ),

                          const SizedBox(
                            width: 14,
                          ),

                          Expanded(
                            child:
                                _buildCropHealthCard(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // QUICK ACTIONS TITLE
                // ==================================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      24,
                      28,
                      24,
                      0,
                    ),

                    child:
                        const SectionHeader(
                      title:
                          'Quick actions',
                      showSeeAll: false,
                    ),
                  ),
                ),

                // ==================================================
                // QUICK ACTIONS
                // ==================================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      24,
                      14,
                      24,
                      0,
                    ),

                    child: Row(
                      children: [

                        Expanded(
                          child:
                              _buildQuickAction(
                            icon:
                                Icons
                                    .camera_alt_outlined,
                            title:
                                'Scan Crop',
                            subtitle:
                                'AI diagnosis',
                            onTap:
                                _openCamera,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child:
                              _buildQuickAction(
                            icon:
                                Icons
                                    .science_outlined,
                            title:
                                'NPK',
                            subtitle:
                                'Fertilizer',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const NpkCalculatorPage(),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child:
                              _buildQuickAction(
                            icon:
                                Icons
                                    .cloud_outlined,
                            title:
                                'Weather',
                            subtitle:
                                'Risk forecast',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const WeatherApp(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ==================================================
                // INSIGHTS
                // ==================================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      24,
                      30,
                      24,
                      0,
                    ),

                    child:
                        SectionHeader(
                      title:
                          loc.homeInsightsTitle,
                      showSeeAll: false,
                    ),
                  ),
                ),

                // ==================================================
                // MARKET PREDICTION
                // ==================================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      24,
                      14,
                      24,
                      0,
                    ),

                    child:
                        _buildPredictionCard(),
                  ),
                ),

                const SliverToBoxAdapter(
                  child:
                      SizedBox(height: 12),
                ),

                // ==================================================
                // EARLY WARNING
                // ==================================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 24,
                    ),

                    child:
                        _buildBlightAlertCard(
                      loc,
                    ),
                  ),
                ),

                // ==================================================
                // BOTTOM SPACE
                // ==================================================

                const SliverToBoxAdapter(
                  child:
                      SizedBox(height: 130),
                ),
              ],
            ),

            // ====================================================
            // FLOATING CHATBOT
            // ====================================================

            const ChatbotFloatingButton(
              bottom: 88,
              right: 20,
            ),
          ],
        ),
      ),

      // ========================================================
      // CENTER CAMERA BUTTON
      // ========================================================

      floatingActionButtonLocation:
          FloatingActionButtonLocation
              .centerDocked,

      floatingActionButton:
          Container(
        width: 68,
        height: 68,

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          color:
              const Color(0xFFE9F044),

          border: Border.all(
            color:
                const Color(0xFFF6F7F1),
            width: 5,
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(
                0.15,
              ),
              blurRadius: 12,
              offset:
                  const Offset(0, 5),
            ),
          ],
        ),

        child: IconButton(
          onPressed: _openCamera,

          icon: const Icon(
            Icons.camera_alt_outlined,
            color:
                Color(0xFF285C2D),
            size: 30,
          ),
        ),
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar:
          SafeArea(
        top: false,

        child: Container(
          height: 68,

          decoration:
              const BoxDecoration(
            color: Colors.white,
          ),

          child: Row(
            children: [

              _buildNavItem(
                icon:
                    Icons.home_outlined,
                label:
                    'Home',
                index: 0,
              ),

              _buildNavItem(
                icon:
                    Icons.science_outlined,
                label:
                    'NPK',
                index: 1,
              ),

              const SizedBox(
                width: 70,
              ),

              _buildNavItem(
                icon:
                    Icons.cloud_outlined,
                label:
                    'Weather',
                index: 2,
              ),

              _buildNavItem(
                icon:
                    Icons.person_outline,
                label:
                    'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HERO CARD
  // ============================================================

  Widget _buildHeroCard() {
    return Container(
      height: 290,

      decoration:
          const BoxDecoration(
        gradient:
            LinearGradient(
          colors: [
            Color(0xFF214F29),
            Color(0xFF587C3C),
          ],
          begin:
              Alignment.centerLeft,
          end:
              Alignment.centerRight,
        ),

        borderRadius:
            BorderRadius.only(
          topRight:
              Radius.circular(40),
          bottomRight:
              Radius.circular(40),
        ),
      ),

      child: Stack(
        children: [

          // Decorative circle
          Positioned(
            right: -40,
            bottom: -45,

            child: Container(
              width: 220,
              height: 220,

              decoration:
                  BoxDecoration(
                color:
                    Colors.white.withOpacity(
                  0.07,
                ),
                shape:
                    BoxShape.circle,
              ),

              child: const Icon(
                Icons.spa_outlined,
                size: 150,
                color:
                    Colors.white24,
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              34,
              34,
              30,
              25,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 9,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white.withOpacity(
                      0.13,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                  ),

                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [

                      const Text(
                        '✨',
                        style:
                            TextStyle(
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(
                        width: 7,
                      ),

                      Text(
                        'AI POWERED FARMING',
                        style:
                            GoogleFonts.poppins(
                          color:
                              Colors.white,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w700,
                          letterSpacing:
                              0.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                Text(
                  'Control your\nfield with AI',

                  style:
                      GoogleFonts.poppins(
                    color:
                        Colors.white,
                    fontSize: 34,
                    height: 1.05,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  'Detect crop problems early and make smarter decisions.',

                  style:
                      GoogleFonts.poppins(
                    color:
                        Colors.white.withOpacity(
                      0.80,
                    ),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),

                const Spacer(),

                // Scan button
                GestureDetector(
                  onTap:
                      _openCamera,

                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 13,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFE9F044,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        35,
                      ),
                    ),

                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,

                      children: [

                        Text(
                          'Scan Your Crop',
                          style:
                              GoogleFonts.poppins(
                            color:
                                const Color(
                              0xFF285C2D,
                            ),
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        const Icon(
                          Icons
                              .arrow_forward_rounded,
                          color:
                              Color(0xFF285C2D),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WEATHER CARD
  // ============================================================

  Widget _buildWeatherCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const WeatherApp(),
          ),
        );
      },

      child: Container(
        padding:
            const EdgeInsets.all(22),

        decoration:
            const BoxDecoration(
          gradient:
              LinearGradient(
            colors: [
              Color(0xFF77904A),
              Color(0xFF6D8745),
            ],
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
          ),

          borderRadius:
              BorderRadius.only(
            topRight:
                Radius.circular(35),
            bottomRight:
                Radius.circular(35),
          ),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [

                Text(
                  'WEATHER',
                  style:
                      GoogleFonts.poppins(
                    color:
                        Colors.white.withOpacity(
                      0.85,
                    ),
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),

                const Icon(
                  Icons.cloud,
                  color:
                      Color(0xFFE9F044),
                  size: 32,
                ),
              ],
            ),

            const Spacer(),

            Text(
              '23°C',

              style:
                  GoogleFonts.poppins(
                color:
                    Colors.white,
                fontSize: 42,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 2,
            ),

            Text(
              'Cloudy • Today',

              style:
                  GoogleFonts.poppins(
                color:
                    Colors.white.withOpacity(
                  0.85,
                ),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CROP HEALTH CARD
  // ============================================================

  Widget _buildCropHealthCard() {
    return GestureDetector(
      onTap:
          _openCamera,

      child: Container(
        padding:
            const EdgeInsets.all(22),

        decoration:
            BoxDecoration(
          color:
              const Color(0xFFF2F5E9),

          border:
              Border.all(
            color:
                const Color(0xFFD7E2BD),
            width: 1.5,
          ),

          borderRadius:
              const BorderRadius.only(
            topLeft:
                Radius.circular(35),
            bottomLeft:
                Radius.circular(35),
          ),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [

                Text(
                  'CROP HEALTH',

                  style:
                      GoogleFonts.poppins(
                    color:
                        const Color(
                      0xFF6D8745,
                    ),
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),

                const Icon(
                  Icons.eco_outlined,
                  color:
                      Color(0xFF77904A),
                  size: 30,
                ),
              ],
            ),

            const Spacer(),

            Text(
              'Monitor',

              style:
                  GoogleFonts.poppins(
                color:
                    const Color(
                  0xFF285C2D,
                ),
                fontSize: 31,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 2,
            ),

            Text(
              'Scan leaves for diseases',

              style:
                  GoogleFonts.poppins(
                color:
                    Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTION
  // ============================================================

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap:
          onTap,

      child: Container(
        height: 105,

        padding:
            const EdgeInsets.all(14),

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(22),

          border:
              Border.all(
            color:
                const Color(0xFFE3E8DA),
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(
                0.04,
              ),
              blurRadius: 10,
              offset:
                  const Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Container(
              width: 38,
              height: 38,

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFE8EFD7,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child: Icon(
                icon,
                color:
                    const Color(
                  0xFF285C2D,
                ),
                size: 21,
              ),
            ),

            const Spacer(),

            Text(
              title,

              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,

              style:
                  GoogleFonts.poppins(
                fontSize: 13,
                fontWeight:
                    FontWeight.w700,
                color:
                    const Color(
                  0xFF285C2D,
                ),
              ),
            ),

            Text(
              subtitle,

              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,

              style:
                  GoogleFonts.poppins(
                fontSize: 10,
                color:
                    Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MARKET PREDICTION
  // ============================================================

  Widget _buildPredictionCard() {
    return FutureBuilder<
        Map<String, dynamic>>(
      future:
          ApiService.getPrediction(
        state: 'Haryana',
        crop: 'Wheat',
      ),

      builder:
          (context, snapshot) {

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return
              _buildPredictionLoadingCard();
        }

        if (snapshot.hasError ||
            !snapshot.hasData) {
          return
              _buildPredictionErrorCard();
        }

        final predictionData =
            snapshot.data![
                'prediction_data'];

        if (predictionData
            is! Map<String, dynamic>) {
          return
              _buildPredictionErrorCard();
        }

        final currentPrice =
            predictionData[
                    'current_price'] ??
                0;

        final trend =
            predictionData['trend']
                    ?.toString() ??
                'Stable';

        final confidence =
            ((predictionData[
                          'confidence'] ??
                      0) *
                  100)
              .round();

        final isRising =
            trend.toLowerCase() ==
                'rising';

        return Container(
          padding:
              const EdgeInsets.all(18),

          decoration:
              BoxDecoration(
            color:
                Colors.white,

            borderRadius:
                BorderRadius.circular(24),

            border:
                Border.all(
              color:
                  const Color(0xFFE1E7D6),
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(
                  0.04,
                ),
                blurRadius: 10,
                offset:
                    const Offset(0, 4),
              ),
            ],
          ),

          child: Row(
            children: [

              // Crop image
              Container(
                width: 65,
                height: 65,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFEAF0DB,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),

                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),

                  child:
                      Image.asset(
                    'assets/soybean.png',
                    fit:
                        BoxFit.cover,

                    errorBuilder:
                        (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const Icon(
                        Icons.grass,
                        color:
                            Color(
                          0xFF77904A,
                        ),
                        size: 32,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [

                    Text(
                      'Wheat Price',

                      style:
                          GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            const Color(
                          0xFF222222,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      '₹$currentPrice / quintal',

                      style:
                          GoogleFonts.poppins(
                        fontSize: 14,
                        color:
                            Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      '$confidence% prediction confidence',

                      style:
                          GoogleFonts.poppins(
                        fontSize: 11,
                        color:
                            Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),

                decoration:
                    BoxDecoration(
                  color: isRising
                      ? const Color(
                          0xFFE6F2D0,
                        )
                      : const Color(
                          0xFFF9E5E5,
                        ),

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child: Text(
                  isRising
                      ? '↑ Rising'
                      : '↓ Falling',

                  style:
                      GoogleFonts.poppins(
                    color: isRising
                        ? const Color(
                            0xFF39713D,
                          )
                        : Colors.redAccent,

                    fontSize: 11,

                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // PREDICTION LOADING
  // ============================================================

  Widget _buildPredictionLoadingCard() {
    return Container(
      height: 105,

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(24),
      ),

      child: Row(
        children: [

          Container(
            width: 65,
            height: 65,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFEAF0DB,
              ),
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),

            child:
                const Icon(
              Icons.grass,
              color:
                  Color(0xFF77904A),
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  'Wheat Price',

                  style:
                      GoogleFonts.poppins(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'Loading prediction...',

                  style:
                      GoogleFonts.poppins(
                    color:
                        Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 20,
            height: 20,

            child:
                CircularProgressIndicator(
              strokeWidth: 2,
              color:
                  Color(0xFF77904A),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PREDICTION ERROR
  // ============================================================

  Widget _buildPredictionErrorCard() {
    return Container(
      height: 105,

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(24),

        border:
            Border.all(
          color:
              const Color(0xFFE1E7D6),
        ),
      ),

      child: Row(
        children: [

          Container(
            width: 65,
            height: 65,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFEAF0DB,
              ),
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),

            child:
                const Icon(
              Icons.grass,
              color:
                  Color(0xFF77904A),
              size: 30,
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  'Wheat Price',

                  style:
                      GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  'Prediction unavailable',

                  style:
                      GoogleFonts.poppins(
                    color:
                        Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.error_outline,
            color:
                Colors.redAccent,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EARLY WARNING
  // ============================================================

  Widget _buildBlightAlertCard(
    AppLocalizations loc,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF1F4E8),

        borderRadius:
            BorderRadius.circular(24),

        border:
            Border.all(
          color:
              const Color(0xFFDCE6C9),
        ),
      ),

      child: Row(
        children: [

          Container(
            width: 65,
            height: 65,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFDDE8C5,
              ),
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),

            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                18,
              ),

              child:
                  Image.asset(
                'assets/tomato_leaf.png',

                fit:
                    BoxFit.cover,

                errorBuilder:
                    (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const Icon(
                    Icons
                        .warning_amber_rounded,
                    color:
                        Color(0xFF77904A),
                    size: 32,
                  );
                },
              ),
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  loc.homeBlightAlertTitle,

                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        const Color(
                      0xFF285C2D,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  loc.homeBlightAlertSubtitle,

                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      GoogleFonts.poppins(
                    fontSize: 12,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Container(
            width: 42,
            height: 42,

            decoration:
                const BoxDecoration(
              color:
                  Color(0xFFE7F0D1),
              shape:
                  BoxShape.circle,
            ),

            child:
                const Icon(
              Icons
                  .warning_amber_rounded,
              color:
                  Color(0xFF77904A),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVIGATION ITEM
  // ============================================================

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected =
        _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () =>
            _onItemTapped(index),

        borderRadius:
            BorderRadius.circular(20),

        child: SizedBox(
          height: 68,

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              Icon(
                icon,
                size: 25,

                color: isSelected
                    ? const Color(
                        0xFF285C2D,
                      )
                    : Colors.grey.shade500,
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                label,

                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,

                style:
                    GoogleFonts.poppins(
                  fontSize: 9,
                  height: 1.0,
                  fontWeight:
                      isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,

                  color: isSelected
                      ? const Color(
                          0xFF285C2D,
                        )
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION DIALOG
  // ============================================================

  void _showNotificationDialog(
    BuildContext context,
  ) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              25,
            ),
          ),

          title: Row(
            children: [

              Container(
                width: 42,
                height: 42,

                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFFE2ECC7),
                  shape:
                      BoxShape.circle,
                ),

                child:
                    const Icon(
                  Icons
                      .notifications_none_rounded,
                  color:
                      Color(0xFF285C2D),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              const Expanded(
                child: Text(
                  'Notifications',
                ),
              ),
            ],
          ),

          content:
              const Text(
            'No new notifications right now.\n\n'
            'Crop alerts and important farming '
            'updates will appear here.',
          ),

          actions: [

            TextButton(
              onPressed: () =>
                  Navigator.pop(context),

              child:
                  const Text(
                'Close',

                style:
                    TextStyle(
                  color:
                      Color(0xFF285C2D),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// SECTION HEADER
// ============================================================

class SectionHeader
    extends StatelessWidget {
  final String title;
  final bool showSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.showSeeAll = true,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: [

        Expanded(
          child: Text(
            title,

            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,

            style:
                GoogleFonts.poppins(
              fontSize: 21,
              fontWeight:
                  FontWeight.w700,
              color:
                  const Color(0xFF222222),
            ),
          ),
        ),

        if (showSeeAll)
          Text(
            'See all',

            style:
                GoogleFonts.poppins(
              fontSize: 13,
              color:
                  const Color(
                0xFF285C2D,
              ),
              fontWeight:
                  FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

// ============================================================
// CHATBOT FLOATING BUTTON
// ============================================================

class ChatbotFloatingButton
    extends StatefulWidget {
  final double bottom;
  final double right;

  const ChatbotFloatingButton({
    super.key,
    this.bottom = 88,
    this.right = 20,
  });

  @override
  State<ChatbotFloatingButton>
      createState() =>
          _ChatbotFloatingButtonState();
}

class _ChatbotFloatingButtonState
    extends State<
        ChatbotFloatingButton>
    with
        SingleTickerProviderStateMixin {
  late AnimationController
      _controller;

  late Animation<double>
      _hoverAnimation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
      vsync: this,
      duration:
          const Duration(
        milliseconds: 2800,
      ),
    )..repeat(
        reverse: true,
      );

    _hoverAnimation =
        Tween<double>(
      begin: 0,
      end: -6,
    ).animate(
      CurvedAnimation(
        parent:
            _controller,
        curve:
            Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final loc =
        AppLocalizations.of(
      context,
    )!;

    return AnimatedBuilder(
      animation:
          _controller,

      builder:
          (context, child) {
        return Positioned(
          bottom:
              widget.bottom +
                  _hoverAnimation.value,

          right:
              widget.right,

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,

            children: [

              // Chatbot message
              Container(
                constraints:
                    const BoxConstraints(
                  maxWidth: 160,
                ),

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(
                        0.12,
                      ),
                      blurRadius: 10,
                      offset:
                          const Offset(
                        0,
                        3,
                      ),
                    ),
                  ],
                ),

                child: Text(
                  loc.homeChatbotFloatingMessage,

                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      GoogleFonts.poppins(
                    color:
                        const Color(
                      0xFF285C2D,
                    ),
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // Bot button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ChatScreen(),
                    ),
                  );
                },

                child: Container(
                  width: 72,
                  height: 72,

                  padding:
                      const EdgeInsets.all(
                    4,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,

                    shape:
                        BoxShape.circle,

                    border:
                        Border.all(
                      color:
                          const Color(
                        0xFFDCE8C8,
                      ),
                      width: 3,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(
                          0.12,
                        ),
                        blurRadius: 12,
                        offset:
                            const Offset(
                          0,
                          4,
                        ),
                      ),
                    ],
                  ),

                  child: ClipOval(
                    child:
                        Image.asset(
                      'assets/bot.png',

                      fit:
                          BoxFit.cover,

                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Icon(
                          Icons
                              .smart_toy_outlined,
                          color:
                              Color(
                            0xFF285C2D,
                          ),
                          size: 38,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}