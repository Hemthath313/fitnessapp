import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool isThinking = false;

  Future<void> _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(message: userMessage, isUser: true));
      isThinking = true;
    });

    _controller.clear();
    _scrollToBottom();

    final response = await _askGemini(userMessage);

    setState(() {
      _messages.add(ChatMessage(message: response, isUser: false));
      isThinking = false;
    });

    _scrollToBottom();
  }

  Future<String> _askGemini(String question) async {
    const apiKey = 'AIzaSyBAzw2Wu3RjsDCxEt17PmCeCeccxtBThUw';
    const endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text":
                  "Answer only fitness and health and supplement diet calories protein foods related questions. If the question is not related to fitness, reply 'I can only answer fitness related questions.'\n\nQuestion: $question"
            }
          ]
        }
      ]
    });

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        try {
          final text = data['candidates'][0]['content']['parts'][0]['text'];
          return text ?? 'No text response found.';
        } catch (e) {
          return 'Error parsing response: $e';
        }
      } else {
        return 'API request failed: ${response.statusCode}';
      }
    } catch (e) {
      return 'Network error: $e';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      body: SafeArea(
        bottom: true,
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: kToolbarHeight + 10), // Space for app bar
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && isThinking) {
                      return _buildTypingIndicator();
                    }
                    final message = _messages[index];
                    final isUser = message.isUser;

                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser
                              ? ColorManager.primary
                              : ColorManager.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isUser ? 16 : 0),
                            bottomRight: Radius.circular(isUser ? 0 : 16),
                          ),
                        ),
                        child: Text(
                          message.message,
                          style: TextStyle(
                            color: isUser ? Colors.black : ColorManager.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              BannerAdWidget(pageName: 'chat'),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: ColorManager.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ask a fitness question...',
                hintStyle: const TextStyle(color: ColorManager.textTertiary),
                filled: true,
                fillColor: ColorManager.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: ColorManager.primary, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: ColorManager.primary, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: ColorManager.primary),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          '...',
          style: TextStyle(color: ColorManager.textPrimary, fontSize: 20),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String message;
  final bool isUser;

  ChatMessage({required this.message, required this.isUser});
}

// import 'package:flutter/material.dart';

// class ChatScreen extends StatelessWidget {
//   const ChatScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.lock,
//               size: 100,
//               color: Colors.lime,
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Coming Soon',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               'Stay tuned for exciting updates!',
//               style: TextStyle(
//                 color: Colors.white54,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
