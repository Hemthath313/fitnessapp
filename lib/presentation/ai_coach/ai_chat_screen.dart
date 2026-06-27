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

  final List<ChatMessage> _messages = [
    ChatMessage(
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

  void _sendMessage(String text) {
    if (text.trim().isEmpty || _isTyping) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      gemini.streamGenerateContent(text).listen(
        (value) {
          final response = value.output ?? "";
          if (response.isNotEmpty) {
            setState(() {
              _isTyping = false;
              _messages.add(ChatMessage(
                text: response,
                isUser: false,
              ));
            });
            _scrollToBottom();
          }
        },
        onError: (e) {
          setState(() {
            _isTyping = false;
            _messages.add(ChatMessage(
              text:
                  "Sorry, I'm having trouble connecting to Gemini. Please check your API key.",
              isUser: false,
            ));
          });
          _scrollToBottom();
        },
      );
    } catch (e) {
      setState(() {
        _isTyping = false;
      });
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
              itemBuilder: (context, index) => _messages[index],
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
                      color: ColorManager.primary.withOpacity(0.7),
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
                side: BorderSide(color: ColorManager.primary.withOpacity(0.3)),
              ),
              onPressed: () => _sendMessage(_quickPrompts[index]),
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
          IconButton(
            onPressed: () => _sendMessage(_messageController.text),
            icon: Icon(Icons.send_rounded, color: ColorManager.primary),
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
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.black : Colors.white,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}
