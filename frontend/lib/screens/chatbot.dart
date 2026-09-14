import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

/// ===============================================================
/// AGRICROPSENTINEL CHAT SCREEN
/// ===============================================================
///
/// Features:
/// - Farmer chatbot
/// - FastAPI backend connection
/// - Hindi / English friendly responses
/// - Local Flutter TTS fallback
/// - Backend voice support if voice_url is available
/// - Clean Chrome-compatible implementation
///
/// NOTE:
/// Image analysis should continue through your existing camera.dart
/// because this file intentionally does NOT use file_picker.
/// ===============================================================

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // =============================================================
  // BACKEND
  // =============================================================

  static const String backendUrl = "http://localhost:8000";

  // =============================================================
  // CONTROLLERS
  // =============================================================

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  // =============================================================
  // AUDIO
  // =============================================================

  final FlutterTts _flutterTts = FlutterTts();

  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isSpeaking = false;

  // =============================================================
  // CHAT STATE
  // =============================================================

  bool _isLoading = false;

  final List<ChatMessage> _messages = [];

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    _initializeTts();

    _addWelcomeMessage();
  }

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    _flutterTts.stop();
    _audioPlayer.dispose();

    super.dispose();
  }

  // =============================================================
  // WELCOME MESSAGE
  // =============================================================

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text:
            "Namaste! 🌾\n\n"
            "Main AgriCropSentinel AI hoon. "
            "Aap mujhse apni fasal, bimari, weather risk, "
            "treatment ya farming ke baare mein pooch sakte hain.\n\n"
            "Aap example ke liye pooch sakte hain:\n"
            "• Tomato leaves have brown spots\n"
            "• What should I do for Apple Black Rot?\n"
            "• How can I protect my crop from disease?",
        isUser: false,
      ),
    );
  }

  // =============================================================
  // TTS INITIALIZATION
  // =============================================================

  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage("hi-IN");

      await _flutterTts.setSpeechRate(0.5);

      await _flutterTts.setVolume(1.0);

      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        if (!mounted) return;

        setState(() {
          _isSpeaking = true;
        });
      });

      _flutterTts.setCompletionHandler(() {
        if (!mounted) return;

        setState(() {
          _isSpeaking = false;
        });
      });

      _flutterTts.setCancelHandler(() {
        if (!mounted) return;

        setState(() {
          _isSpeaking = false;
        });
      });

      _flutterTts.setErrorHandler((message) {
        debugPrint("TTS error: $message");

        if (!mounted) return;

        setState(() {
          _isSpeaking = false;
        });
      });
    } catch (e) {
      debugPrint("TTS initialization error: $e");
    }
  }

  // =============================================================
  // LOCAL TTS
  // =============================================================

  Future<void> speakText(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    try {
      await _audioPlayer.stop();

      await _flutterTts.stop();

      await _flutterTts.setLanguage("hi-IN");

      await _flutterTts.setSpeechRate(0.5);

      await _flutterTts.setVolume(1.0);

      await _flutterTts.setPitch(1.0);

      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("Local TTS error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Voice playback is not available.",
          ),
        ),
      );
    }
  }

  // =============================================================
  // STOP SPEAKING
  // =============================================================

  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();

      await _audioPlayer.stop();

      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });
    } catch (e) {
      debugPrint("Stop voice error: $e");
    }
  }

  // =============================================================
  // PLAY VOICE
  // =============================================================

  Future<void> playVoice({
    String? voiceUrl,
    required String fallbackText,
  }) async {
    try {
      await stopSpeaking();

      // ---------------------------------------------------------
      // Try backend-generated audio first
      // ---------------------------------------------------------

      if (voiceUrl != null &&
          voiceUrl.trim().isNotEmpty) {
        String finalUrl = voiceUrl.trim();

        // Backend may return:
        // /uploadvoices/example.mp3

        if (finalUrl.startsWith("/")) {
          finalUrl = "$backendUrl$finalUrl";
        }

        debugPrint(
          "Trying backend voice: $finalUrl",
        );

        try {
          await _audioPlayer.play(
            UrlSource(finalUrl),
          );

          if (!mounted) return;

          setState(() {
            _isSpeaking = true;
          });

          return;
        } catch (e) {
          debugPrint(
            "Backend voice failed: $e",
          );

          debugPrint(
            "Falling back to Flutter TTS.",
          );
        }
      }

      // ---------------------------------------------------------
      // Backend voice unavailable
      // Use local Flutter TTS
      // ---------------------------------------------------------

      await speakText(fallbackText);
    } catch (e) {
      debugPrint(
        "Voice playback error: $e",
      );
    }
  }

  // =============================================================
  // SEND MESSAGE
  // =============================================================

  Future<void> sendMessage() async {
    final text =
        _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    if (_isLoading) {
      return;
    }

    _messageController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
        ),
      );

      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(
          "$backendUrl/chat/general",
        ),
        headers: {
          "Content-Type":
              "application/json",
          "Accept":
              "application/json",
        },
        body: jsonEncode({
          "prompt": text,
        }),
      );

      debugPrint(
        "Chat status: ${response.statusCode}",
      );

      debugPrint(
        "Chat response: ${response.body}",
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Chat API error: "
          "${response.statusCode}",
        );
      }

      final decoded =
          jsonDecode(response.body);

      final reply =
          _extractResponse(decoded);

      final voiceUrl =
          _extractVoiceUrl(decoded);

      setState(() {
        _messages.add(
          ChatMessage(
            text: reply,
            isUser: false,
            voiceUrl: voiceUrl,
          ),
        );

        _isLoading = false;
      });

      _scrollToBottom();

      await playVoice(
        voiceUrl: voiceUrl,
        fallbackText: reply,
      );
    } catch (e) {
      debugPrint(
        "Chat request failed: $e",
      );

      setState(() {
        _messages.add(
          ChatMessage(
            text:
                "Sorry, I could not connect to "
                "the AgriCropSentinel AI service.\n\n"
                "Please make sure the backend is running.",
            isUser: false,
          ),
        );

        _isLoading = false;
      });

      _scrollToBottom();
    }
  }

  // =============================================================
  // EXTRACT CHAT RESPONSE
  // =============================================================

  String _extractResponse(dynamic data) {
    // Backend returned plain string
    if (data is String) {
      return data;
    }

    // Backend returned JSON object
    if (data is Map) {
      final possibleKeys = [
        "response",
        "reply",
        "message",
        "answer",
        "text",
        "response_text",
        "content",
      ];

      for (final key in possibleKeys) {
        final value = data[key];

        if (value != null &&
            value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }

    return "I received a response, but could not understand its format.";
  }

  // =============================================================
  // EXTRACT VOICE URL
  // =============================================================

  String? _extractVoiceUrl(dynamic data) {
    if (data is Map) {
      final value = data["voice_url"];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return null;
  }

  // =============================================================
  // SCROLL TO BOTTOM
  // =============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position
            .maxScrollExtent,
        duration:
            const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "AgriCropSentinel AI",
        ),
        centerTitle: true,
        actions: [
          if (_isSpeaking)
            IconButton(
              tooltip: "Stop voice",
              icon: const Icon(
                Icons.stop_circle,
              ),
              onPressed: stopSpeaking,
            ),
        ],
      ),

      body: Column(
        children: [
          // =====================================================
          // CHAT MESSAGES
          // =====================================================

          Expanded(
            child: ListView.builder(
              controller:
                  _scrollController,
              padding:
                  const EdgeInsets.all(16),
              itemCount:
                  _messages.length,
              itemBuilder:
                  (context, index) {
                return _buildMessageBubble(
                  _messages[index],
                );
              },
            ),
          ),

          // =====================================================
          // LOADING
          // =====================================================

          if (_isLoading)
            const Padding(
              padding:
                  EdgeInsets.fromLTRB(
                16,
                4,
                16,
                8,
              ),
              child: Align(
                alignment:
                    Alignment.centerLeft,
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "AI is thinking...",
                    ),
                  ],
                ),
              ),
            ),

          // =====================================================
          // MESSAGE INPUT
          // =====================================================

          SafeArea(
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(
                10,
                8,
                10,
                10,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  // ------------------------------------------------
                  // CAMERA
                  // ------------------------------------------------

                  IconButton(
                    tooltip:
                        "Analyze crop image",
                    icon: const Icon(
                      Icons.camera_alt,
                    ),
                    onPressed:
                        _showImageAnalysisMessage,
                  ),

                  // ------------------------------------------------
                  // TEXT FIELD
                  // ------------------------------------------------

                  Expanded(
                    child: TextField(
                      controller:
                          _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) {
                        sendMessage();
                      },
                      decoration:
                          InputDecoration(
                        hintText:
                            "Ask about your crop...",
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(24),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  // ------------------------------------------------
                  // SEND
                  // ------------------------------------------------

                  CircleAvatar(
                    child: IconButton(
                      tooltip: "Send",
                      icon: const Icon(
                        Icons.send,
                      ),
                      onPressed:
                          _isLoading
                              ? null
                              : sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // IMAGE BUTTON MESSAGE
  // =============================================================
  //
  // We don't use file_picker here because your current target
  // is Chrome and FilePicker.platform caused the compilation error.
  //
  // Your existing camera.dart should handle image selection and
  // /vision/analyze.
  // =============================================================

  void _showImageAnalysisMessage() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          "Use the Camera / Crop Analysis screen "
          "to upload a crop image.",
        ),
      ),
    );
  }

  // =============================================================
  // MESSAGE BUBBLE
  // =============================================================

  Widget _buildMessageBubble(
    ChatMessage message,
  ) {
    final bool isUser =
        message.isUser;

    return Align(
      alignment:
          isUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
      child: Container(
        constraints:
            const BoxConstraints(
          maxWidth: 700,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.all(14),
        decoration:
            BoxDecoration(
          color:
              isUser
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                  : Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style:
                  const TextStyle(
                fontSize: 15,
                height: 1.45,
              ),
            ),

            // ----------------------------------------------------
            // VOICE CONTROL
            // ----------------------------------------------------

            if (!isUser)
              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 6,
                ),
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip:
                          "Read aloud",
                      icon: Icon(
                        _isSpeaking
                            ? Icons
                                .stop_circle
                            : Icons
                                .volume_up,
                      ),
                      onPressed: () {
                        if (_isSpeaking) {
                          stopSpeaking();
                        } else {
                          playVoice(
                            voiceUrl:
                                message.voiceUrl,
                            fallbackText:
                                message.text,
                          );
                        }
                      },
                    ),

                    if (_isSpeaking)
                      const Text(
                        "Speaking...",
                        style:
                            TextStyle(
                          fontSize: 12,
                        ),
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

// =================================================================
// CHAT MESSAGE MODEL
// =================================================================

class ChatMessage {
  final String text;

  final bool isUser;

  final String? voiceUrl;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.voiceUrl,
  });
}