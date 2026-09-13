import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:farmer_app/services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriPredict',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF0FBF6),
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      home: const AgriPredictScreen(),
    );
  }
}

class AgriPredictScreen extends StatefulWidget {
  const AgriPredictScreen({super.key});

  @override
  State<AgriPredictScreen> createState() => _AgriPredictScreenState();
}

class _AgriPredictScreenState extends State<AgriPredictScreen> {
  String? _selectedState;
  String? _selectedCrop;

  final List<String> _states = [
    'Haryana',
    'Punjab',
    'Uttar Pradesh',
    'Maharashtra',
    'Karnataka',
  ];

  final List<String> _crops = ['Wheat', 'Rice', 'Sugarcane', 'Cotton', 'Maize'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'AgriPredict',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('🌾', style: TextStyle(fontSize: 30)),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Get real-time market predictions for your crop.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 50),

                      // Card container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enter Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // State Selector Box
                            _buildDropdownBox(
                              title: 'Select State',
                              value: _selectedState,
                              items: _states,
                              onChanged: (val) {
                                setState(() => _selectedState = val);
                              },
                            ),
                            const SizedBox(height: 16),

                            // Crop Selector Box
                            _buildDropdownBox(
                              title: 'Select Crop',
                              value: _selectedCrop,
                              items: _crops,
                              onChanged: (val) {
                                setState(() => _selectedCrop = val);
                              },
                            ),
                            const SizedBox(height: 32),

                            // View Predictions Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                  backgroundColor: const Color(0xFF2E7D32),
                                ),
                                onPressed: () async {
                                  if (_selectedState == null ||
                                      _selectedCrop == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Please select both State and Crop",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryanimation,
                                          ) => const AgricultureLoadingScreen(),
                                      transitionsBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            const begin = Offset(1.0, 0.0);
                                            const end = Offset.zero;
                                            const curve = Curves.easeInOut;
                                            final tween = Tween(
                                              begin: begin,
                                              end: end,
                                            ).chain(CurveTween(curve: curve));
                                            return SlideTransition(
                                              position: animation.drive(tween),
                                              child: child,
                                            );
                                          },
                                    ),
                                  );

                                  try {
                                    final result =
                                        await ApiService.getPrediction(
                                          state: _selectedState!,
                                          crop: _selectedCrop!,
                                        );

                                    Navigator.pop(context);

                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => MarketPredictionScreen(
                                              crop: _selectedCrop!,
                                              state: _selectedState!,
                                              result: result,
                                            ),
                                        transitionsBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                              child,
                                            ) {
                                              final fadeTween = Tween<double>(
                                                begin: 0.0,
                                                end: 1.0,
                                              );
                                              final scaleTween = Tween<double>(
                                                begin: 0.8,
                                                end: 1.0,
                                              );

                                              return FadeTransition(
                                                opacity: animation.drive(
                                                  fadeTween,
                                                ),
                                                child: ScaleTransition(
                                                  scale: animation.drive(
                                                    scaleTween,
                                                  ),
                                                  child: child,
                                                ),
                                              );
                                            },
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Error: $e")),
                                    );
                                  }
                                },
                                child: const Text(
                                  'View Predictions',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              const Padding(
                padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Text(
                  'Powered by AI-based market prediction model.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom Boxed Dropdown Widget
  Widget _buildDropdownBox({
    required String title,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.black,
        ),
        dropdownColor: Colors.white, // dropdown menu background
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 14.0,
          ),
          border: InputBorder.none,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// --- Colors defined from the Tailwind config ---
const Color kPrimary = Color(0xFF1E4620);
const Color kBackgroundLightStart = Color(0xFFF0F3F1);
const Color kBackgroundLightEnd = Color(0xFFE6EBE8);
const Color kBackgroundDark = Color(0xFF10221C);

// Using Tailwind gray-800
const Color kCardDark = Color(0xFF1F2937);
const Color kCardLight = Colors.white;

const Color kTextPrimaryDark = Colors.white;
const Color kTextPrimaryLight = kPrimary;

// Using Tailwind gray-600 & gray-400
const Color kTextSecondaryLight = Color(0xFF4B5563);
const Color kTextSecondaryDark = Color(0xFF9CA3AF);

// Using Tailwind gray-200 & gray-700
const Color kBorderLight = Color(0xFFE5E7EB);
const Color kBorderDark = Color(0xFF374151);

// Using Tailwind green-600 & green-400
const Color kGreenLight = Color(0xFF16A34A);
const Color kGreenDark = Color(0xFF4ADE80);
// --- End of Colors ---

class MarketPredictionApp extends StatelessWidget {
  const MarketPredictionApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Market Prediction',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        fontFamily: 'Roboto',
      ),
      home: const AgriPredictScreen(),
    );
  }
}

class MarketPredictionScreen extends StatelessWidget {
  final String crop;
  final String state;
  final Map<String, dynamic> result;

  const MarketPredictionScreen({
    Key? key,
    required this.crop,
    required this.state,
    required this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final predictionData = result['prediction_data'] ?? {};
    final currentPrice = (predictionData['current_price'] ?? 0).toDouble();
    final trend = predictionData['trend'] ?? "N/A";
    final confidence = (predictionData['confidence'] ?? 0).toDouble();
    final weatherImpact = predictionData['weather_impact'] ?? "N/A";
    final recommendation = predictionData['recommendation'] ?? "N/A";
    final weeklyForecast = predictionData['weekly_forecast'] ?? {};

    // Extract dynamic chart data
    final List<double> forecastPrices = [];
    final List<String> weekLabels = [];
    weeklyForecast.forEach((week, data) {
      forecastPrices.add((data['price'] ?? 0).toDouble());
      weekLabels.add(week);
    });

    double _getDynamicYInterval(List<double> prices) {
      if (prices.isEmpty) return 100;

      final double minVal = prices.reduce((a, b) => a < b ? a : b);
      final double maxVal = prices.reduce((a, b) => a > b ? a : b);
      final double range = maxVal - minVal;

      if (range < 200) return 50;
      if (range < 500) return 100;
      if (range < 1000) return 200;
      if (range < 2000) return 400;
      return 500;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF2F4F3F),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Market Prediction',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F1720),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Crop name
              Text(
                crop,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF12523B),
                ),
              ),
              const SizedBox(height: 14),

              // Current Price

              // Recommendation

              // Weekly Forecast Chart
              _CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '8-Week Price Forecast',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF092B20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 230,
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: (forecastPrices.length - 1).toDouble(),

                          // ✅ Rounded & padded Y range to prevent overlap
                          minY:
                              ((forecastPrices.reduce(
                                            (a, b) => a < b ? a : b,
                                          )) /
                                          50)
                                      .floor() *
                                  50 -
                              100,
                          maxY:
                              ((forecastPrices.reduce(
                                            (a, b) => a > b ? a : b,
                                          )) /
                                          50)
                                      .ceil() *
                                  50 +
                              100,

                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 50,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index >= 0 && index < weekLabels.length) {
                                    if (index % 2 == 0) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          weekLabels[index],
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF2D3748),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                interval: _getDynamicYInterval(forecastPrices),
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Text(
                                      '₹${value.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF4A5568),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              left: BorderSide(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              bottom: BorderSide(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              fitInsideHorizontally: true,
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final price = forecastPrices[spot.spotIndex]
                                      .toStringAsFixed(2);
                                  final week = weekLabels[spot.spotIndex];
                                  return LineTooltipItem(
                                    "$week\n₹$price",
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                forecastPrices.length,
                                (index) => FlSpot(
                                  index.toDouble(),
                                  forecastPrices[index],
                                ),
                              ),
                              isCurved: true,
                              color: const Color(0xFF1E7A54),
                              barWidth: 3,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter:
                                    (spot, percent, barData, index) =>
                                        FlDotCirclePainter(
                                          radius: 4,
                                          color: Colors.white,
                                          strokeWidth: 2,
                                          strokeColor: const Color(0xFF1E7A54),
                                        ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF1E7A54).withOpacity(0.3),
                                    const Color(0xFF1E7A54).withOpacity(0.05),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              _CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Market Price',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF12523B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${currentPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0E2A20),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Trend: $trend',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.trending_up,
                          color: Color(0xFF1E8F5C),
                          size: 28,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Confidence card
              _CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Confidence Level',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF092B20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _GradientProgressBar(
                            percent: (confidence / 100),
                            height: 18,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFEA6A2E),
                                Color(0xFFF2C94C),
                                Color(0xFF1EA64B),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${confidence.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Weather Impact
              _CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weather Impact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF092B20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      weatherImpact,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              _CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommendation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF092B20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recommendation,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;

  const _CardContainer({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  final double percent;
  final double height;
  final Gradient gradient;

  const _GradientProgressBar({
    Key? key,
    required this.percent,
    required this.height,
    required this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: height,
              width: constraints.maxWidth * percent.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            );
          },
        ),
      ],
    );
  }
}

class AgricultureLoadingScreen extends StatefulWidget {
  const AgricultureLoadingScreen({super.key});

  @override
  State<AgricultureLoadingScreen> createState() =>
      _AgricultureLoadingScreenState();
}

class _AgricultureLoadingScreenState extends State<AgricultureLoadingScreen> {
  final List<String> _messages = [
    "🌾 AI is analyzing crop data...",
    "☀️ Checking latest weather trends...",
    "📈 Estimating future market prices...",
    "🚜 Preparing smart farming insights...",
    "🌱 Generating accurate price forecast...",
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startMessageLoop();
  }

  void _startMessageLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) break;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _messages.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Color(0xff2e7d32),
              strokeWidth: 5,
            ),
            const SizedBox(height: 30),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _messages[_currentIndex],
                key: ValueKey(_currentIndex),
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xff1e4620),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
