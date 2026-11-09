import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:fitness_app/utils/managers/value_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final gemini = Gemini.instance;
  bool _isTyping = false;

  final List<ChatModel> _messages = [
    ChatModel(
      text:
          "Hello! I'm your AI Personal Trainer powered by Gemini. How can I help you today?",
      isUser: false,
    ),
  ];

  final List<String> _quickPrompts = [
    "🍎 Meal Idea",
    "💪 Form Tip",
    "🔄 Swap Lift",
    "⚡ Motivation",
  ];

  static const Map<String, String> _promptMap = {
    "🍎 Meal Idea": "Suggest a delicious, high-protein meal or post-workout snack with approximate macros.",
    "💪 Form Tip": "What are 3 critical form cues to avoid injury and maximize hypertrophy on compound lifts?",
    "🔄 Swap Lift": "What are the top dumbbell or bodyweight substitutes if the squat rack or barbell bench is taken?",
    "⚡ Motivation": "Give me a short, powerful motivational message to get me fired up for my workout today!",
  };

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text, {String? displayLabel}) {
    final messageText = text.trim();
    if (messageText.isEmpty || _isTyping) return;

    final displayText = displayLabel ?? messageText;

    setState(() {
      _messages.add(ChatModel(text: displayText, isUser: true));
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    ChatModel? aiMessageModel;

    final systemPrompt =
        "You are an encouraging and knowledgeable AI Fitness Coach in the Gym Buddy app. "
        "Provide direct, concise, and scientifically accurate workout and nutrition advice. "
        "Keep answers practical and focused.\n\nUser Question: $messageText";

    try {
      gemini.streamGenerateContent(systemPrompt).listen(
        (value) {
          final chunk = value.output ?? "";
          if (chunk.isNotEmpty) {
            setState(() {
              if (aiMessageModel == null) {
                aiMessageModel = ChatModel(text: chunk, isUser: false);
                _messages.add(aiMessageModel!);
              } else {
                aiMessageModel!.text += chunk;
              }
            });
            _scrollToBottom();
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isTyping = false;
            });
          }
        },
        onError: (e) {
          String userFriendlyMessage = "Sorry, I'm having trouble connecting to Gemini. Please check your API key.";
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
              _isTyping = false;
              if (aiMessageModel == null) {
                _messages.add(ChatModel(
                  text: userFriendlyMessage,
                  isUser: false,
                ));
              } else {
                aiMessageModel!.text = userFriendlyMessage;
              }
            });
            _scrollToBottom();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    }
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
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title:
            Text('AI Coach Chat', style: TextStyle(color: ColorManager.textPrimary)),
        backgroundColor: ColorManager.background,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatMessage(text: message.text, isUser: message.isUser);
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: EdgeInsets.only(left: 20.w, bottom: 8.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'AI is typing...',
                  style: TextStyle(
                      color: ColorManager.primary.withValues(alpha: 0.7),
                      fontSize: 12.sp,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ),
          _buildQuickPrompts(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return Container(
      height: 50.h,
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        itemCount: _quickPrompts.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ActionChip(
              label: Text(_quickPrompts[index]),
              labelStyle: TextStyle(color: ColorManager.textPrimary, fontSize: 12.sp),
              backgroundColor: ColorManager.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(color: ColorManager.primary.withValues(alpha: 0.3)),
              ),
              onPressed: () => _sendMessage(
                _promptMap[_quickPrompts[index]] ?? _quickPrompts[index],
                displayLabel: _quickPrompts[index],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        bottom: MediaQuery.of(context).padding.bottom + 16.h,
        top: 10.h,
      ),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: ColorManager.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: ColorManager.textTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          IconButton(tooltip: 'Send', 
            onPressed: () => _sendMessage(_messageController.text),
            icon: Icon(Icons.send_rounded, color: ColorManager.primaryText),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        decoration: BoxDecoration(
          color: isUser ? ColorManager.primary : ColorManager.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: Radius.circular(isUser ? 20.r : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? ColorManager.onMint : ColorManager.textPrimary,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}

class ChatModel {
  String text;
  final bool isUser;

  ChatModel({required this.text, required this.isUser});
}

