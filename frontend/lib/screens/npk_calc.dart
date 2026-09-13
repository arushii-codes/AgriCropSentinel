import 'package:flutter/material.dart';

// --- Main App Entry Point ---
void main() {
  runApp(const MyApp());
}

// --- Color Constants ---
const Color primaryGreen = Color(0xFF5C8D6D); // Muted green
const Color backgroundGrey = Color(0xFFF0F2F5);
const Color textDark = Color(0xFF333333);
const Color textLight = Color(0xFF666666);

// --- App Widget ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NPK Calculator',
      theme: ThemeData(
        scaffoldBackgroundColor: backgroundGrey,
        fontFamily:
            'Poppins', // Make sure to add the Poppins font in pubspec.yaml
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: textDark),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen),
        useMaterial3: true,
      ),
      home: const NpkCalculatorPage(),
    );
  }
}

// --- NPK Calculator Page Widget ---
class NpkCalculatorPage extends StatefulWidget {
  const NpkCalculatorPage({super.key});

  @override
  State<NpkCalculatorPage> createState() => _NpkCalculatorPageState();
}

class _NpkCalculatorPageState extends State<NpkCalculatorPage> {
  // State variables for dropdowns
  String? selectedState;
  String? selectedCrop;
  String? selectedGrowthStage = 'Initial Growth';

  // Dummy data for dropdown options
  final List<String> states = [
    'Haryana',
    'Punjab',
    'Uttar Pradesh',
    'Rajasthan',
  ];
  final List<String> crops = ['Wheat', 'Rice', 'Sugarcane', 'Cotton'];
  final List<String> growthStages = [
    'Initial Growth',
    'Mid Growth',
    'Flowering',
    'Harvest',
  ];

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildCustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(Icons.grass, 'Crop & Location Details'),
                const SizedBox(height: 24),
                _buildDropdown(
                  label: 'State',
                  hint: 'Select your state',
                  value: selectedState,
                  items: states,
                  onChanged: (value) => setState(() => selectedState = value),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Crop Type',
                  hint: 'Select crop',
                  value: selectedCrop,
                  items: crops,
                  onChanged: (value) => setState(() => selectedCrop = value),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Field Size (hectares)',
                  hint: 'Enter field size',
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Growth Stage',
                  value: selectedGrowthStage,
                  items: growthStages,
                  onChanged: (value) =>
                      setState(() => selectedGrowthStage = value),
                ),
                const SizedBox(height: 32),
                _buildCalculateButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Custom AppBar with Back Button Logic ---
  AppBar _buildCustomAppBar() {
    return AppBar(
      backgroundColor: backgroundGrey,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: textDark),
        onPressed: () {
          Navigator.pop(context); // Back button logic
        },
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calculate, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NPK Calculator',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: textDark,
                ),
              ),
              Text(
                'Smart Fertilizer Dosage Calculator',
                style: TextStyle(fontSize: 12, color: textLight),
              ),
            ],
          ),
        ],
      ),
      elevation: 0,
    );
  }

  // --- Section Title Widget ---
  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        const Spacer(),
        const Icon(Icons.keyboard_arrow_up, color: textDark),
      ],
    );
  }

  // --- Dropdown Widget ---
  Widget _buildDropdown({
    required String label,
    String? hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: textDark,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint ?? '', style: const TextStyle(color: textLight)),
          icon: const Icon(Icons.keyboard_arrow_down, color: textDark),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGreen, width: 2.0),
            ),
          ),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // --- Text Field Widget ---
  Widget _buildTextField({required String label, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: textDark,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: textLight),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryGreen, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  // --- Calculate Button ---
  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Add calculation logic here
          print('Calculating...');
        },
        icon: const Icon(Icons.calculate_outlined, color: Colors.white),
        label: const Text(
          'Calculate NPK Requirements',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
