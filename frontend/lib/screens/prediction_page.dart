import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  String selectedCrop = 'Wheat';
  String selectedState = 'Haryana';

  bool loading = false;
  String? errorMessage;

  Map<String, dynamic>? predictionData;

  final List<String> crops = [
    'Wheat',
    'Rice',
    'Maize',
    'Cotton',
    'Sugarcane',
    'Potato',
    'Tomato',
    'Onion',
    'Apple',
  ];

  Future<void> _loadPrediction() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getPrediction(
        state: selectedState,
        crop: selectedCrop,
      );

      setState(() {
        predictionData =
            response['prediction_data'] ?? response;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Unable to load prediction.';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPrediction();
  }

  @override
  Widget build(BuildContext context) {
    final data = predictionData;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7EF),
        elevation: 0,
        foregroundColor: const Color(0xFF263626),
        title: const Text(
          'Insights & Predictions',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadPrediction,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPrediction,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),

                const SizedBox(height: 18),

                _buildCropSelector(),

                const SizedBox(height: 18),

                if (loading)
                  _buildLoading()
                else if (errorMessage != null)
                  _buildError()
                else if (data != null) ...[
                  _buildCurrentPriceCard(data),

                  const SizedBox(height: 15),

                  _buildTrendCard(data),

                  const SizedBox(height: 15),

                  _buildForecastCard(data),

                  const SizedBox(height: 15),

                  _buildWeatherImpactCard(data),

                  const SizedBox(height: 15),

                  _buildRecommendationCard(data),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF355E3B),
            Color(0xFF64844F),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 15,
            offset: Offset(0, 7),
            color: Colors.black12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_graph,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(width: 15),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Market Intelligence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'AI-powered crop price trends and selling insights.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropSelector() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Crop',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: selectedCrop,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.eco_outlined,
                color: Color(0xFF355E3B),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F7EF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            items: crops
                .map(
                  (crop) => DropdownMenuItem(
                    value: crop,
                    child: Text(crop),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedCrop = value;
              });

              _loadPrediction();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPriceCard(
    Map<String, dynamic> data,
  ) {
    final price = data['current_price'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2E6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.currency_rupee,
              color: Color(0xFF355E3B),
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Market Price',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '₹${_formatNumber(price)}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF263626),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$selectedCrop • $selectedState',
                  style: const TextStyle(
                    color: Color(0xFF6B756B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(
    Map<String, dynamic> data,
  ) {
    final trend = data['trend'] ?? 'Unknown';

    final confidence =
        ((data['confidence'] ?? 0) as num).toDouble();

    final isRising =
        trend.toString().toLowerCase() == 'rising';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isRising
            ? const Color(0xFFEAF2E6)
            : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          Icon(
            isRising
                ? Icons.trending_up
                : Icons.trending_down,
            size: 38,
            color: isRising
                ? const Color(0xFF2E7D32)
                : const Color(0xFFE65100),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Price Trend',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trend,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isRising
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              const Text(
                'Confidence',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${(confidence * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(
    Map<String, dynamic> data,
  ) {
    final forecast =
        data['weekly_forecast'];

    if (forecast is! Map ||
        forecast.isEmpty) {
      return _emptyCard(
        'No weekly forecast available.',
      );
    }

    final entries = forecast.entries.toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.show_chart,
                color: Color(0xFF355E3B),
              ),
              SizedBox(width: 9),
              Text(
                '8-Week Price Forecast',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: List.generate(
                entries.length,
                (index) {
                  final item = entries[index];

                  final value =
                      ((item.value['price'] ?? 0)
                              as num)
                          .toDouble();

                  final maxPrice = entries
                      .map(
                        (e) => ((e.value['price'] ?? 0)
                                as num)
                            .toDouble(),
                      )
                      .reduce(
                        (a, b) => a > b ? a : b,
                      );

                  final barHeight =
                      maxPrice == 0
                          ? 10.0
                          : 135 * value / maxPrice;

                  return Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 3,
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        children: [
                          Text(
                            '₹${value.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF6B8E5E,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                8,
                              ),
                            ),
                          ),

                          const SizedBox(height: 7),

                          Text(
                            'W${index + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherImpactCard(
    Map<String, dynamic> data,
  ) {
    final impact =
        data['weather_impact'] ??
            'Weather impact information unavailable.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1F7),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.cloud_outlined,
                color: Color(0xFF456B82),
              ),
              SizedBox(width: 9),
              Text(
                'Weather Impact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            impact.toString(),
            style: const TextStyle(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
    Map<String, dynamic> data,
  ) {
    final recommendation =
        data['recommendation'] ??
            'Monitor market conditions regularly.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF355E3B),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.white,
              ),
              SizedBox(width: 9),
              Text(
                'AI Recommendation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Text(
            recommendation.toString(),
            style: const TextStyle(
              color: Colors.white,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white70,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Predictions are estimates. Always consider local mandi prices and expert advice.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            color: Color(0xFF355E3B),
          ),
          SizedBox(height: 15),
          Text(
            'Generating market insights...',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off,
            size: 45,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _loadPrediction,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF355E3B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.grey,
        ),
      ),
    );
  }

  String _formatNumber(dynamic value) {
    final number =
        double.tryParse(value.toString()) ?? 0;

    return number
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }
}