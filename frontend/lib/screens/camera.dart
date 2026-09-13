import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

class AnalysisResult {
  final String predictedClass;
  final String detailedInfo;
  final String cause;
  final String cure;
  final String riskLevel;
  final String urgency;
  final List<String> ipmSteps;
  final String? voiceUrl;

  AnalysisResult({
    required this.predictedClass,
    required this.detailedInfo,
    required this.cause,
    required this.cure,
    required this.riskLevel,
    required this.urgency,
    required this.ipmSteps,
    this.voiceUrl,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final analysis = json['analysis_result'] ?? {};
    final predicted = analysis['predicted_class'] ?? json['predicted_class'] ?? 'Healthy / Unknown';
    final info = json['detailed_info'] ?? json['summary_text'] ?? '';
    final cause = analysis['cause'] ?? '';
    final cure = analysis['cure'] ?? '';
    
    final riskFusion = json['risk_fusion'] ?? {};
    final riskLevel = riskFusion['risk_level'] ?? 'medium';
    final urgency = riskFusion['urgency'] ?? 'Monitor crop';

    final ipm = json['ipm_advisory'] ?? {};
    final stepsList = (ipm['ipm_steps'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    final voiceUrl = json['voice_url'];

    return AnalysisResult(
      predictedClass: predicted.toString(),
      detailedInfo: info.toString(),
      cause: cause.toString(),
      cure: cure.toString(),
      riskLevel: riskLevel.toString(),
      urgency: urgency.toString(),
      ipmSteps: stepsList,
      voiceUrl: voiceUrl?.toString(),
    );
  }
}

enum ScreenState { initial, imageSelected, loading, result }

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  ScreenState _currentState = ScreenState.initial;
  XFile? _selectedImage;
Uint8List? _selectedImageBytes;
  AnalysisResult? _analysisResult;

  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();
  
  // Update API URL base if running on physical device vs emulator
  final String apiUrl = "http://127.0.0.1:8000/image-analysis/analyze";
Future<void> _pickImage(ImageSource source) async {
  try {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();

      setState(() {
        _selectedImage = pickedFile;
        _selectedImageBytes = bytes;
        _currentState = ScreenState.imageSelected;
      });
    }
  } catch (e) {
    _showErrorSnackbar('Failed to pick image: $e');
  }
}
Future<void> _analyzeImage() async {
  if (_selectedImage == null || _selectedImageBytes == null) return;

  setState(() => _currentState = ScreenState.loading);

  try {
    final fileName = _selectedImage!.name;

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        _selectedImageBytes!,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
  apiUrl,
  data: formData,
);

    if (response.statusCode == 200) {
      setState(() {
        _analysisResult = AnalysisResult.fromJson(response.data);
        _currentState = ScreenState.result;
      });
    } else {
      _handleError(
        "Analysis failed. Server returned: ${response.statusCode}",
      );
    }
  } on DioException catch (e) {
    _handleError("Network Error: ${e.message}");
  } catch (e) {
    _handleError("An unexpected error occurred: $e");
  }
}
  void _handleError(String message) {
    setState(() => _currentState = ScreenState.imageSelected);
    _showErrorSnackbar(message);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _resetState() {
  setState(() {
    _selectedImage = null;
    _selectedImageBytes = null;
    _analysisResult = null;
    _currentState = ScreenState.initial;
  });
}

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plant Disease & IPM Scanner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF9FAF8),
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: switch (_currentState) {
            ScreenState.initial => _buildInitialUI(),
            ScreenState.imageSelected => _buildImagePreviewUI(),
            ScreenState.loading => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  SizedBox(height: 16),
                  Text("Analyzing leaf & calculating IPM risk...", style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ScreenState.result => _buildResultUI(),
          },
        ),
      ),
    );
  }

  Widget _buildInitialUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.cloud_upload_outlined,
          color: Color(0xFF2E7D32),
          size: 80,
        ),
        const SizedBox(height: 20),
        const Text(
          'Upload Plant Image',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          'Take or select a clear photo of an affected leaf to detect diseases, risk levels, and IPM treatments.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.gallery),
          icon: const Icon(Icons.photo_library),
          label: const Text('Choose from Gallery'),
          style: _buttonStyle(),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.camera),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Use Camera'),
          style: _buttonStyle(isPrimary: false),
        ),
      ],
    );
  }

  Widget _buildImagePreviewUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Image Selected",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
  _selectedImageBytes!,
  fit: BoxFit.contain,
),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _analyzeImage,
          icon: const Icon(Icons.biotech),
          label: const Text('Detect Disease & IPM Risk'),
          style: _buttonStyle(),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _resetState,
          child: const Text('Select Different Image'),
        ),
      ],
    );
  }

  Widget _buildResultUI() {
    if (_analysisResult == null) return _buildInitialUI();

    final riskColor = _getRiskColor(_analysisResult!.riskLevel);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Diagnostic Results 🌿",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: riskColor, width: 1.5),
                ),
                child: Text(
                  _analysisResult!.riskLevel.toUpperCase(),
                  style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: Image.memory(
    _selectedImageBytes!,
    height: 180,
    width: double.infinity,
    fit: BoxFit.cover,
  ),
),
          const SizedBox(height: 16),
          _buildResultCard(
            icon: Icons.bug_report,
            iconColor: Colors.red.shade700,
            title: "Detected Diagnosis",
            content: _analysisResult!.predictedClass.replaceAll('_', ' '),
          ),
          _buildResultCard(
            icon: Icons.warning_amber_rounded,
            iconColor: riskColor,
            title: "Urgency Action",
            content: _analysisResult!.urgency,
          ),
          if (_analysisResult!.cure.isNotEmpty)
            _buildResultCard(
              icon: Icons.healing,
              iconColor: const Color(0xFF2E7D32),
              title: "Primary Treatment & Cure",
              content: _analysisResult!.cure,
            ),
          if (_analysisResult!.ipmSteps.isNotEmpty)
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text(
                          "Integrated Pest Management (IPM)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    ..._analysisResult!.ipmSteps.map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                          Expanded(child: Text(step, style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          _buildResultCard(
            icon: Icons.psychology_outlined,
            iconColor: Colors.purple.shade700,
            title: "Gemini AI Agricultural Advisory",
            content: _analysisResult!.detailedInfo,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _resetState,
            icon: const Icon(Icons.refresh),
            label: const Text("Scan Another Plant"),
            style: _buttonStyle(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(content, style: const TextStyle(fontSize: 14, height: 1.3)),
          ],
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle({bool isPrimary = true}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isPrimary ? const Color(0xFF2E7D32) : Colors.white,
      foregroundColor: isPrimary ? Colors.white : const Color(0xFF2E7D32),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF2E7D32)),
      ),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
