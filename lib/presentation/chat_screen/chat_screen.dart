import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  
  // Daily Limit State
  static const int _dailyLimit = 5;
  int _questionsCount = 0;
  bool _limitReached = false;
  
  bool isThinking = false;
  Gemini? gemini;
  bool _isKeyMissing = false;

  final List<String> _suggestions = [
    "🔥 Fat Loss Tips",
    "💪 Muscle Building Diet",
    "🥗 Healthy Snacks",
    "🏋️ Best Abs Workout",
    "😴 Sleep & Recovery"
  ];

  @override
  void initState() {
    super.initState();
    _loadDailyLimit();
    _initGemini();
  }

  void _initGemini() {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      _isKeyMissing = true;
    } else {
      try {
        gemini = Gemini.instance;
      } catch (e) {
        _isKeyMissing = true;
      }
    }
  }

  Future<void> _loadDailyLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    final lastDate = prefs.getString('chat_last_date');
    
    setState(() {
      if (lastDate != today) {
        // New day, reset count
        _questionsCount = 0;
        prefs.setString('chat_last_date', today);
        prefs.setInt('chat_count', 0);
      } else {
        // Same day, load count
        _questionsCount = prefs.getInt('chat_count') ?? 0;
      }
      _limitReached = _questionsCount >= _dailyLimit;
    });
  }

  Future<void> _incrementCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _questionsCount++;
      _limitReached = _questionsCount >= _dailyLimit;
    });
    await prefs.setInt('chat_count', _questionsCount);
  }

  Future<void> _sendMessage({String? text}) async {
    final userMessage = text ?? _controller.text.trim();
    if (userMessage.isEmpty) return;

    if (_isKeyMissing || gemini == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemini API Key is missing! Check .env file.')),
      );
      return;
    }

    if (_limitReached) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily limit reached! Come back tomorrow.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _messages.add(ChatMessage(message: userMessage, isUser: true));
      isThinking = true;
    });

    _controller.clear();
    _scrollToBottom();
    
    // Increment limit BEFORE sending (to prevent spamming)
    await _incrementCount();

    await _askGemini(userMessage);

    setState(() {
      isThinking = false;
    });

    _scrollToBottom();
  }

  Future<void> _askGemini(String question) async {
    final prompt =
        "Answer only fitness and health and supplement diet calories protein foods related questions. "
        "Keep the answer concise (under 100 words) if possible. "
        "Question: $question";

    try {
      final value = await gemini!.prompt(parts: [Part.text(prompt)]);
      final response = value?.output ?? 'No response from AI.';

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(message: response, isUser: false));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(message: "Error: Unable to connect to AI.", isUser: false));
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        backgroundColor: ColorManager.background,
        elevation: 0,
        title: const Text('AI Coach', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: _limitReached ? Colors.red.withOpacity(0.2) : ColorManager.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _limitReached ? Colors.red : ColorManager.primary,
                width: 1,
              )
            ),
            child: Text(
              '${_dailyLimit - _questionsCount} Left',
              style: TextStyle(
                color: _limitReached ? Colors.red : ColorManager.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (isThinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && isThinking) {
                        return _buildTypingIndicator();
                      }
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
            ),
            if (!_limitReached && !isThinking)
              _buildSuggestions(),
              
            BannerAdWidget(pageName: 'chat'),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, color: ColorManager.primary, size: 48.sp),
          SizedBox(height: 16.h),
          Text(
            'Ask me anything about fitness!',
            style: TextStyle(color: Colors.white70, fontSize: 16.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 50.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (c, i) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(_suggestions[index]),
            backgroundColor: ColorManager.surface,
            labelStyle: TextStyle(color: Colors.white, fontSize: 12.sp),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: ColorManager.primary.withOpacity(0.3)),
            ),
            onPressed: () => _sendMessage(text: _suggestions[index]),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isUser 
            ? LinearGradient(colors: [ColorManager.primary, ColorManager.primary.withOpacity(0.8)])
            : const LinearGradient(colors: [ColorManager.surface, ColorManager.surface]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Text(
          message.message,
          style: TextStyle(
            color: isUser ? Colors.black : Colors.white,
            fontSize: 15.sp,
            fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          width: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _dot(0),
              _dot(1),
              _dot(2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(int index) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: ColorManager.textTertiary,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16.w, 
        right: 16.w, 
        top: 12.h,
        bottom: MediaQuery.of(context).padding.bottom + 12.h
      ),
      decoration: const BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              enabled: !_limitReached,
              decoration: InputDecoration(
                hintText: _limitReached ? 'Daily limit reached' : 'Ask a question...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: ColorManager.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (val) => _sendMessage(),
            ),
          ),
          SizedBox(width: 12.w),
          Container(
            decoration: BoxDecoration(
              color: _limitReached ? Colors.grey : ColorManager.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.black),
              onPressed: _limitReached ? null : () => _sendMessage(),
            ),
          ),
        ],
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
