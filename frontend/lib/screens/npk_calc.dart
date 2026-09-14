import 'package:flutter/material.dart';

class NpkCalculatorPage extends StatefulWidget {
  const NpkCalculatorPage({super.key});

  @override
  State<NpkCalculatorPage> createState() => _NpkCalculatorPageState();
}

class _NpkCalculatorPageState extends State<NpkCalculatorPage> {
  final TextEditingController fieldSizeController =
      TextEditingController();

  String selectedCrop = 'Wheat';
  String selectedStage = 'Initial Growth';

  final List<String> crops = [
    'Wheat',
    'Rice',
    'Sugarcane',
    'Cotton',
  ];

  final List<String> stages = [
    'Initial Growth',
    'Mid Growth',
    'Flowering',
    'Harvest',
  ];

  final Map<String, Map<String, double>> cropNpk = {
    'Wheat': {
      'N': 120,
      'P': 60,
      'K': 40,
    },
    'Rice': {
      'N': 100,
      'P': 50,
      'K': 50,
    },
    'Sugarcane': {
      'N': 150,
      'P': 70,
      'K': 100,
    },
    'Cotton': {
      'N': 100,
      'P': 50,
      'K': 50,
    },
  };

  final Map<String, double> growthFactors = {
    'Initial Growth': 0.60,
    'Mid Growth': 0.80,
    'Flowering': 1.00,
    'Harvest': 0.30,
  };

  void _calculate() {
    final fieldSize =
        double.tryParse(fieldSizeController.text.trim());

    if (fieldSize == null || fieldSize <= 0) {
      _showError('Please enter a valid field size.');
      return;
    }

    final base = cropNpk[selectedCrop]!;
    final factor = growthFactors[selectedStage]!;

    final nitrogen = base['N']! * fieldSize * factor;
    final phosphorus = base['P']! * fieldSize * factor;
    final potassium = base['K']! * fieldSize * factor;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NpkResultPage(
          crop: selectedCrop,
          stage: selectedStage,
          fieldSize: fieldSize,
          nitrogen: nitrogen,
          phosphorus: phosphorus,
          potassium: potassium,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7EF),
        elevation: 0,
        foregroundColor: const Color(0xFF263626),
        title: const Text(
          'NPK Calculator',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            18,
            10,
            18,
            100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(),

              const SizedBox(height: 18),

              _buildInputCard(),

              const SizedBox(height: 18),

              _buildNpkInfo(),

              const SizedBox(height: 20),

              _buildCalculateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
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
            Color(0xFF678750),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 7),
            color: Colors.black12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.science_outlined,
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
                  'Smart NPK Calculator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Estimate nutrient requirements according to crop and growth stage.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
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
          const Text(
            'Field Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263626),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Crop',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

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
            items: crops.map((crop) {
              return DropdownMenuItem(
                value: crop,
                child: Text(crop),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedCrop = value;
              });
            },
          ),

          const SizedBox(height: 18),

          const Text(
            'Field Size',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: fieldSizeController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              hintText: 'Enter field size',
              suffixText: 'hectare',
              prefixIcon: const Icon(
                Icons.landscape_outlined,
                color: Color(0xFF355E3B),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F7EF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Growth Stage',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: selectedStage,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.timeline,
                color: Color(0xFF355E3B),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F7EF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            items: stages.map((stage) {
              return DropdownMenuItem(
                value: stage,
                child: Text(stage),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedStage = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNpkInfo() {
    final values = cropNpk[selectedCrop]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2E6),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Color(0xFF355E3B),
              ),
              SizedBox(width: 8),
              Text(
                'Recommended Base Nutrients',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF29452B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          Row(
            children: [
              Expanded(
                child: _nutrientBox(
                  'N',
                  'Nitrogen',
                  values['N']!,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _nutrientBox(
                  'P',
                  'Phosphorus',
                  values['P']!,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _nutrientBox(
                  'K',
                  'Potassium',
                  values['K']!,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            'Current growth factor: ${growthFactors[selectedStage]!.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF58705A),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutrientBox(
    String symbol,
    String name,
    double value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            symbol,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: Color(0xFF355E3B),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${value.toStringAsFixed(0)} kg/ha',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.calculate_outlined),
        label: const Text(
          'Calculate Nutrient Requirement',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF355E3B),
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  @override
  void dispose() {
    fieldSizeController.dispose();
    super.dispose();
  }
}


class NpkResultPage extends StatelessWidget {
  final String crop;
  final String stage;
  final double fieldSize;
  final double nitrogen;
  final double phosphorus;
  final double potassium;

  const NpkResultPage({
    super.key,
    required this.crop,
    required this.stage,
    required this.fieldSize,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
  });

  @override
  Widget build(BuildContext context) {
    final total = nitrogen + phosphorus + potassium;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7EF),
        elevation: 0,
        foregroundColor: const Color(0xFF263626),
        title: const Text(
          'NPK Result',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            18,
            10,
            18,
            40,
          ),
          child: Column(
            children: [
              _buildSuccessCard(),

              const SizedBox(height: 18),

              _buildSummaryCard(),

              const SizedBox(height: 18),

              _buildNutrientCard(
                'Nitrogen',
                'N',
                nitrogen,
                Icons.grass,
              ),

              const SizedBox(height: 12),

              _buildNutrientCard(
                'Phosphorus',
                'P',
                phosphorus,
                Icons.spa_outlined,
              ),

              const SizedBox(height: 12),

              _buildNutrientCard(
                'Potassium',
                'K',
                potassium,
                Icons.eco_outlined,
              ),

              const SizedBox(height: 18),

              _buildDisclaimer(),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF355E3B),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(17),
                    ),
                  ),
                  child: const Text(
                    'Calculate Again',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF355E3B),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 52,
          ),
          SizedBox(height: 12),
          Text(
            'Nutrient Plan Generated',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Estimated nutrient requirements for your field',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        children: [
          _summaryRow(
            Icons.eco_outlined,
            'Crop',
            crop,
          ),
          const Divider(height: 24),
          _summaryRow(
            Icons.landscape_outlined,
            'Field Size',
            '${fieldSize.toStringAsFixed(2)} hectare',
          ),
          const Divider(height: 24),
          _summaryRow(
            Icons.timeline,
            'Growth Stage',
            stage,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF355E3B),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientCard(
    String name,
    String symbol,
    double amount,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2E6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF355E3B),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '$name ($symbol)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Estimated requirement',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '${amount.toStringAsFixed(1)} kg',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF355E3B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFFE65100),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'These are estimated nutrient requirements. Soil testing and local agricultural expert recommendations should be used before applying fertilizer.',
              style: TextStyle(
                color: Color(0xFF704214),
                height: 1.4,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}