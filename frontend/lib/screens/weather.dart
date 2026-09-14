import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  static const String backendUrl = 'http://localhost:8000';

  bool _loading = true;
  String? _error;

  double temperature = 28.5;
  double humidity = 76.0;
  double rainfall = 12.4;
  double weatherRisk = 0.62;

  List<String> favorableConditions = [
    'Leaf Rust',
    'Late Blight',
  ];

  String locationName = 'Kurukshetra';

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      double lat = 29.9695;
      double lon = 76.8783;

      try {
        final serviceEnabled =
            await Geolocator.isLocationServiceEnabled();

        if (serviceEnabled) {
          LocationPermission permission =
              await Geolocator.checkPermission();

          if (permission == LocationPermission.denied) {
            permission =
                await Geolocator.requestPermission();
          }

          if (permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever) {
            final position =
                await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );

            lat = position.latitude;
            lon = position.longitude;
          }
        }
      } catch (_) {
        // Use default demo coordinates if browser location is unavailable.
      }

      final uri = Uri.parse(
        '$backendUrl/weather/risk?lat=$lat&lon=$lon',
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Weather API returned ${response.statusCode}',
        );
      }

      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final location =
          data['location'] as Map<String, dynamic>?;

      final conditions =
          data['favorable_conditions_for'];

      setState(() {
        temperature =
            (data['temperature_c'] ?? 28.5).toDouble();

        humidity =
            (data['humidity_pct'] ?? 76.0).toDouble();

        rainfall =
            (data['rainfall_mm_last_24h'] ?? 12.4).toDouble();

        weatherRisk =
            (data['weather_risk_score'] ?? 0.62).toDouble();

        if (location != null) {
          locationName =
              'Lat ${_format(location['lat'])}, '
              'Lon ${_format(location['lon'])}';
        }

        if (conditions is List) {
          favorableConditions = conditions
              .map((e) => _prettyName(e.toString()))
              .toList();
        }

        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Unable to load weather data.';
      });
    }
  }

  String _format(dynamic value) {
    if (value == null) return '--';

    final number = double.tryParse(value.toString());

    if (number == null) return value.toString();

    return number.toStringAsFixed(2);
  }

  String _prettyName(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String get riskLevel {
    if (weatherRisk >= 0.75) {
      return 'HIGH';
    }

    if (weatherRisk >= 0.45) {
      return 'MEDIUM';
    }

    return 'LOW';
  }

  Color get riskColor {
    if (weatherRisk >= 0.75) {
      return const Color(0xFFD94B4B);
    }

    if (weatherRisk >= 0.45) {
      return const Color(0xFFE39A32);
    }

    return const Color(0xFF4C8B52);
  }

  String get riskMessage {
    if (weatherRisk >= 0.75) {
      return 'Weather conditions are highly favorable for disease development.';
    }

    if (weatherRisk >= 0.45) {
      return 'Weather conditions may increase crop disease risk.';
    }

    return 'Weather conditions currently show low disease risk.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F1),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7F1),
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF285C2D),
          ),
        ),

        title: Text(
          'Weather & Risk',
          style: GoogleFonts.poppins(
            color: const Color(0xFF285C2D),
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _loadWeather,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF285C2D),
            ),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadWeather,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),

          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            35,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // LOCATION
              // =================================================

              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF77904A),
                    size: 21,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      locationName,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4EDD1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'LIVE',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF285C2D),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // =================================================
              // MAIN WEATHER CARD
              // =================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF214F29),
                      Color(0xFF648247),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),

                child: _loading
                    ? const SizedBox(
                        height: 230,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE9F044),
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CURRENT WEATHER',
                                    style:
                                        GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Today',
                                    style:
                                        GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              Container(
                                width: 58,
                                height: 58,
                                decoration:
                                    const BoxDecoration(
                                  color: Color(0x33FFFFFF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.cloud_outlined,
                                  color: Color(0xFFE9F044),
                                  size: 34,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${temperature.toStringAsFixed(1)}°',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 55,
                                  height: 1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.only(
                                  bottom: 6,
                                ),
                                child: Text(
                                  'C',
                                  style:
                                      GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 22,
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'Crop conditions are being monitored',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // WEATHER METRICS
              // =================================================

              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      icon: Icons.water_drop_outlined,
                      title: 'Humidity',
                      value:
                          '${humidity.toStringAsFixed(0)}%',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      icon: Icons.umbrella_outlined,
                      title: 'Rainfall',
                      value:
                          '${rainfall.toStringAsFixed(1)} mm',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      icon: Icons.thermostat_outlined,
                      title: 'Temperature',
                      value:
                          '${temperature.toStringAsFixed(1)}°C',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      icon: Icons.analytics_outlined,
                      title: 'Weather Risk',
                      value:
                          '${(weatherRisk * 100).round()}%',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // =================================================
              // DISEASE RISK
              // =================================================

              Text(
                'Disease Risk',
                style: GoogleFonts.poppins(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF222222),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFFE1E7D6),
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: riskColor,
                            size: 29,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$riskLevel RISK',
                                style:
                                    GoogleFonts.poppins(
                                  color: riskColor,
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${(weatherRisk * 100).round()}% weather risk score',
                                style:
                                    GoogleFonts.poppins(
                                  color:
                                      Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                    ),

                    const SizedBox(height: 18),

                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: weatherRisk.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor:
                            const Color(0xFFE8EDE1),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          riskColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      riskMessage,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // =================================================
              // FAVORABLE CONDITIONS
              // =================================================

              Text(
                'Conditions Favorable For',
                style: GoogleFonts.poppins(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF222222),
                ),
              ),

              const SizedBox(height: 12),

              if (favorableConditions.isEmpty)
                _emptyConditionsCard()
              else
                ...favorableConditions.map(
                  (condition) =>
                      _conditionCard(condition),
                ),

              const SizedBox(height: 24),

              // =================================================
              // EARLY WARNING
              // =================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4E7),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFFD9E4C5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE1EBCB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF285C2D),
                        size: 26,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Early Warning',
                            style: GoogleFonts.poppins(
                              color:
                                  const Color(0xFF285C2D),
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            weatherRisk >= 0.45
                                ? 'Monitor your crops closely. Current weather may support disease development.'
                                : 'Current weather conditions are relatively favorable for crop health.',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),

                Center(
                  child: Text(
                    _error!,
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // METRIC CARD
  // =============================================================

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE1E7D6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF77904A),
            size: 25,
          ),

          const Spacer(),

          Text(
            value,
            style: GoogleFonts.poppins(
              color: const Color(0xFF285C2D),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // CONDITION CARD
  // =============================================================

  Widget _conditionCard(String condition) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE1E7D6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFE8EFD7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.coronavirus_outlined,
              color: Color(0xFF77904A),
              size: 21,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Text(
              condition,
              style: GoogleFonts.poppins(
                color: const Color(0xFF285C2D),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF9AA58B),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // EMPTY CONDITIONS
  // =============================================================

  Widget _emptyConditionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'No specific disease conditions detected.',
        style: GoogleFonts.poppins(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
    );
  }
}