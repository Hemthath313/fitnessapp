import 'package:fitness_app/presentation/banner_ads/banner_ad_service.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AICoachPersonality { motivator, scientist, companion }

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  AICoachPersonality _personality = AICoachPersonality.motivator;

  final List<String> _dailyTips = [
    "Drinking 500ml of water can boost your metabolism by 30% for over an hour.",
    "Progressive overload (gradually increasing weight or reps) is key to building muscle.",
    "Rest days are when your muscles actually grow and recover. Don't skip them!",
    "Lifting weights burns calories during the workout, but muscle tissue burns calories even at rest.",
    "A high-protein snack before bed can support muscle synthesis and recovery overnight.",
    "Compound exercises (squats, deadlifts, bench press) engage multiple muscles and burn more energy.",
    "Stretching after a workout helps reduce soreness and improves joint flexibility.",
    "Consistency beats intensity. 3 moderate workouts a week is better than 1 extreme session.",
  ];
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
    
    if (mounted) {
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
  }

  Future<void> _incrementCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _questionsCount++;
        _limitReached = _questionsCount >= _dailyLimit;
      });
    }
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
  }

  Future<void> _askGemini(String question) async {
    String personalityInstruction = "";
    switch (_personality) {
      case AICoachPersonality.motivator:
        personalityInstruction = 
            "Act as a high-energy fitness trainer like Arnold Schwarzenegger. "
            "Use bodybuilding slang, words like 'crush it', 'heavy', 'pump', and lots of fitness/flexing emojis. "
            "Be extremely motivating and intense. ";
        break;
      case AICoachPersonality.scientist:
        personalityInstruction = 
            "Act as a detailed, fact-oriented sports science researcher. "
            "Explain the physiological mechanism briefly, use precise numbers (macronutrients, reps, rests), "
            "be formal and highly detailed, avoiding hype. ";
        break;
      case AICoachPersonality.companion:
        personalityInstruction = 
            "Act as a supportive, warm, and friendly fitness partner. "
            "Emphasize mental wellness, proper recovery, sleep, and warm, encouraging words. ";
        break;
    }

    final prompt =
        "Instructions: $personalityInstruction Answer only fitness, health, supplement, diet, calories, protein, and workout related questions. "
        "Keep the answer concise (under 100 words). "
        "Question: $question";

    ChatMessage? aiMessage;

    try {
      final stream = gemini!.streamGenerateContent(prompt);
      
      await for (final value in stream) {
        final chunk = value.output ?? "";
        if (chunk.isNotEmpty) {
          if (mounted) {
            setState(() {
              if (aiMessage == null) {
                aiMessage = ChatMessage(message: chunk, isUser: false);
                _messages.add(aiMessage!);
                isThinking = false;
              } else {
                aiMessage!.message += chunk;
              }
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      String userFriendlyMessage = "Sorry, I'm having trouble connecting to the AI. Please try again.";
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('503') || errStr.contains('demand') || errStr.contains('busy') || errStr.contains('unavailable')) {
        userFriendlyMessage = "The AI is currently experiencing high demand. Please try again in a few moments!";
      } else if (errStr.contains('quota') || errStr.contains('limit')) {
        userFriendlyMessage = "AI limit reached or API quota exceeded. Please try again later.";
      } else if (errStr.contains('403') || errStr.contains('suspended') || errStr.contains('permission')) {
        userFriendlyMessage = "API Key error or access denied. Please check your credentials.";
      }

      if (mounted) {
        setState(() {
          if (aiMessage == null) {
            _messages.add(ChatMessage(message: userFriendlyMessage, isUser: false));
          } else {
            aiMessage!.message = userFriendlyMessage;
          }
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) {
        setState(() {
          isThinking = false;
        });
        _scrollToBottom();
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
        title: Text('AI Coach', style: TextStyle(color: ColorManager.textPrimary)),
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
            _buildPersonalitySelector(),
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

            _buildInputArea(),
            const PremiumAwareBannerAd(pageName: 'chat'),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalitySelector() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      color: ColorManager.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Coach Style:',
            style: TextStyle(
              color: ColorManager.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              _buildPersonalityChip(AICoachPersonality.motivator, '⚡ Arnold'),
              SizedBox(width: 8.w),
              _buildPersonalityChip(AICoachPersonality.scientist, '🔬 Scientist'),
              SizedBox(width: 8.w),
              _buildPersonalityChip(AICoachPersonality.companion, '🤝 Friendly'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityChip(AICoachPersonality p, String label) {
    final isSelected = _personality == p;
    return GestureDetector(
      onTap: () {
        setState(() {
          _personality = p;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? ColorManager.primary : ColorManager.background,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(
            color: isSelected ? ColorManager.primary : ColorManager.divider,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : ColorManager.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 11.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final dayOfMonth = DateTime.now().day;
    final dailyTip = _dailyTips[(dayOfMonth - 1) % _dailyTips.length];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorManager.primary.withOpacity(0.15), ColorManager.primary.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: ColorManager.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: ColorManager.primary, size: 28.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 Daily Fitness Fact',
                        style: TextStyle(
                          color: ColorManager.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        dailyTip,
                        style: TextStyle(
                          color: ColorManager.textSecondary,
                          fontSize: 12.sp,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Quick Action Guides',
            style: TextStyle(
              color: ColorManager.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 12.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1.4,
            children: [
              _buildCategoryCard(
                '🍏',
                'Diet Planner',
                'Get custom protein & meal tips.',
                'Build a high-protein diet plan for muscle gain',
              ),
              _buildCategoryCard(
                '💪',
                'Form Check',
                'Learn how to do exercises safely.',
                'Show me key tips to keep my squat form perfect',
              ),
              _buildCategoryCard(
                '😴',
                'Recovery',
                'Optimize sleep and muscle rest.',
                'How can I optimize sleep and recovery for bodybuilding?',
              ),
              _buildCategoryCard(
                '⚡',
                'Motivation',
                'Get an instant mental energy boost.',
                'Give me a short, intense pump-up speech for my workout',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String emoji, String title, String desc, String promptText) {
    return InkWell(
      onTap: () => _sendMessage(text: promptText),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: ColorManager.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(emoji, style: TextStyle(fontSize: 20.sp)),
                Icon(Icons.arrow_forward_rounded, color: ColorManager.textTertiary, size: 16.sp),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ColorManager.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ColorManager.textSecondary,
                    fontSize: 10.sp,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
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
            labelStyle: TextStyle(color: ColorManager.textPrimary, fontSize: 12.sp),
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
            :  LinearGradient(colors: [ColorManager.surface, ColorManager.surface]),
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
            color: isUser ? Colors.white : ColorManager.textPrimary,
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
      decoration:  BoxDecoration(
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
      decoration:  BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: ColorManager.textPrimary),
              enabled: !_limitReached,
              decoration: InputDecoration(
                hintText: _limitReached ? 'Daily limit reached' : 'Ask a question...',
                hintStyle: TextStyle(color: ColorManager.textTertiary),
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
  String message;
  final bool isUser;

  ChatMessage({required this.message, required this.isUser});
}

// import 'package:flutter/material.dart';

// class ChatScreen extends StatelessWidget {
//   const ChatScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: ColorManager.background,
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
//                 color: ColorManager.textPrimary,
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               'Stay tuned for exciting updates!',
//               style: TextStyle(
//                 color: ColorManager.textTertiary,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
