import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // ============================================================
  // BACKEND
  // ============================================================

  static const String backendUrl = 'https://jslkprxq-8000.inc1.devtunnels.ms';

  // ============================================================
  // SERVICES
  // ============================================================

  final ImagePicker _picker = ImagePicker();
  final FlutterTts _tts = FlutterTts();

  // ============================================================
  // STATE
  // ============================================================

  Uint8List? _imageBytes;

  Map<String, dynamic>? _result;

  bool _loading = false;
  bool _speaking = false;
  bool _gettingLocation = false;

  String _selectedLanguage = 'hi';
  String _selectedGrowthStage = 'vegetative';

  double? _latitude;
  double? _longitude;

  int _nearbyCases = 0;

  // Default location used if browser/device location is unavailable.
  static const double defaultLatitude = 29.9695;
  static const double defaultLongitude = 76.8783;

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _gettingLocation = true;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _setDefaultLocation(
          'Location service is disabled. Using default field location.',
        );
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setDefaultLocation(
          'Location permission denied. Using default field location.',
        );
        return;
      }

      // Compatible with geolocator 10.1.1.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      debugPrint(
        '[LOCATION] lat=${position.latitude}, '
        'lon=${position.longitude}',
      );
    } catch (e) {
      debugPrint('[LOCATION ERROR] $e');

      _setDefaultLocation(
        'Unable to get current location. Using default field location.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }
    }
  }

  void _setDefaultLocation(String message) {
    if (!mounted) return;

    setState(() {
      _latitude = defaultLatitude;
      _longitude = defaultLongitude;
    });

    _showMessage(message);
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _result = null;
      });

      await _getCurrentLocation();
      await _analyzeImage();
    } catch (e) {
      debugPrint('[IMAGE PICK ERROR] $e');

      _showMessage(
        'Unable to select image: $e',
      );
    }
  }

  // ============================================================
  // ANALYZE IMAGE
  // ============================================================

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) return;

    if (!mounted) return;

    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      if (_latitude == null || _longitude == null) {
        await _getCurrentLocation();
      }

      final lat = _latitude ?? defaultLatitude;
      final lon = _longitude ?? defaultLongitude;

      final uri = Uri.parse(
        '$backendUrl/vision/analyze',
      ).replace(
        queryParameters: {
          'voice': 'false',
          'lang': _selectedLanguage,
          'growth_stage': _selectedGrowthStage,
          'nearby_cases': _nearbyCases.toString(),
          'lat': lat.toString(),
          'lon': lon.toString(),
        },
      );

      debugPrint('[ANALYZE] POST $uri');

      final request = http.MultipartRequest(
        'POST',
        uri,
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _imageBytes!,
          filename: 'crop_image.jpg',
        ),
      );

      final streamedResponse = await request.send();

      final response =
          await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint(
        '[ANALYZE] STATUS: ${response.statusCode}',
      );

      debugPrint(
        '[ANALYZE] RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        String errorMessage =
            'Server error: ${response.statusCode}';

        try {
          final errorData = jsonDecode(
            response.body,
          );

          if (errorData is Map &&
              errorData['detail'] != null) {
            errorMessage =
                errorData['detail'].toString();
          }
        } catch (_) {}

        throw Exception(errorMessage);
      }

      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is! Map) {
        throw Exception(
          'Invalid response received from backend.',
        );
      }

      if (!mounted) return;

      setState(() {
        _result =
            Map<String, dynamic>.from(decoded);
      });

      debugPrint(
        '[ANALYZE SUCCESS] result received',
      );
    } catch (e) {
      debugPrint('[ANALYZE ERROR] $e');

      _showMessage(
        'Disease analysis failed: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // VOICE
  // ============================================================

  Future<void> _speakResult() async {
    if (_result == null) return;

    final analysis =
        _result!['analysis_result'];

    final fusion =
        _result!['risk_fusion'];

    String disease = 'Unknown disease';
    String confidence = '0';
    String risk = 'Unknown';
    String urgency = '';

    if (analysis is Map) {
      disease =
          analysis['predicted_class']?.toString() ??
              'Unknown disease';

      final confidenceRaw =
          analysis['confidence'];

      if (confidenceRaw is num) {
        confidence =
            (confidenceRaw * 100)
                .toStringAsFixed(1);
      }
    }

    if (fusion is Map) {
      risk =
          fusion['risk_level']?.toString() ??
              'Unknown';

      urgency =
          fusion['urgency']?.toString() ?? '';
    }

    final text =
        'Crop health analysis complete. '
        'Detected condition: $disease. '
        'Confidence: $confidence percent. '
        'Overall risk level: $risk. '
        '$urgency';

    try {
      if (!mounted) return;

      setState(() {
        _speaking = true;
      });

      String ttsLanguage;

      if (_selectedLanguage == 'hi') {
        ttsLanguage = 'hi-IN';
      } else if (_selectedLanguage == 'pa') {
        ttsLanguage = 'pa-IN';
      } else {
        ttsLanguage = 'en-IN';
      }

      await _tts.setLanguage(ttsLanguage);
      await _tts.setSpeechRate(0.45);

      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _speaking = false;
          });
        }
      });

      await _tts.speak(text);
    } catch (e) {
      debugPrint('[TTS ERROR] $e');

      if (mounted) {
        setState(() {
          _speaking = false;
        });
      }
    }
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();

    if (mounted) {
      setState(() {
        _speaking = false;
      });
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // RISK COLOR
  // ============================================================

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

  // ============================================================
  // RISK ICON
  // ============================================================

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final analysisRaw =
        _result?['analysis_result'];

    final fusionRaw =
        _result?['risk_fusion'];

    String disease = '';

    double confidence = 0.0;

    String risk = '';

    double score = 0.0;

    String urgency = '';

    String cause = '';

    String cure = '';

    // ----------------------------------------------------------
    // ANALYSIS RESULT
    // ----------------------------------------------------------

    if (analysisRaw is Map) {
      final analysis =
          Map<String, dynamic>.from(
        analysisRaw,
      );

      disease =
          analysis['predicted_class']?.toString() ??
              analysis['disease_or_pest_name']
                  ?.toString() ??
              '';

      final confidenceRaw =
          analysis['confidence'];

      if (confidenceRaw is num) {
        confidence =
            confidenceRaw.toDouble();

        if (confidence > 1.0) {
          confidence =
              confidence / 100.0;
        }
      }

      cause =
          analysis['cause']?.toString() ?? '';

      cure =
          analysis['cure']?.toString() ?? '';
    }

    // ----------------------------------------------------------
    // FUSION RESULT
    // ----------------------------------------------------------

    if (fusionRaw is Map) {
      final fusion =
          Map<String, dynamic>.from(
        fusionRaw,
      );

      risk =
          fusion['risk_level']?.toString() ??
              '';

      final scoreRaw =
          fusion['fused_risk_score'];

      if (scoreRaw is num) {
        score = scoreRaw.toDouble();

        if (score > 1.0) {
          score = score / 100.0;
        }
      }

      urgency =
          fusion['urgency']?.toString() ??
              '';
    }

    // ----------------------------------------------------------
    // IPM
    // ----------------------------------------------------------

    final ipmSteps =
        _extractIpmSteps();

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7EF),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            const Color(0xFFF5F7EF),
        foregroundColor:
            const Color(0xFF243B24),

        title: const Text(
          'Crop Health',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),

        actions: [
          Padding(
            padding:
                const EdgeInsets.only(
              right: 12,
            ),

            child:
                DropdownButtonHideUnderline(
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

                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _selectedLanguage = value;
                  });

                  if (_imageBytes != null &&
                      !_loading) {
                    _analyzeImage();
                  }
                },
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            110,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              _buildHeroCard(),

              const SizedBox(height: 20),

              _buildGrowthStageSelector(),

              const SizedBox(height: 18),

              if (_imageBytes != null)
                _buildImagePreview(),

              const SizedBox(height: 18),

              if (_imageBytes == null)
                _buildUploadCard(),

              if (_gettingLocation)
                _buildLocationLoadingCard(),

              if (_loading)
                _buildLoadingCard(),

              if (_result != null &&
                  !_loading) ...[
                _buildLocationCard(),

                const SizedBox(height: 14),

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

                _buildFusionFactorsCard(),

                const SizedBox(height: 14),

                _buildInfoCard(
                  title: 'What caused it?',
                  icon:
                      Icons.biotech_outlined,
                  text: cause,
                ),

                const SizedBox(height: 14),

                _buildInfoCard(
                  title:
                      'Recommended treatment',
                  icon: Icons
                      .medical_services_outlined,
                  text: cure,
                ),

                const SizedBox(height: 14),

                // ALWAYS SHOW IPM
                _buildIpmCard(
                  ipmSteps.isNotEmpty
                      ? ipmSteps
                      : _defaultIpmSteps(
                          disease,
                        ),
                ),

                const SizedBox(height: 16),

                _buildVoiceButton(),
              ],

              if (_imageBytes != null &&
                  !_loading) ...[
                const SizedBox(height: 12),
                _buildRetakeButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(28),

        gradient:
            const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [
            Color(0xFF355E3B),
            Color(0xFF567D46),
          ],
        ),

        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 8),
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
              color:
                  Colors.white.withOpacity(
                0.15,
              ),
              borderRadius:
                  BorderRadius.circular(18),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'AI Crop Diagnosis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
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

  // ============================================================
  // GROWTH STAGE
  // ============================================================

  Widget _buildGrowthStageSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color:
              const Color(0xFFDDE5D8),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons.grass,
                color:
                    Color(0xFF355E3B),
              ),

              SizedBox(width: 8),

              Text(
                'Crop Growth Stage',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _selectedGrowthStage,

            decoration:
                InputDecoration(
              filled: true,
              fillColor:
                  const Color(0xFFF5F7EF),

              border:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                borderSide:
                    BorderSide.none,
              ),
            ),

            items: const [
              DropdownMenuItem(
                value: 'seedling',
                child:
                    Text('Seedling'),
              ),
              DropdownMenuItem(
                value: 'vegetative',
                child:
                    Text('Vegetative'),
              ),
              DropdownMenuItem(
                value: 'tillering',
                child:
                    Text('Tillering'),
              ),
              DropdownMenuItem(
                value: 'flowering',
                child:
                    Text('Flowering'),
              ),
              DropdownMenuItem(
                value: 'fruiting',
                child:
                    Text('Fruiting'),
              ),
              DropdownMenuItem(
                value: 'maturity',
                child:
                    Text('Maturity'),
              ),
            ],

            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedGrowthStage =
                    value;
              });

              if (_imageBytes != null &&
                  !_loading) {
                _analyzeImage();
              }
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPLOAD CARD
  // ============================================================

  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(25),

        border: Border.all(
          color:
              const Color(0xFFDDE5D8),
        ),
      ),

      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,

            decoration:
                const BoxDecoration(
              color:
                  Color(0xFFEAF2E6),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons
                  .add_a_photo_outlined,
              size: 38,
              color:
                  Color(0xFF355E3B),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Upload Crop Image',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(0xFF263626),
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Take a clear photo of the affected leaf',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child:
                    ElevatedButton.icon(
                  onPressed: _loading
                      ? null
                      : () =>
                          _pickImage(
                            ImageSource
                                .camera,
                          ),

                  icon: const Icon(
                    Icons.camera_alt,
                  ),

                  label:
                      const Text(
                    'Camera',
                  ),

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF355E3B,
                    ),
                    foregroundColor:
                        Colors.white,

                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 15,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () =>
                          _pickImage(
                            ImageSource
                                .gallery,
                          ),

                  icon: const Icon(
                    Icons
                        .photo_library_outlined,
                  ),

                  label:
                      const Text(
                    'Gallery',
                  ),

                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(
                      0xFF355E3B,
                    ),

                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 15,
                    ),

                    side:
                        const BorderSide(
                      color: Color(
                        0xFF355E3B,
                      ),
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
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

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 270,

      clipBehavior:
          Clip.antiAlias,

      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(25),
        color: Colors.grey.shade200,
      ),

      child: Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
      ),
    );
  }

  // ============================================================
  // LOCATION LOADING
  // ============================================================

  Widget _buildLocationLoadingCard() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        top: 18,
      ),
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,

            child:
                CircularProgressIndicator(
              strokeWidth: 2.5,
              color:
                  Color(0xFF355E3B),
            ),
          ),

          SizedBox(width: 14),

          Expanded(
            child: Text(
              'Getting field location...',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ANALYSIS LOADING
  // ============================================================

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        top: 18,
      ),
      padding:
          const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
      ),

      child: const Column(
        children: [
          CircularProgressIndicator(
            color:
                Color(0xFF355E3B),
          ),

          SizedBox(height: 16),

          Text(
            'Analyzing crop health...',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Checking disease, weather and risk factors',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION CARD
  // ============================================================

  Widget _buildLocationCard() {
    final lat =
        _latitude?.toStringAsFixed(4) ??
            '--';

    final lon =
        _longitude?.toStringAsFixed(4) ??
            '--';

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color:
            const Color(0xFFEAF2E6),
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color:
                Color(0xFF355E3B),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'Field location: $lat, $lon',

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETECTION CARD
  // ============================================================

  Widget _buildDetectionCard(
    String disease,
    double confidence,
  ) {
    final percentage =
        (confidence * 100)
            .toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(23),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons.search,
                color:
                    Color(0xFF355E3B),
              ),

              SizedBox(width: 8),

              Text(
                'AI Detection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            _formatDiseaseName(
              disease,
            ),

            style: const TextStyle(
              fontSize: 23,
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(0xFF263626),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [
              const Text(
                'AI Confidence',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              Text(
                '$percentage%',

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              20,
            ),

            child:
                LinearProgressIndicator(
              value:
                  confidence.clamp(
                0.0,
                1.0,
              ),

              minHeight: 9,

              backgroundColor:
                  Colors.grey.shade200,

              color:
                  const Color(
                0xFF5B8C51,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RISK CARD
  // ============================================================

  Widget _buildRiskCard(
    String risk,
    double score,
    String urgency,
  ) {
    final color =
        _riskColor(risk);

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color:
            color.withOpacity(0.08),

        borderRadius:
            BorderRadius.circular(23),

        border: Border.all(
          color:
              color.withOpacity(0.25),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

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
                  fontWeight:
                      FontWeight.bold,
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
                risk.isEmpty
                    ? 'UNKNOWN'
                    : risk.toUpperCase(),

                style: TextStyle(
                  color: color,
                  fontSize: 30,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const Spacer(),

              Text(
                '${(score * 100).toStringAsFixed(0)}%',

                style: TextStyle(
                  color: color,
                  fontSize: 25,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              20,
            ),

            child:
                LinearProgressIndicator(
              value:
                  score.clamp(
                0.0,
                1.0,
              ),

              minHeight: 10,

              backgroundColor:
                  color.withOpacity(
                0.12,
              ),

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
                  urgency.isEmpty
                      ? 'Monitor crop health regularly.'
                      : urgency,

                  style: TextStyle(
                    color: color,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FUSION FACTORS
  // ============================================================

  Widget _buildFusionFactorsCard() {
    final fusionRaw =
        _result?['risk_fusion'];

    if (fusionRaw is! Map) {
      return const SizedBox.shrink();
    }

    final fusion =
        Map<String, dynamic>.from(
      fusionRaw,
    );

    // ----------------------------------------------------------
    // Normalize numbers
    // ----------------------------------------------------------

    double normalize(dynamic raw) {
      if (raw == null) {
        return 0.0;
      }

      double? value;

      if (raw is num) {
        value = raw.toDouble();
      } else if (raw is String) {
        value = double.tryParse(raw);
      }

      if (value == null) {
        return 0.0;
      }

      if (value > 1.0) {
        value = value / 100.0;
      }

      return value.clamp(
        0.0,
        1.0,
      );
    }

    // ----------------------------------------------------------
    // Search in every likely backend location
    // ----------------------------------------------------------

    dynamic findValue(
      List<String> keys,
    ) {
      // Direct fusion fields
      for (final key in keys) {
        if (fusion.containsKey(key)) {
          return fusion[key];
        }
      }

      // Explanation
      final explanationRaw =
          fusion['explanation'];

      if (explanationRaw is Map) {
        final explanation =
            Map<String, dynamic>.from(
          explanationRaw,
        );

        for (final key in keys) {
          if (explanation.containsKey(key)) {
            return explanation[key];
          }
        }
      }

      // Contributions
      final contributionsRaw =
          fusion['contributions'];

      if (contributionsRaw is Map) {
        final contributions =
            Map<String, dynamic>.from(
          contributionsRaw,
        );

        for (final key in keys) {
          if (contributions.containsKey(key)) {
            return contributions[key];
          }
        }
      }

      // Root response
      for (final key in keys) {
        if (_result?.containsKey(key) ==
            true) {
          return _result![key];
        }
      }

      return null;
    }

    // ----------------------------------------------------------
    // DISEASE CONFIDENCE
    // ----------------------------------------------------------

    dynamic confidenceRaw =
        findValue([
      'cv_confidence',
      'confidence',
      'image_confidence',
      'disease_confidence',
    ]);

    if (confidenceRaw == null) {
      final analysis =
          _result?['analysis_result'];

      if (analysis is Map) {
        confidenceRaw =
            analysis['confidence'];
      }
    }

    final cvConfidence =
        normalize(confidenceRaw);

    // ----------------------------------------------------------
    // IMAGE RELIABILITY
    // ----------------------------------------------------------

    dynamic reliabilityRaw =
        findValue([
      'image_reliability',
      'reliability',
    ]);

    double imageReliability;

    if (reliabilityRaw != null) {
      imageReliability =
          normalize(reliabilityRaw);
    } else {
      // Same reliability logic as backend.
      if (cvConfidence >= 0.80) {
        imageReliability = 1.0;
      } else if (cvConfidence >= 0.60) {
        imageReliability = 0.80;
      } else if (cvConfidence >= 0.40) {
        imageReliability = 0.60;
      } else {
        imageReliability = 0.40;
      }
    }

    // ----------------------------------------------------------
    // WEATHER RISK
    // ----------------------------------------------------------

    dynamic weatherRaw =
        findValue([
      'weather_risk',
      'weather_risk_score',
    ]);

    // Check weather_result
    if (weatherRaw == null) {
      final weather =
          _result?['weather_result'];

      if (weather is Map) {
        weatherRaw =
            weather[
                'weather_risk_score'] ??
            weather['risk_score'] ??
            weather['weather_risk'];
      }
    }

    // Check weather
    if (weatherRaw == null) {
      final weather =
          _result?['weather'];

      if (weather is Map) {
        weatherRaw =
            weather[
                'weather_risk_score'] ??
            weather['risk_score'] ??
            weather['weather_risk'];
      }
    }

    // Check nested weather_data
    if (weatherRaw == null) {
      final weather =
          _result?['weather_data'];

      if (weather is Map) {
        weatherRaw =
            weather[
                'weather_risk_score'] ??
            weather['risk_score'] ??
            weather['weather_risk'];
      }
    }

    final weatherRisk =
        normalize(weatherRaw);

    // ----------------------------------------------------------
    // GROWTH STAGE RISK
    // ----------------------------------------------------------

    dynamic stageRaw =
        findValue([
      'stage_risk',
      'growth_stage_risk',
    ]);

    double stageRisk;

    if (stageRaw != null) {
      stageRisk =
          normalize(stageRaw);
    } else {
      stageRisk =
          _calculateStageRisk();
    }

    // ----------------------------------------------------------
    // NEARBY CASE RISK
    // ----------------------------------------------------------

    dynamic caseRaw =
        findValue([
      'case_risk',
      'nearby_case_risk',
    ]);

    double nearbyCaseRisk;

    if (caseRaw != null) {
      nearbyCaseRisk =
          normalize(caseRaw);
    } else {
      dynamic nearbyCases =
          _result?[
              'nearby_case_count_7d'];

      nearbyCases ??=
          _result?['nearby_cases'];

      nearbyCases ??=
          _nearbyCases;

      if (nearbyCases is num) {
        nearbyCaseRisk =
            (nearbyCases.toDouble() /
                    5.0)
                .clamp(
          0.0,
          1.0,
        );
      } else {
        nearbyCaseRisk = 0.0;
      }
    }

    // ----------------------------------------------------------
    // DEBUG
    // ----------------------------------------------------------

    debugPrint(
      '[FUSION UI] '
      'cv=$cvConfidence '
      'reliability=$imageReliability '
      'weather=$weatherRisk '
      'stage=$stageRisk '
      'cases=$nearbyCaseRisk',
    );

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color:
              const Color(0xFFDDE5D8),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons
                    .psychology_outlined,
                color:
                    Color(0xFF355E3B),
                size: 27,
              ),

              SizedBox(width: 9),

              Text(
                'Why this risk?',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'The overall risk combines AI detection, image reliability, '
            'weather, crop stage and nearby cases.',

            style: TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          _buildFactor(
            'Disease confidence',
            cvConfidence,
          ),

          _buildFactor(
            'Image reliability',
            imageReliability,
          ),

          _buildFactor(
            'Weather risk',
            weatherRisk,
          ),

          _buildFactor(
            'Growth-stage risk',
            stageRisk,
          ),

          _buildFactor(
            'Nearby case risk',
            nearbyCaseRisk,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAGE RISK
  // ============================================================

  double _calculateStageRisk() {
    final stage =
        _selectedGrowthStage
            .toLowerCase();

    const stageValues = {
      'seedling': 0.60,
      'vegetative': 0.50,
      'tillering': 0.65,
      'flowering': 0.85,
      'fruiting': 0.90,
      'maturity': 0.70,
    };

    return stageValues[stage] ??
        0.50;
  }

  // ============================================================
  // FACTOR BAR
  // ============================================================

  Widget _buildFactor(
    String title,
    double value,
  ) {
    final safeValue =
        value.clamp(0.0, 1.0);

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 17,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),

              Text(
                '${(safeValue * 100).toStringAsFixed(0)}%',

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              10,
            ),

            child:
                LinearProgressIndicator(
              value: safeValue,
              minHeight: 8,

              backgroundColor:
                  Colors.grey.shade200,

              color:
                  const Color(
                0xFF5B8C51,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                icon,
                color:
                    const Color(
                  0xFF355E3B,
                ),
              ),

              const SizedBox(width: 9),

              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            text.isEmpty
                ? 'Information unavailable.'
                : text,

            style:
                const TextStyle(
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXTRACT IPM STEPS
  // ============================================================

  List<String> _extractIpmSteps() {
    if (_result == null) {
      return [];
    }

    const advisoryKeys = [
      'ipm_advisory',
      'advisory',
      'ipm',
      'advisory_result',
      'ipm_result',
    ];

    const stepKeys = [
      'ipm_steps',
      'steps',
      'recommendations',
      'actions',
      'advice',
      'recommendation',
    ];

    // ----------------------------------------------------------
    // Search top-level advisory objects
    // ----------------------------------------------------------

    for (final advisoryKey in advisoryKeys) {
      final raw =
          _result![advisoryKey];

      if (raw is Map) {
        final map =
            Map<String, dynamic>.from(
          raw,
        );

        for (final stepKey in stepKeys) {
          final steps =
              map[stepKey];

          if (steps is List &&
              steps.isNotEmpty) {
            return steps
                .map(
                  (e) => e.toString(),
                )
                .where(
                  (e) =>
                      e.trim().isNotEmpty,
                )
                .toList();
          }
        }

        // Single recommendation text
        for (final textKey in [
          'message',
          'text',
          'recommendation_text',
        ]) {
          final text =
              map[textKey];

          if (text is String &&
              text.trim().isNotEmpty) {
            return [text];
          }
        }
      }

      // Direct list
      if (raw is List &&
          raw.isNotEmpty) {
        return raw
            .map(
              (e) => e.toString(),
            )
            .where(
              (e) =>
                  e.trim().isNotEmpty,
            )
            .toList();
      }
    }

    // ----------------------------------------------------------
    // Search recursively through response
    // ----------------------------------------------------------

    final recursive =
        _findListRecursively(
      _result!,
      stepKeys,
    );

    if (recursive.isNotEmpty) {
      return recursive;
    }

    return [];
  }

  // ============================================================
  // RECURSIVE LIST SEARCH
  // ============================================================

  List<String> _findListRecursively(
    dynamic data,
    List<String> wantedKeys,
  ) {
    if (data is Map) {
      for (final entry in data.entries) {
        final key =
            entry.key.toString();

        if (wantedKeys.contains(key)) {
          final value =
              entry.value;

          if (value is List &&
              value.isNotEmpty) {
            return value
                .map(
                  (e) => e.toString(),
                )
                .where(
                  (e) =>
                      e.trim().isNotEmpty,
                )
                .toList();
          }
        }

        final nested =
            _findListRecursively(
          entry.value,
          wantedKeys,
        );

        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }

    if (data is List) {
      for (final item in data) {
        final nested =
            _findListRecursively(
          item,
          wantedKeys,
        );

        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }

    return [];
  }

  // ============================================================
  // DEFAULT IPM
  // ============================================================

  List<String> _defaultIpmSteps(
    String disease,
  ) {
    final lower =
        disease.toLowerCase();

    if (lower.contains('mosaic')) {
      return [
        'Remove and isolate visibly infected plants or leaves.',
        'Sanitize pruning tools and hands after handling infected plants.',
        'Avoid touching healthy plants immediately after infected plants.',
        'Use disease-free planting material and resistant varieties where available.',
        'Monitor nearby plants regularly for new symptoms.',
      ];
    }

    if (lower.contains('late blight')) {
      return [
        'Remove severely infected leaves or plants and dispose of them safely.',
        'Avoid prolonged leaf wetness and improve field ventilation.',
        'Monitor the crop closely after rainfall or high-humidity periods.',
        'Use recommended disease-management practices according to local agricultural guidance.',
        'Inspect nearby plants because late blight can spread rapidly.',
      ];
    }

    if (lower.contains('early blight')) {
      return [
        'Remove heavily infected leaves and plant debris.',
        'Avoid overhead irrigation where possible.',
        'Maintain adequate spacing and field ventilation.',
        'Rotate crops where practical to reduce disease pressure.',
        'Continue monitoring the crop for new lesions.',
      ];
    }

    if (lower.contains('powdery mildew')) {
      return [
        'Remove heavily affected leaves where practical.',
        'Improve airflow around plants by maintaining suitable spacing.',
        'Avoid excessive nitrogen application.',
        'Monitor new growth for spreading symptoms.',
        'Follow locally recommended disease-management practices.',
      ];
    }

    // Generic IPM fallback.
    return [
      'Remove or isolate visibly infected plant material.',
      'Sanitize tools after handling affected plants.',
      'Monitor nearby plants for similar symptoms.',
      'Maintain good field hygiene and suitable crop spacing.',
      'Follow locally recommended integrated pest-management practices.',
    ];
  }

  // ============================================================
  // IPM CARD
  // ============================================================

  Widget _buildIpmCard(
    List<String> steps,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color:
            const Color(0xFFEAF2E6),

        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color:
              const Color(0xFFD2E2CC),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Row(
            children: [
              Icon(
                Icons
                    .shield_outlined,
                color:
                    Color(0xFF355E3B),
                size: 26,
              ),

              SizedBox(width: 9),

              Text(
                'Recommended IPM',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF29452B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Text(
            'Integrated Pest Management actions for your crop',

            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 18),

          ...List.generate(
            steps.length,
            (index) {
              return Container(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),

                padding:
                    const EdgeInsets.all(
                  13,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),

                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Container(
                      width: 29,
                      height: 29,

                      alignment:
                          Alignment.center,

                      decoration:
                          const BoxDecoration(
                        color:
                            Color(
                          0xFF355E3B,
                        ),
                        shape:
                            BoxShape.circle,
                      ),

                      child: Text(
                        '${index + 1}',

                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Text(
                        steps[index],

                        style:
                            const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color:
                              Color(
                            0xFF263626,
                          ),
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

  // ============================================================
  // VOICE BUTTON
  // ============================================================

  Widget _buildVoiceButton() {
    return SizedBox(
      width: double.infinity,

      child:
          ElevatedButton.icon(
        onPressed: _speaking
            ? _stopSpeaking
            : _speakResult,

        icon: Icon(
          _speaking
              ? Icons.stop
              : Icons
                  .volume_up_outlined,
        ),

        label: Text(
          _speaking
              ? 'Stop Voice'
              : 'Listen to Diagnosis',
        ),

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              const Color(
            0xFF355E3B,
          ),

          foregroundColor:
              Colors.white,

          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 16,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              17,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RETAKE
  // ============================================================

  Widget _buildRetakeButton() {
    return SizedBox(
      width: double.infinity,

      child:
          OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _imageBytes = null;
            _result = null;
          });
        },

        icon: const Icon(
          Icons.refresh,
        ),

        label: const Text(
          'Analyze Another Crop',
        ),

        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              const Color(
            0xFF355E3B,
          ),

          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 15,
          ),

          side:
              const BorderSide(
            color:
                Color(0xFF355E3B),
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              17,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISEASE NAME FORMATTER
  // ============================================================

  String _formatDiseaseName(
    String value,
  ) {
    if (value.trim().isEmpty) {
      return 'No disease detected';
    }

    return value
        .replaceAll('___', ' ')
        .replaceAll('__', ' ')
        .replaceAll('_', ' ')
        .replaceAll(',', ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where(
          (word) => word.isNotEmpty,
        )
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}'
                  '${word.substring(1)}',
        )
        .join(' ');
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}