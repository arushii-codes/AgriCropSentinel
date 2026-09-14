import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const String backendUrl = 'http://localhost:8000';

  final ImagePicker _picker = ImagePicker();
  final FlutterTts _tts = FlutterTts();

  Uint8List? _imageBytes;
  Map<String, dynamic>? _result;

  bool _loading = false;
  bool _speaking = false;

  String _selectedLanguage = 'hi';

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      setState(() {
        _imageBytes = bytes;
        _result = null;
      });

      await _analyzeImage();
    } catch (e) {
      _showError('Unable to select image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) return;

    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '$backendUrl/vision/analyze'
          '?voice=true'
          '&lang=$_selectedLanguage',
        ),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _imageBytes!,
          filename: 'crop_image.jpg',
        ),
      );

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _result = data;
        });
      } else {
        throw Exception(
          'Server returned ${response.statusCode}',
        );
      }
    } catch (e) {
      _showError('Disease analysis failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _speakResult() async {
    if (_result == null) return;

    final analysis = _result!['analysis_result'];

    final disease =
        analysis?['predicted_class'] ?? 'Unknown disease';

    final confidence =
        ((analysis?['confidence'] ?? 0) * 100).toStringAsFixed(1);

    final risk =
        _result!['risk_fusion']?['risk_level'] ?? 'Unknown';

    final text =
        'Crop health analysis complete. '
        'Detected condition: $disease. '
        'Confidence: $confidence percent. '
        'Risk level: $risk.';

    try {
      setState(() {
        _speaking = true;
      });

      await _tts.setLanguage(
        _selectedLanguage == 'pa'
            ? 'pa-IN'
            : _selectedLanguage == 'hi'
                ? 'hi-IN'
                : 'en-IN',
      );

      await _tts.setSpeechRate(0.45);
      await _tts.speak(text);

      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _speaking = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _speaking = false;
      });
    }
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();

    setState(() {
      _speaking = false;
    });
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return const Color(0xFF2E7D32);
      case 'medium':
        return const Color(0xFFF9A825);
      case 'high':
        return const Color(0xFFE65100);
      case 'critical':
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  IconData _riskIcon(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return Icons.check_circle;
      case 'medium':
        return Icons.warning_amber_rounded;
      case 'high':
        return Icons.warning;
      case 'critical':
        return Icons.dangerous;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _result?['analysis_result'];
    final fusion = _result?['risk_fusion'];
    final advisory = _result?['ipm_advisory'];

    final disease =
        analysis?['predicted_class'] ?? '';

    final confidence =
        ((analysis?['confidence'] ?? 0) as num).toDouble();

    final risk =
        fusion?['risk_level'] ?? '';

    final score =
        ((fusion?['fused_risk_score'] ?? 0) as num).toDouble();

    final urgency =
        fusion?['urgency'] ?? '';

    final cause =
        analysis?['cause'] ?? '';

    final cure =
        analysis?['cure'] ?? '';

    final ipmSteps =
        advisory?['ipm_steps'] is List
            ? List<String>.from(advisory['ipm_steps'])
            : <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7EF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F7EF),
        foregroundColor: const Color(0xFF243B24),
        title: const Text(
          'Crop Health',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLanguage,
                items: const [
                  DropdownMenuItem(
                    value: 'en',
                    child: Text('EN'),
                  ),
                  DropdownMenuItem(
                    value: 'hi',
                    child: Text('हिं'),
                  ),
                  DropdownMenuItem(
                    value: 'pa',
                    child: Text('ਪੰ'),
                  ),
                ],
                onChanged: (value) async {
                  if (value == null) return;

                  setState(() {
                    _selectedLanguage = value;
                  });

                  if (_imageBytes != null) {
                    await _analyzeImage();
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroCard(),

              const SizedBox(height: 20),

              if (_imageBytes != null)
                _buildImagePreview(),

              const SizedBox(height: 18),

              if (_imageBytes == null)
                _buildUploadCard(),

              if (_loading)
                _buildLoadingCard(),

              if (_result != null && !_loading) ...[
                _buildDetectionCard(
                  disease,
                  confidence,
                ),

                const SizedBox(height: 14),

                _buildRiskCard(
                  risk,
                  score,
                  urgency,
                ),

                const SizedBox(height: 14),

                _buildInfoCard(
                  title: 'What caused it?',
                  icon: Icons.biotech_outlined,
                  text: cause,
                ),

                const SizedBox(height: 14),

                _buildInfoCard(
                  title: 'Recommended treatment',
                  icon: Icons.medical_services_outlined,
                  text: cure,
                ),

                const SizedBox(height: 14),

                if (ipmSteps.isNotEmpty)
                  _buildIpmCard(ipmSteps),

                const SizedBox(height: 16),

                _buildVoiceButton(),
              ],

              if (_imageBytes != null && !_loading)
                const SizedBox(height: 12),

              if (_imageBytes != null && !_loading)
                _buildRetakeButton(),
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
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF355E3B),
            Color(0xFF567D46),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
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
              Icons.eco,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Crop Diagnosis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Upload a leaf image to detect diseases and assess crop risk.',
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

  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFDDE5D8),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2E6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_a_photo_outlined,
              size: 38,
              color: Color(0xFF355E3B),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Upload Crop Image',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263626),
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Take a clear photo of the affected leaf',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF355E3B),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xFF355E3B),
                    padding:
                        const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(
                      color: Color(0xFF355E3B),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 270,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.grey.shade200,
      ),
      child: Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            color: Color(0xFF355E3B),
          ),
          SizedBox(height: 16),
          Text(
            'Analyzing crop health...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Checking disease, weather and risk factors',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionCard(
    String disease,
    double confidence,
  ) {
    final percentage =
        (confidence * 100).toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.search,
                color: Color(0xFF355E3B),
              ),
              SizedBox(width: 8),
              Text(
                'AI Detection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            _formatDiseaseName(disease),
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263626),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Confidence',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 9,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF5B8C51),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCard(
    String risk,
    double score,
    String urgency,
  ) {
    final color = _riskColor(risk);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _riskIcon(risk),
                color: color,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text(
                'Overall Crop Risk',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                risk.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${(score * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: score.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor:
                  color.withOpacity(0.12),
              color: color,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Icon(
                Icons.bolt,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  urgency,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF355E3B),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            text.isEmpty
                ? 'Information unavailable.'
                : text,
            style: const TextStyle(
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIpmCard(List<String> steps) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2E6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: Color(0xFF355E3B),
              ),
              SizedBox(width: 9),
              Text(
                'Recommended IPM',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF29452B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ...List.generate(
            steps.length,
            (index) {
              return Padding(
                padding:
                    const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 27,
                      height: 27,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF355E3B),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        steps[index],
                        style: const TextStyle(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            _speaking ? _stopSpeaking : _speakResult,
        icon: Icon(
          _speaking
              ? Icons.stop
              : Icons.volume_up_outlined,
        ),
        label: Text(
          _speaking
              ? 'Stop Voice'
              : 'Listen to Diagnosis',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF355E3B),
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }

  Widget _buildRetakeButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _imageBytes = null;
            _result = null;
          });
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Analyze Another Crop'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF355E3B),
          padding:
              const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(
            color: Color(0xFF355E3B),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }

  String _formatDiseaseName(String value) {
    if (value.isEmpty) return 'No disease detected';

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

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}