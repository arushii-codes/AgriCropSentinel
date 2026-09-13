import 'dart:async';
import 'package:farmer_app/screens/weather.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmer_app/screens/chatbot.dart';
import 'package:farmer_app/screens/npk_calc.dart';
import 'package:farmer_app/screens/profile_page.dart';
import 'package:farmer_app/screens/camera.dart';
import 'package:farmer_app/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';

Future<Position> getCurrentLocation() async {
  await Geolocator.requestPermission();
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

void main() {
  runApp(const CropDropApp());
}

class CropDropApp extends StatelessWidget {
  const CropDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Drop',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF9FAF8),
        textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
      ),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _showInitialTitle = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return; // ensure safety
      setState(() => _showInitialTitle = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    if (!mounted)
      return;
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NpkCalculatorPage()),
      );
      return;
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WeatherApp()),
      );
      return;
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? Colors.grey[800] : Colors.grey[800];
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const Color primaryColor = Color(0xFF2E7D32);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: const Color(0xFFF9FAF8),
                pinned: true,
                floating: false,
                toolbarHeight: 70,
                automaticallyImplyLeading: false,
                scrolledUnderElevation: 0.0,
                elevation: 0,
                title: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    AnimatedOpacity(
                      opacity: _showInitialTitle ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 800),
                      child: Text(
                        loc.homeAppTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: _showInitialTitle ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 800),
                      child: Text(
                        loc.homeWelcomeBack,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 100.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ImagePickerScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFF2E7D32),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Detect Crop Disease 🌿",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Upload or capture a leaf image for instant AI diagnosis & IPM treatment.",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const WeatherMarketWidget(),
                      const SizedBox(height: 24),
                      SectionHeader(
                        title: loc.homeInsightsTitle,
                        showSeeAll: false,
                      ),
                      const SizedBox(height: 16),
                      InsightCard(
                        imagePath: 'assets/soybean.png',
                        title: loc.homeSoybeanPriceTitle,
                        subtitle: loc.homeSoybeanPriceSubtitle,
                        trailing: Text(
                          '↗ 5%',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InsightCard(
                        imagePath: 'assets/tomato_leaf.png',
                        title: loc.homeBlightAlertTitle,
                        subtitle: loc.homeBlightAlertSubtitle,
                        trailing: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const ChatbotFloatingButton(bottom: 40, right: 20),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 450),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const ImagePickerScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    final curvedAnimation = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    );

                    return ScaleTransition(
                      scale: curvedAnimation,
                      alignment: Alignment.bottomCenter,
                      child: FadeTransition(
                        opacity: curvedAnimation,
                        child: child,
                      ),
                    );
                  },
            ),
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(
          Icons.camera_alt_outlined,
          size: 30,
          color: Colors.white,
        ),
        elevation: 4,
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 10,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.home_outlined, label: 'Home', index: 0),
              _buildNavItem(
                icon: Icons.calculate_outlined,
                label: 'NPK Calc',
                index: 1,
              ),
              const SizedBox(width: 40),
              _buildNavItem(
                icon: Icons.cloud_outlined,
                label: 'Weather',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_outlined,
                label: 'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final bool showSeeAll;
  const SectionHeader({super.key, required this.title, this.showSeeAll = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (showSeeAll)
          Text(
            'See all',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF2E7D32),
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class InsightCard extends StatelessWidget {
  final String imagePath, title, subtitle;
  final Widget trailing;
  const InsightCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.grey[200],
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class WeatherMarketWidget extends StatelessWidget {
  const WeatherMarketWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WeatherAppIconWidget(),
        const SizedBox(height: 12),
        // Container(
        //   padding: const EdgeInsets.all(16),
        //   decoration: BoxDecoration(
        //     color: Colors.green.shade50,
        //     borderRadius: BorderRadius.circular(12),
        //     boxShadow: [
        //       BoxShadow(
        //         color: Colors.grey.withOpacity(0.2),
        //         blurRadius: 8,
        //         offset: const Offset(0, 4),
        //       ),
        //     ],
        //   ),
        //   child: const Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       Icon(Icons.grass, color: Colors.green, size: 28),
        //       SizedBox(width: 10),
        //       Expanded(
        //         child: Text(
        //           "Get your crops’ upcoming prices 🌾",
        //           style: TextStyle(
        //             fontSize: 16,
        //             fontWeight: FontWeight.bold,
        //             color: Colors.black87,
        //           ),
        //         ),
        //       ),
        //       Icon(Icons.arrow_forward_ios, size: 16, color: Colors.green),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}

String getWeatherIcon(Map<String, dynamic> data) {
  final description = data['weather'][0]['main'].toString().toLowerCase();

  if (description.contains('cloud')) {
    return 'assets/cloud.png';
  } else if (description.contains('sun') || description.contains('clear')) {
    return 'assets/sun.png';
  } else if (description.contains('rain') || description.contains('drizzle')) {
    return 'assets/rain.png';
  } else if (description.contains('storm') || description.contains('thunder')) {
    return 'assets/thunder.png';
  } else {
    return 'assets/sun.png';
  }
}

// class WeatherCard extends StatefulWidget {
//   const WeatherCard({super.key});

//   @override
//   State<WeatherCard> createState() => _WeatherCardState();
// }

// class _WeatherCardState extends State<WeatherCard> {
//   Map<String, dynamic>? weatherData;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     loadCachedWeather(); // Step 1: Load cached data immediately
//     loadWeather(); // Step 2: Fetch fresh data in background
//   }

//   /// Load cached weather from SharedPreferences
//   Future<void> loadCachedWeather() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     final cached = prefs.getString('cached_weather');
//     if (cached != null) {
//       final data = jsonDecode(cached);
//       if (mounted) {
//         setState(() {
//           weatherData = data;
//           isLoading = false;
//         });
//       }
//     }
//   }

//   /// Fetch fresh weather from API
//   Future<void> loadWeather() async {
//     try {
//       Position pos = await getCurrentLocation();
//       final data = await fetchWeather(pos.latitude, pos.longitude);

//       // Cache the fresh data
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       prefs.setString('cached_weather', jsonEncode(data));

//       if (mounted) {
//         setState(() {
//           weatherData = data;
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       print("Weather fetch error: $e");
//       if (mounted) setState(() => isLoading = false);
//     }
//   }

//   /// Decide weather icon
//   String getWeatherIcon(Map<String, dynamic> data) {
//     final description = data['weather'][0]['main'].toString().toLowerCase();
//     final currentHour = DateTime.now().hour;

//     bool isDayTime = currentHour >= 6 && currentHour < 18;

//     if (description.contains('cloud')) {
//       return 'assets/cloud.png';
//     } else if (description.contains('sun') || description.contains('clear')) {
//       return isDayTime ? 'assets/sun.png' : 'assets/moon3.png';
//     } else if (description.contains('rain') ||
//         description.contains('drizzle')) {
//       return 'assets/rain.png';
//     } else if (description.contains('storm') ||
//         description.contains('thunder')) {
//       return 'assets/thunder.png';
//     } else {
//       return isDayTime ? 'assets/sun.png' : 'assets/moon3.png';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // final loc = AppLocalizations.of(context)!;

//     return InkWell(
//       borderRadius: BorderRadius.circular(16),
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const WeatherApp()),
//         );
//       },
//       child: Container(
//         height: 180,
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: Color(0xFF039BE5),
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               blurRadius: 10,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),

//         child: isLoading && weatherData == null
//             ? const Center(
//                 child: CircularProgressIndicator(color: Colors.green),
//               )
//             : weatherData != null
//             ? Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // City Name
//                       Text(
//                         "${weatherData!['name']}",
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           Text(
//                             "${weatherData!['main']['temp'].toInt()}°C",
//                             style: const TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 0),
//                       Padding(
//                         padding: const EdgeInsets.only(bottom: 3.0),
//                         child: Text(
//                           "${weatherData!['weather'][0]['description']}",
//                           style: const TextStyle(
//                             color: Colors.black,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       // High / Low Temperature
//                       Row(
//                         children: [
//                           Text(
//                             "H: ${weatherData!['main']['temp_max'].toInt()}°C",
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: Colors.black,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Text(
//                             "L: ${weatherData!['main']['temp_min'].toInt()}°C",
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: Colors.black,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const Spacer(),
//                       // Humidity & Wind
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Row(
//                             children: [
//                               const Icon(
//                                 Icons.water_drop,
//                                 color: Colors.blueAccent,
//                                 size: 20,
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 "${weatherData!['main']['humidity']}%",
//                                 style: const TextStyle(fontSize: 12),
//                               ),

//                               const SizedBox(width: 20),

//                               const Icon(
//                                 Icons.air,
//                                 color: Colors.black,
//                                 size: 20,
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 "${weatherData!['wind']['speed']} m/s",
//                                 style: const TextStyle(fontSize: 12),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   Positioned(
//                     top: -15,
//                     right: -15,
//                     child: Image.asset(
//                       getWeatherIcon(weatherData!),
//                       width: 60,
//                       height: 60,
//                     ),
//                   ),
//                 ],
//               )
//             : const Center(child: Text("Failed to load weather")),
//       ),
//     );
//   }
// }

class ChatbotFloatingButton extends StatefulWidget {
  final double bottom;
  final double right;

  const ChatbotFloatingButton({super.key, this.bottom = 40, this.right = 20});

  @override
  State<ChatbotFloatingButton> createState() => _ChatbotFloatingButtonState();
}

class _ChatbotFloatingButtonState extends State<ChatbotFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _hoverAnimation;
  late Animation<double> _vibrateAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _hoverAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -10), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: -10, end: 5), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 5, end: 0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _vibrateAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -2), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: -2, end: 2), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 2, end: 0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          bottom: widget.bottom + _hoverAnimation.value,
          right: widget.right + _vibrateAnimation.value,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;

                  final offset = renderBox.localToGlobal(Offset.zero);
                  final size = renderBox.size;
                  final iconCenter =
                      offset + Offset(size.width / 2, size.height / 2);

                  Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 500),
                      reverseTransitionDuration: const Duration(
                        milliseconds: 400,
                      ),
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const ChatScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            final curved = CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            );

                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: AnimatedBuilder(
                                    animation: curved,
                                    builder: (context, _) {
                                      final scale = Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ).animate(curved).value;

                                      return Transform.scale(
                                        scale: scale,
                                        origin: Offset(
                                          iconCenter.dx -
                                              MediaQuery.of(
                                                    context,
                                                  ).size.width /
                                                  2,
                                          iconCenter.dy -
                                              MediaQuery.of(
                                                    context,
                                                  ).size.height /
                                                  2,
                                        ),
                                        child: FadeTransition(
                                          opacity: curved,
                                          child: child,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                    ),
                  );
                },

                child: Material(
                  elevation: 6,
                  shape: const CircleBorder(),
                  color: Colors.white,
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Center(
                      child: ClipOval(
                        child: Image.asset(
                          'assets/bot.png',
                          width: 85,
                          height: 85,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 90,
                right: -10,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    loc.homeChatbotFloatingMessage,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
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

class MarketPriceCard extends StatelessWidget {
  const MarketPriceCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the primary thematic color
    const Color primaryGreen = Color(0xFF2E7D32); // Darker Green
    const Color lightGreen = Color(0xFFC8E6C9); // Very Light Green

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // TODO: Navigate to your crop price prediction page
        // Navigator.push(context,
        //     MaterialPageRoute(builder: (_) => const CropPricePage()));
      },
      // Using a fixed height for a clean, consistent UI card size
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(16), // Slightly increased padding
        decoration: BoxDecoration(
          // Unique Gradient: Green tones for agricultural theme
          gradient: const LinearGradient(
            colors: [
              Color(0xFF43A047),
              Color(0xFFE0F7FA),
            ], // Dark Green to Medium Green
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          // Subtle box shadow for lift
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Use spaceBetween to push the CTA to the bottom
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title
            const Text(
              "Get Crop Price Forecasts 📈",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    Colors.black, // Text color contrasted with dark background
              ),
            ),

            // Description
            const Text(
              "Know your crop’s upcoming market trends and stay ahead of mandi prices.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black, // Slightly desaturated white for hierarchy
                height: 1.4,
              ),
            ),

            // CTA Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: lightGreen, // Light green background for CTA
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "Check Prices",
                    style: TextStyle(
                      color: primaryGreen, // Dark green text
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.trending_up, // More thematic icon
                    color: primaryGreen,
                    size: 20,
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

class WeatherAppIconWidget extends StatelessWidget {
  const WeatherAppIconWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the colors for the blue gradient
    const Color darkBlue = Color(0xFF1E88E5); // A darker, vibrant blue
    const Color lightBlue = Color(0xFF42A5F5); // A lighter blue

    return Container(
      width: 150, // Fixed width for the icon/widget appearance
      height: 150, // Fixed height
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Blue Gradient background
        gradient: const LinearGradient(
          colors: [darkBlue, lightBlue],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        // Rounded corners
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top Row: Temperature and Cloud Icon ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '23°',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w400,
                  // Tighter line height to match the image spacing
                  height: 1.0,
                ),
              ),
              // Cloud icon
              Icon(Icons.sunny, color: Colors.yellow, size: 50),
            ],
          ),

          // --- Middle Section: Date and Condition ---
          const SizedBox(height: 4),
          const Text(
            'Friday 16:00',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Text(
            'Cloudy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Spacer to push the forecast cards to the bottom
          const Spacer(),

          // --- Bottom Row: 3-Day Forecast Cards ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            // children: const [
            //   _ForecastChip(day: 'Sat', temp: 22),
            //   _ForecastChip(day: 'Sun', temp: 15),
            //   _ForecastChip(day: 'Mon', temp: 17),
            // ],
          ),
        ],
      ),
    );
  }
}

// Separate stateless widget for the forecast chip (Sat, Sun, Mon)
class _ForecastChip extends StatelessWidget {
  final String day;
  final int temp;

  const _ForecastChip({required this.day, required this.temp});

  @override
  Widget build(BuildContext context) {
    // Defines the slightly darker, translucent background for the chip
    const Color chipColor = Color.fromRGBO(0, 0, 0, 0.15);

    return Container(
      width: 40, // Fixed width for a uniform look
      height: 48, // Fixed height
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(10), // Rounded corners for the chip
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$temp°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
