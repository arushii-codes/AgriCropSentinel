import 'package:flutter/material.dart';

// --- Main App Entry Point ---
void main() {
  runApp(const MyApp());
}

// --- Color Constants ---
const Color primaryGreen = Color(0xFF2C7D43);
const Color backgroundGrey = Color(0xFFF0F2F5);
const Color cardGrey = Color(0xFFE9ECEF);
const Color textDark = Color(0xFF333333);
const Color textLight = Color(0xFF666666);
const Color lightGreenPill = Color(0xFFD4E9DB);

// --- App Widget ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NPK Results',
      theme: ThemeData(
        scaffoldBackgroundColor: backgroundGrey,
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundGrey,
          elevation: 0,
          iconTheme: IconThemeData(color: textDark),
          titleTextStyle: TextStyle(
            color: textDark,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen),
        useMaterial3: true,
      ),
      home: const ResultsPageStyle2(),
    );
  }
}

// --- Results Page Widget ---
class ResultsPageStyle2 extends StatelessWidget {
  const ResultsPageStyle2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NPK Requirements & Recommendations'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Add navigation logic if needed
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: cardGrey,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            children: [
              _buildSection(
                icon: Icons.scale_outlined,
                title: 'NPK Requirements (per hectare)',
                child: _buildNpkValues(),
              ),
              const SizedBox(height: 24),
              _buildSection(
                icon: Icons.bar_chart_outlined,
                title: 'Fertilizer Recommendations',
                child: _buildFertilizerRecommendations(),
              ),
              const SizedBox(height: 24),
              _buildSection(
                icon: Icons.water_drop_outlined,
                title: 'Irrigation Analysis',
                child: _buildIrrigationAnalysis(),
              ),
              const SizedBox(height: 24),
              _buildWeatherData(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: textDark, size: 28),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildNpkValues() {
    return Row(
      children: [
        _npkValueCard('Nitrogen (N)', '120'),
        const SizedBox(width: 12),
        _npkValueCard('Phosphorus (P)', '60'),
        const SizedBox(width: 12),
        _npkValueCard('Potassium (K)', '90'),
      ],
    );
  }

  Widget _npkValueCard(String nutrient, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              nutrient,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 4),
            const Text('kg/ha', style: TextStyle(color: textLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildFertilizerRecommendations() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Per Hectare',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _fertilizerItem('Urea', '50 kg/ha'),
              const SizedBox(height: 8),
              _fertilizerItem('DAP', '25 kg/ha'),
              const SizedBox(height: 8),
              _fertilizerItem('MOP', '30 kg/ha'),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total for Your Field (5 ha)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _fertilizerItem('Urea', '250 kg'),
              const SizedBox(height: 8),
              _fertilizerItem('DAP', '125 kg'),
              const SizedBox(height: 8),
              _fertilizerItem('MOP', '150 kg'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fertilizerItem(String name, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: lightGreenPill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIrrigationAnalysis() {
    return Column(
      children: [
        _irrigationItem('ETo (Reference)', '4.5 mm/day'),
        const Divider(height: 24),
        _irrigationItem('ETc (Crop)', '3.2 mm/day'),
        const Divider(height: 24),
        _irrigationItem('Current Rainfall', '0.8 mm'),
        const Divider(height: 24),
        _irrigationItem('Irrigation Needed', '2.4 mm', isHighlighted: true),
      ],
    );
  }

  Widget _irrigationItem(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textLight,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlighted ? primaryGreen : textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherData() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Weather Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Data from NASA POWER API.',
                style: TextStyle(color: textLight, fontSize: 12),
              ),
            ],
          ),
          Icon(
            Icons.wb_sunny_outlined,
            color: Colors.orange.shade600,
            size: 32,
          ),
        ],
      ),
    );
  }
}
