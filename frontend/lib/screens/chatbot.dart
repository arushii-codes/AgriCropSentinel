import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum ChatSender { user, bot }

class ChatMessage {
  final String text;
  final ChatSender sender;
  final File? imageFile;
  final String? voiceUrl;

  ChatMessage({
    required this.text,
    required this.sender,
    this.imageFile,
    this.voiceUrl,
  });
}

class Api {
  static const String _baseUrl = 'http://10.26.133.104:8000';

  static Future<String> getChatResponse(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/general'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'prompt': text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['response'] ?? 'No response from server.';
      } else {
        return 'Error: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error: Could not connect. Make sure your device and PC are on the same Wi-Fi.';
    }
  }

  static Future<Map<String, dynamic>> analyzeImage(
    File imageFile, {
    bool voice = true,
    String lang = 'hi',
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/image-analysis/analyze'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );
    request.fields['voice'] = voice.toString();
    request.fields['lang'] = lang;

    var response = await request.send();
    if (response.statusCode == 200) {
      var respStr = await response.stream.bytesToString();
      return json.decode(respStr);
    } else {
      throw Exception('Failed to analyze image');
    }
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crop Drop Chat',
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D32),
        scaffoldBackgroundColor: const Color(0xFFF6F8F6),
        textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = false;
  final FlutterTts _flutter_tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text:
            "Hello! I am Crop Drop, your agriculture expert. How can I help you today?",
        sender: ChatSender.bot,
      ),
    );
    _flutter_tts.setLanguage("hi-IN");
    _flutter_tts.setSpeechRate(0.5);
    _flutter_tts.setVolume(1.0);
  }

  Future<void> _speakText(String text) async {
    await _flutter_tts.stop();
    await _flutter_tts.speak(text);
  }

  Future<void> _sendTextMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, sender: ChatSender.user));
      _isLoading = true;
    });
    _controller.clear();

    final response = await Api.getChatResponse(text);
    setState(() {
      _messages.add(ChatMessage(text: response, sender: ChatSender.bot));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendImageMessage() async {
    // Step 1️⃣ Ask user: Camera or Gallery?
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
                title: const Text("Take a Photo"),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF2E7D32),
                ),
                title: const Text("Choose from Gallery"),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    // Step 2️⃣ Handle user cancel
    if (source == null) return;

    // Step 3️⃣ Pick image
    final XFile? pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    final File imageFile = File(pickedFile.path);

    setState(() {
      _messages.add(
        ChatMessage(
          text: "Image selected...",
          sender: ChatSender.user,
          imageFile: imageFile,
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final result = await Api.analyzeImage(imageFile);
      final String detailedInfo = result['detailed_info'] ?? "No details";

      setState(() {
        _messages.add(
          ChatMessage(
            text: detailedInfo,
            sender: ChatSender.bot,
            voiceUrl: result['voice_url'],
          ),
        );
        _isLoading = false;
      });

      // 🔊 Play backend voice if available, else speak locally
      if (result['voice_url'] != null) {
        await _audioPlayer.play(UrlSource(result['voice_url']));
      } else {
        _speakText(detailedInfo);
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Error analyzing image: $e",
            sender: ChatSender.bot,
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SliverAppBarHeader(),
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final message = _messages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        child: _ChatBubble(
                          message: message,
                          onSpeakPressed: message.sender == ChatSender.bot
                              ? () => _speakText(message.text)
                              : null,
                        ),
                      );
                    }, childCount: _messages.length),
                  ),
                  if (_isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _TypingIndicator(),
                      ),
                    ),
                ],
              ),
            ),
            _MessageInputField(
              controller: _controller,
              onSendPressed: _sendTextMessage,
              onImagePressed: _sendImageMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class SliverAppBarHeader extends StatelessWidget {
  const SliverAppBarHeader({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      color: const Color(0xFFF6F8F6),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 38),
          const Text(
            'Crop Drop AI',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onSpeakPressed;

  const _ChatBubble({required this.message, this.onSpeakPressed});

  @override
  Widget build(BuildContext context) {
    bool isUser = message.sender == ChatSender.user;

    return Row(
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) const _BotAvatar(),
        if (!isUser) const SizedBox(width: 8),
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: EdgeInsets.symmetric(
              vertical: 6,
            ).copyWith(left: isUser ? 60 : 0, right: isUser ? 0 : 60),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF2E7D32) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image + Text
                if (message.imageFile != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.file(message.imageFile!, height: 150),
                      const SizedBox(height: 8),
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isUser
                              ? Colors.white
                              : const Color(0xFF333333),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF333333),
                    ),
                  ),

                // 🎧 Speaker icon for bot messages only
                if (!isUser && onSpeakPressed != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onSpeakPressed,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.volume_up,
                          size: 20,
                          color: Color(0xFF2E7D32),
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Listen",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendPressed;
  final VoidCallback onImagePressed;

  const _MessageInputField({
    required this.controller,
    required this.onSendPressed,
    required this.onImagePressed,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2E7D32);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: primaryColor),
            onPressed: onImagePressed,
            padding: EdgeInsets.symmetric(horizontal: 4),
          ),
          IconButton(
            icon: const Icon(Icons.mic, color: primaryColor),
            onPressed: () {},
            padding: EdgeInsets.symmetric(horizontal: 4),
          ),

          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 10,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: "Ask about farming...",
                filled: true,
                fillColor: const Color(0xFFF0F2F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
              ),
              onSubmitted: (_) => onSendPressed(),
            ),
          ),

          const SizedBox(width: 6),

          CircleAvatar(
            radius: 22,
            backgroundColor: primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: onSendPressed,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _BotAvatar(),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
              ),
            ],
          ),
          child: const Text(
            "Crop Drop is thinking...",
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class _BotAvatar extends StatelessWidget {
  const _BotAvatar();
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24.0,
      backgroundColor: Colors.white,
      child: ClipOval(
        child: Image.asset(
          'assets/bot.png',
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
