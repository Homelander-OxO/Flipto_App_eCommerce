import 'dart:convert';
import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/API%20E-Commerce/Model/cart_items.dart';
import 'package:flutter_app/API%20E-Commerce/Model/e-subcategory_model.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/cart_page.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../Utilities/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isTyping = false;

  // Enhanced animation controllers
  late AnimationController _loadingController;
  late AnimationController _messageController;
  late AnimationController _inputController;
  late AnimationController _pulseController;
  late AnimationController _backgroundController;
  late AnimationController _sparkleController;
  late AnimationController _waveController;
  late AnimationController _floatingController;

  // Enhanced animations
  late Animation<double> _breatheAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<Color?> _gradientAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize all animation controllers
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _messageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _inputController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    )..repeat(reverse: true);

    // Initialize animations
    _breatheAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _messageController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _inputController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _gradientAnimation = ColorTween(
      begin: const Color(0xff101d42),
      end: const Color(0xff2d4a7a),
    ).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _inputController.forward();
      } else {
        _inputController.reverse();
      }
    });

    _controller.addListener(() {
      setState(() {
        _isTyping = _controller.text.isNotEmpty;
      });
    });

    // Add animated welcome message
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        _messages.add({
          "role": "bot",
          "text":
              "✨ Hello! I'm your premium shopping assistant. How can I help you today?"
        });
      });
    });
  }

  Future<void> _sendMessage(String input) async {
    if (input.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": input});
      _isLoading = true;
    });

    _controller.clear();
    _focusNode.unfocus();
    _scrollToBottom();

    // Add haptic feedback
    HapticFeedback.lightImpact();

    try {
      await Future.delayed(const Duration(milliseconds: 1500));
      final botReply = await DynamicChatBotService.askChatBot(input, context);

      setState(() {
        _messages.add({"role": "bot", "text": "💫 $botReply"});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "bot",
          "text":
              "🔧 I apologize, but I'm experiencing some technical difficulties. Please try again."
        });
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  List<TextSpan> _parseMarkdown(String text, bool isUser) {
    final List<TextSpan> spans = [];
    final pattern = RegExp(r'\*\*(.*?)\*\*');
    final matches = pattern.allMatches(text);
    int currentPos = 0;

    for (final match in matches) {
      if (match.start > currentPos) {
        spans.add(TextSpan(text: text.substring(currentPos, match.start)));
      }

      spans.add(
        TextSpan(
          text: match.group(1),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isUser
                ? Colors.white.withOpacity(0.95)
                : const Color(0xff101d42),
          ),
        ),
      );

      currentPos = match.end;
    }

    if (currentPos < text.length) {
      spans.add(TextSpan(text: text.substring(currentPos)));
    }

    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: Listenable.merge([_sparkleController, _floatingController]),
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: List.generate(6, (index) {
                final offset = (index * 0.5) % 1.0;
                final sparkleValue = (_sparkleAnimation.value + offset) % 1.0;
                final floatingOffset =
                    _floatingAnimation.value * (index % 2 == 0 ? 1 : -1);

                return Positioned(
                  left: 30.0 + (index * 60.0),
                  top: 100.0 + (index * 120.0) + floatingOffset,
                  child: Opacity(
                    opacity: (math.sin(sparkleValue * math.pi * 2) * 0.3 + 0.4)
                        .clamp(0.0, 0.7),
                    child: Container(
                      width: 4 + (sparkleValue * 3),
                      height: 4 + (sparkleValue * 3),
                      decoration: BoxDecoration(
                        color: const Color(0xff101d42).withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff101d42).withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessage(Map<String, String> msg, int index) {
    final isUser = msg['role'] == 'user';
    final text = msg['text'] ?? '';
    final textSpans = _parseMarkdown(text, isUser);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                child: Row(
                  mainAxisAlignment:
                      isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isUser) ...[
                      AnimatedBuilder(
                        animation: Listenable.merge(
                            [_pulseAnimation, _gradientAnimation]),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 32,
                              height: 32,
                              margin:
                                  const EdgeInsets.only(right: 12, bottom: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _gradientAnimation.value ??
                                        const Color(0xff101d42),
                                    const Color(0xff101d42),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xff101d42).withOpacity(
                                        0.4 * _pulseAnimation.value),
                                    blurRadius: 12 * _pulseAnimation.value,
                                    spreadRadius: 2 * _pulseAnimation.value,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    Flexible(
                      child: GestureDetector(
                        onTap: () {
                          // Add ripple effect on tap
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            gradient: isUser
                                ? LinearGradient(
                                    colors: [
                                      const Color(0xff101d42),
                                      const Color(0xff1a2b5c),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isUser ? null : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(24),
                              topRight: const Radius.circular(24),
                              bottomLeft: Radius.circular(isUser ? 24 : 8),
                              bottomRight: Radius.circular(isUser ? 8 : 24),
                            ),
                            border: isUser
                                ? null
                                : Border.all(
                                    color: Colors.grey.shade100,
                                    width: 1,
                                  ),
                            boxShadow: [
                              BoxShadow(
                                color: isUser
                                    ? const Color(0xff101d42).withOpacity(0.3)
                                    : Colors.black.withOpacity(0.08),
                                blurRadius: isUser ? 12 : 8,
                                offset: const Offset(0, 4),
                                spreadRadius: isUser ? 1 : 0,
                              ),
                            ],
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white.withOpacity(0.95)
                                    : const Color(0xff2d3748),
                                fontSize: 15,
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.3,
                              ),
                              children: textSpans,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isUser) ...[
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(left: 12, bottom: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade100,
                              Colors.grey.shade50,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.grey.shade600,
                          size: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final quickActions = [
      {"text": "✨ Premium Collections", "emoji": "✨"},
      {"text": "🔥 Trending Now", "emoji": "🔥"},
      {"text": "💎 Exclusive Deals", "emoji": "💎"},
      {"text": "👗 Personal Stylist", "emoji": "👗"}
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _sparkleAnimation,
            builder: (context, child) {
              return Row(
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.rotate(
                    angle: _sparkleAnimation.value * math.pi * 2,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: const Color(0xff101d42).withOpacity(0.6),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: quickActions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 600 + (index * 200)),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _sendMessage(action["text"]!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.grey.shade50,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                action["text"]!,
                                style: GoogleFonts.manrope(
                                  color: const Color(0xff101d42),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_breatheAnimation, _pulseAnimation, _gradientAnimation]),
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Row(
            children: [
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (_gradientAnimation.value ?? const Color(0xff101d42))
                            .withOpacity(_breatheAnimation.value),
                        const Color(0xff101d42)
                            .withOpacity(_breatheAnimation.value),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff101d42)
                            .withOpacity(0.4 * _pulseAnimation.value),
                        blurRadius: 12 * _pulseAnimation.value,
                        spreadRadius: 2 * _pulseAnimation.value,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: Colors.grey.shade100,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ...List.generate(3, (index) {
                        final delay = index * 0.3;
                        final animValue =
                            (_breatheAnimation.value + delay) % 1.0;
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xff101d42).withOpacity(
                              (math.sin(animValue * math.pi * 2) * 0.5 + 0.7)
                                  .clamp(0.2, 1.0),
                            ),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                      const SizedBox(width: 12),
                      Text(
                        "Thinking...",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation:
                  Listenable.merge([_pulseAnimation, _gradientAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _gradientAnimation.value ?? const Color(0xff101d42),
                          const Color(0xff101d42),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff101d42)
                              .withOpacity(0.3 * _pulseAnimation.value),
                          blurRadius: 8 * _pulseAnimation.value,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            const Text(
              'AI Assistant',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey.shade50,
        foregroundColor: const Color(0xff101d42),
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          _buildFloatingParticles(),
          Column(
            children: [
              if (_messages.length <= 1) _buildQuickActions(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  itemCount: _messages.length,
                  itemBuilder: (_, index) =>
                      _buildMessage(_messages[index], index),
                ),
              ),
              if (_isLoading) _buildLoadingIndicator(),
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.grey.shade50,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: _focusNode.hasFocus
                              ? const Color(0xff101d42).withOpacity(0.4)
                              : Colors.grey.shade200,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _focusNode.hasFocus
                                ? const Color(0xff101d42).withOpacity(0.15)
                                : Colors.black.withOpacity(0.08),
                            blurRadius: _focusNode.hasFocus ? 16 : 10,
                            offset: const Offset(0, 4),
                            spreadRadius: _focusNode.hasFocus ? 2 : 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              textInputAction: TextInputAction.send,
                              onSubmitted: _sendMessage,
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.3,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.elasticOut,
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: _isTyping
                                  ? LinearGradient(
                                      colors: [
                                        const Color(0xff101d42),
                                        const Color(0xff1a2b5c),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.grey.shade200,
                                        Colors.grey.shade100,
                                      ],
                                    ),
                              shape: BoxShape.circle,
                              boxShadow: _isTyping
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xff101d42)
                                            .withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.send_rounded,
                                color: _isTyping
                                    ? Colors.white
                                    : Colors.grey.shade400,
                                size: 20,
                              ),
                              onPressed: _isTyping
                                  ? () => _sendMessage(_controller.text)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _loadingController.dispose();
    _messageController.dispose();
    _inputController.dispose();
    _pulseController.dispose();
    _backgroundController.dispose();
    _sparkleController.dispose();
    _waveController.dispose();
    _floatingController.dispose();
    super.dispose();
  }
}

class DynamicChatBotService {
  static const String _geminiApiKey = "AIzaSyBNTZt6AVwVAt0BDFWuPP51yZM-gfUmXPk";

  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: _geminiApiKey,
    generationConfig: GenerationConfig(
      temperature: 0.7,
      topK: 40,
      topP: 0.95,
      maxOutputTokens: 800,
    ),
  );

  static final GenerativeModel _classifierModel = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: _geminiApiKey,
    generationConfig: GenerationConfig(
      temperature: 0.1,
      topK: 1,
      topP: 0.9,
      maxOutputTokens: 100,
    ),
  );

  // Enhanced app context with more details
  static const Map<String, dynamic> _appContext = {
    'appName': 'Flipto',
    'features': [
      'Product browsing by categories',
      'Smart search functionality',
      'Shopping cart management',
      'User account management',
      'Order tracking system',
      'Wishlist management',
      'Product reviews and ratings',
      'Multiple payment options',
      'Real-time inventory updates'
    ],
    'policies': {
      'shipping': 'Free shipping on orders above ₹500',
      'return': '30-day hassle-free return policy',
      'payment': [
        'Credit/Debit cards',
        'Razorpay',
        'UPI',
        'Cash on delivery',
        'Net Banking'
      ],
      'support': '24/7 customer support available',
      'warranty': 'Manufacturer warranty applicable on electronics',
      'delivery': 'Same-day delivery in metro cities, 2-7 days elsewhere'
    },
    'benefits': [
      'Competitive pricing',
      'Authentic products only',
      'Fast delivery',
      'Easy returns',
      'Secure payments'
    ]
  };

  /// Main entry point for chatbot queries with user context
  static Future<String> askChatBot(String userInput, BuildContext context,
      {String? userId}) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final userId = cartProvider.email ?? cartProvider.useremail ?? '';
    try {
      // Step 1: Handle quick responses first
      final quickResponse =
          await _handleQuickResponses(userInput, userId: userId, context);
      if (quickResponse != null) {
        return quickResponse;
      }

      // Step 2: Classify the user query
      final classification = await _classifyQuery(userInput);
      print('Query classification: $classification');

      // Step 3: Fetch relevant data based on classification
      final contextData =
          await _fetchRelevantData(userInput, classification, userId: userId);

      // Step 4: Generate AI response with context
      return await _generateContextualResponse(
          userInput, classification, contextData);
    } catch (e) {
      print('Chatbot error: $e');
      return _getFallbackResponse(userInput);
    }
  }

  /// Classify user queries into specific categories
  static Future<Map<String, dynamic>> _classifyQuery(String userInput) async {
    try {
      final classificationPrompt = """
Analyze this user query for an eCommerce app and classify it. Return a JSON object with boolean values for each category:

User Query: "$userInput"

Categories:
- greeting: Basic greetings (hi, hello, hey)
- goodbye: Farewell messages (bye, goodbye, thanks)
- app_info: Questions about the app itself
- product_search: Looking for specific products
- category_browse: Asking about product categories
- price_inquiry: Questions about pricing, costs, budgets
- recommendations: Asking for product suggestions
- comparison: Comparing multiple products
- availability_check: Asking if products are in stock
- order_help: Questions about ordering process
- shipping_info: Questions about delivery/shipping
- return_policy: Questions about returns/exchanges
- payment_methods: Questions about payment options
- account_help: Questions about user account
- technical_support: Technical issues or app problems
- cart_info: Questions about shopping cart, cart items, cart status
- order_status: Questions about order history, tracking, my orders
- wishlist_info: Questions about wishlist, saved items
- address_info: Questions about delivery addresses, address management

Return ONLY valid JSON format like: {"greeting": true, "product_search": false, ...}
""";

      final response = await _classifierModel
          .generateContent([Content.text(classificationPrompt)]);
      final result = response.text?.trim() ?? '{}';

      String cleanedResult = _cleanJsonResponse(result);
      return json.decode(cleanedResult);
    } catch (e) {
      print("Classification error: $e");
      return _fallbackClassification(userInput);
    }
  }

  /// Handle immediate responses for common queries
  static Future<String?> _handleQuickResponses(
      String userInput, BuildContext context,
      {String? userId}) async {
    final lower = userInput.toLowerCase().trim();

    // Greeting responses
    if (RegExp(r'\b(hi|hello|hey|good morning|good afternoon|good evening)\b')
        .hasMatch(lower)) {
      return "Hello! 👋 Welcome to Flipto! I'm your shopping assistant. How can I help you find the perfect products today?";
    }

    // Goodbye responses
    if (RegExp(r'\b(bye|goodbye|see you|thanks for help)\b').hasMatch(lower)) {
      return "Thank you for shopping with Flipto! 🛍️ Feel free to ask me anything anytime. Happy shopping!";
    }

    // App info requests
    if (RegExp(r'\b(what is flipto|about flipto|tell me about|app info)\b')
        .hasMatch(lower)) {
      return """
🛍️ **Flipto - Your Ultimate Shopping Destination**

✨ **Key Features:**
• Browse thousands of products across categories
• Smart search with AI recommendations
• Free shipping on orders above ₹500
• 30-day return policy
• Secure payment options (UPI, Cards, COD)
• 24/7 customer support

What would you like to explore today?
""";
    }

    // Cart-related quick responses
    if (RegExp(r'\b(my cart|cart items|shopping cart|cart status)\b')
        .hasMatch(lower)) {
      if (userId != null) {
        try {
          final cartItems = await ApiService().searchCart(userId);
          final cartCount = cartItems.length;
          final totalValue = _calculateCartTotal(cartItems);

          return """
🛒 **Your Cart Status:**

📦 **Items in Cart:** $cartCount ${cartCount == 1 ? 'item' : 'items'}
💰 **Total Value:** ₹${totalValue.toStringAsFixed(0)}

${cartCount > 0 ? '✅ Ready to checkout!\n🔗 **Go to Cart:** ${TextButton(
                  child: Text('My Cart'),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => CartScreen()));
                  },
                )}' : '🛍️ Your cart is empty. Start shopping now!'}

Need help finding something specific?
""";
        } catch (e) {
          return "🛒 Having trouble accessing your cart right now. Please try again!\n\n🔗 **Go to Cart:** [Open Cart Screen](/cart)";
        }
      } else {
        return "🛒 Please sign in to view your cart items.\n\n🔗 **Go to Cart:** [Open Cart Screen](/cart)";
      }
    }

    return null;
  }

  /// Fetch relevant data based on query classification
  static Future<Map<String, dynamic>> _fetchRelevantData(
      String userInput, Map<String, dynamic> classification,
      {String? userId}) async {
    final Map<String, dynamic> contextData = {};

    try {
      // Always fetch categories for context
      final categories = await ApiService.fetchCategories();
      contextData['categories'] = categories;

      // Handle cart information requests
      if (classification['cart_info'] == true && userId != null) {
        try {
          final cartItems = await ApiService().searchCart(userId);
          contextData['cartItems'] = cartItems;
          contextData['cartCount'] = cartItems.length;
          contextData['cartTotal'] = _calculateCartTotal(cartItems);
        } catch (e) {
          contextData['cartError'] = 'Unable to fetch cart data';
        }
      }

      // Handle product search queries
      if (classification['product_search'] == true) {
        final searchQuery = _extractSearchTerms(userInput);
        if (searchQuery.isNotEmpty) {
          final searchResults = await ApiService.searchProducts(searchQuery);
          contextData['searchResults'] = searchResults;
          contextData['searchQuery'] = searchQuery;
        }
      }

      // Handle category browsing
      if (classification['category_browse'] == true) {
        // Categories already fetched above
        contextData['showAllCategories'] = true;
      }

      // Handle recommendations
      if (classification['recommendations'] == true) {
        final products = await ApiService.fetchProducts();
        contextData['allProducts'] = products;
        contextData['needsRecommendations'] = true;
      }

      // Handle price inquiries
      if (classification['price_inquiry'] == true) {
        final products = await ApiService.fetchProducts();
        contextData['priceData'] = _analyzePricing(products);
        final priceRange = _extractPriceRange(userInput);
        if (priceRange != null) {
          contextData['priceFilteredProducts'] =
              _filterByPrice(products, priceRange);
        }
      }

      // Handle availability checks
      if (classification['availability_check'] == true) {
        final searchQuery = _extractSearchTerms(userInput);
        if (searchQuery.isNotEmpty) {
          final searchResults = await ApiService.searchProducts(searchQuery);
          contextData['availabilityResults'] = searchResults;
        }
      }
    } catch (e) {
      print('Error fetching context data: $e');
      contextData['error'] = 'Some data temporarily unavailable';
    }

    return contextData;
  }

  /// Generate contextual AI response
  static Future<String> _generateContextualResponse(
      String userInput,
      Map<String, dynamic> classification,
      Map<String, dynamic> contextData) async {
    // Handle specific query types with direct responses
    if (classification['shipping_info'] == true) {
      return _getShippingInfo();
    }

    if (classification['return_policy'] == true) {
      return _getReturnPolicyInfo();
    }

    if (classification['payment_methods'] == true) {
      return _getPaymentMethodsInfo();
    }

    if (classification['order_help'] == true) {
      return _getOrderHelpInfo();
    }

    // Handle navigation-related queries
    if (classification['order_status'] == true) {
      return _getOrderStatusInfo();
    }

    if (classification['wishlist_info'] == true) {
      return _getWishlistInfo();
    }

    if (classification['address_info'] == true) {
      return _getAddressInfo();
    }

    if (classification['cart_info'] == true) {
      return _getCartInfoResponse(contextData);
    }

    // Generate AI response for complex queries
    final systemPrompt =
        _buildSystemPrompt(userInput, classification, contextData);

    try {
      final response =
          await _model.generateContent([Content.text(systemPrompt)]);
      return response.text ?? _getFallbackResponse(userInput);
    } catch (e) {
      print('AI generation error: $e');
      return _generateFallbackResponse(classification, contextData);
    }
  }

  /// Build comprehensive system prompt for AI
  static String _buildSystemPrompt(String userInput,
      Map<String, dynamic> classification, Map<String, dynamic> contextData) {
    final buffer = StringBuffer();

    // System context
    buffer.writeln(
        "You are an AI shopping assistant for Flipto, an Indian eCommerce app.");
    buffer.writeln(
        "IMPORTANT: Always use Indian Rupee (₹) for prices and be culturally relevant for Indian users.");
    buffer.writeln();

    // App policies
    buffer.writeln("APP POLICIES:");
    _appContext['policies'].forEach((key, value) {
      if (value is List) {
        buffer.writeln("• $key: ${value.join(', ')}");
      } else {
        buffer.writeln("• $key: $value");
      }
    });
    buffer.writeln();

    // Available categories
    if (contextData['categories'] != null) {
      final categories = contextData['categories'] as List;
      buffer.writeln("AVAILABLE PRODUCT CATEGORIES:");
      for (var category in categories) {
        buffer.writeln("• ${category.name}");
      }
      buffer.writeln();
    }

    // Context-specific data
    _addContextSpecificData(buffer, classification, contextData);

    // User query
    buffer.writeln("USER QUERY: \"$userInput\"");
    buffer.writeln();

    // Response guidelines
    buffer.writeln("RESPONSE GUIDELINES:");
    buffer.writeln("1. Be helpful, friendly, and enthusiastic about shopping");
    buffer
        .writeln("2. Provide specific product names and prices when available");
    buffer.writeln("3. Always mention relevant app features and benefits");
    buffer.writeln("4. Keep responses under 200 words but comprehensive");
    buffer.writeln("5. Use emojis appropriately for better engagement");
    buffer.writeln(
        "6. If no exact matches, suggest similar products or categories");
    buffer.writeln("7. Always encourage users to explore more");
    buffer.writeln(
        "8. Include relevant screen navigation links when appropriate");

    return buffer.toString();
  }

  /// Add context-specific data to prompt
  static void _addContextSpecificData(StringBuffer buffer,
      Map<String, dynamic> classification, Map<String, dynamic> contextData) {
    // Cart information
    if (contextData['cartItems'] != null) {
      final cartItems = contextData['cartItems'] as List<CartItem>;
      final cartCount = contextData['cartCount'] as int;
      final cartTotal = contextData['cartTotal'] as double;

      buffer.writeln("USER'S CART INFORMATION:");
      buffer.writeln("• Items in cart: $cartCount");
      buffer.writeln("• Cart total: ₹${cartTotal.toStringAsFixed(0)}");

      if (cartItems.isNotEmpty) {
        buffer.writeln("• Recent items:");
        for (var item in cartItems.take(3)) {
          buffer.writeln(
              "  - ${item.name} (Qty: ${item.quantity}) - ₹${item.price}");
        }
      }
      buffer.writeln();
    }

    // Search results
    if (contextData['searchResults'] != null) {
      final results = contextData['searchResults'] as List;
      if (results.isNotEmpty) {
        buffer.writeln("SEARCH RESULTS FOR '${contextData['searchQuery']}':");
        for (var product in results.take(8)) {
          final name = product['product_name'] ?? 'Unknown';
          final price = product['product_price'] ?? 'N/A';
          final category = product['gender_category'] ?? 'General';
          buffer.writeln("• $name - ₹$price ($category)");
        }
        buffer.writeln();
      }
    }

    // Price filtered products
    if (contextData['priceFilteredProducts'] != null) {
      final products =
          contextData['priceFilteredProducts'] as List<Subcategory>;
      if (products.isNotEmpty) {
        buffer.writeln("PRODUCTS IN YOUR PRICE RANGE:");
        for (var product in products.take(6)) {
          buffer.writeln("• ${product.name} - ₹${product.price}");
        }
        buffer.writeln();
      }
    }

    // Price statistics
    if (contextData['priceData'] != null) {
      final priceData = contextData['priceData'] as Map<String, dynamic>;
      buffer.writeln("PRICE INSIGHTS:");
      buffer.writeln(
          "• Price range: ₹${priceData['minPrice']} - ₹${priceData['maxPrice']}");
      buffer.writeln("• Average price: ₹${priceData['avgPrice']}");
      buffer.writeln(
          "• Budget options (under ₹1000): ${priceData['budgetItems']} items");
      buffer.writeln();
    }

    // Availability results
    if (contextData['availabilityResults'] != null) {
      final results = contextData['availabilityResults'] as List;
      buffer.writeln("AVAILABILITY CHECK:");
      if (results.isNotEmpty) {
        buffer.writeln("✅ Found ${results.length} matching products in stock");
        for (var product in results.take(5)) {
          buffer.writeln(
              "• ${product['product_name']} - ₹${product['product_price']}");
        }
      } else {
        buffer.writeln(
            "❌ No exact matches found, but I can suggest alternatives");
      }
      buffer.writeln();
    }
  }

  /// Helper methods for specific info types
  static String _getShippingInfo() {
    return """
🚚 **Flipto Shipping Information:**

✅ **Free Shipping:** Orders above ₹500
💰 **Shipping Charges:** ₹50 for orders below ₹500
⚡ **Delivery Time:**
  • Same-day delivery in metro cities
  • 2-3 days in major cities
  • 4-7 days in other locations

📍 **Coverage:** Pan-India delivery available
📦 **Tracking:** Real-time order tracking in the app

🔗 **Track Orders:** [View My Orders](/orders)

Need help with a specific order? Just ask!
""";
  }

  static String _getReturnPolicyInfo() {
    return """
🔄 **Flipto Return Policy:**

✅ **30-Day Returns:** Hassle-free returns within 30 days
💯 **Full Refund:** Original payment method refund
📋 **Easy Process:**
  1. Go to 'My Orders' in the app
  2. Select the item to return
  3. Choose return reason
  4. Schedule free pickup

🚫 **Non-returnable:** Personal care items, food products
⚡ **Refund Time:** 3-5 business days after pickup

🔗 **Manage Returns:** [View My Orders](/orders)

Questions about a specific return? I'm here to help!
""";
  }

  static String _getPaymentMethodsInfo() {
    return """
💳 **Flipto Payment Options:**

✅ **Available Methods:**
  • 💳 Credit/Debit Cards (Visa, Mastercard, RuPay)
  • 📱 UPI (PhonePe, Paytm, GPay, etc.)
  • 🏦 Razorpay (Multiple payment options)
  • 💰 Cash on Delivery (COD)
  • 🎫 Digital Wallets (Paytm, PhonePe)

🔒 **Security:** 256-bit SSL encryption
💯 **Safety:** PCI DSS compliant payments
🚫 **COD Limit:** Available for orders up to ₹5,000

Need help with payment issues? Let me know!
""";
  }

  static String _getOrderHelpInfo() {
    return """
🛍️ **How to Place an Order on Flipto:**

**Step-by-Step Process:**
1. 🔍 Search or browse products
2. 📱 Select product & choose size/color
3. 🛒 Add to cart or Buy Now
4. 📍 Enter delivery address
5. 💳 Choose payment method
6. ✅ Review & confirm order

**After Ordering:**
• 📧 Instant order confirmation
• 📱 Real-time tracking updates
• 🚚 Delivery notifications

**Need Help?**
• 🔗 **Track orders:** [View My Orders](/orders)
• 🔗 **Manage addresses:** [Edit Addresses](/addresses)
• Contact support for issues
• Easy cancellation before dispatch

Ready to start shopping? What are you looking for?
""";
  }

  static String _getOrderStatusInfo() {
    return """
📦 **Order Status & Tracking:**

✅ **Check Your Orders:**
• View all current and past orders
• Real-time tracking updates
• Order status notifications
• Download invoices

📱 **Quick Actions:**
• Cancel orders (before dispatch)
• Return/Exchange items
• Rate and review products
• Reorder favorite items

🔗 **View Orders:** [Open My Orders](/orders)

Need help with a specific order? Just tell me the order number!
""";
  }

  static String _getWishlistInfo() {
    return """
❤️ **Your Wishlist:**

✨ **Wishlist Features:**
• Save products for later
• Track price drops
• Get stock alerts
• Easy add to cart
• Share with friends

🔔 **Smart Notifications:**
• Price drop alerts
• Back in stock notifications
• Sale reminders
• Personalized deals

🔗 **View Wishlist:** [Open Wishlist](/wishlist)

Want to add something to your wishlist? Just let me know!
""";
  }

  static String _getAddressInfo() {
    return """
📍 **Address Management:**

🏠 **Manage Addresses:**
• Add multiple delivery addresses
• Set default address
• Edit existing addresses
• Add landmarks for easy delivery

✅ **Address Types:**
• Home
• Office
• Other (custom label)

📱 **Quick Features:**
• GPS location picker
• Address validation
• Delivery time estimation
• Special delivery instructions

🔗 **Manage Addresses:** [Edit Addresses](/addresses)

Need help adding or updating an address?
""";
  }

  static String _getCartInfoResponse(Map<String, dynamic> contextData) {
    if (contextData['cartError'] != null) {
      return """
🛒 **Cart Status:**

⚠️ Unable to fetch cart details right now. Please try again!

🔗 **Go to Cart:** [Open Cart Screen](/cart)

You can also:
• 🔍 Continue shopping
• 📦 Check your orders
• ❤️ View your wishlist
""";
    }

    if (contextData['cartItems'] != null) {
      final cartItems = contextData['cartItems'] as List<CartItem>;
      final cartCount = contextData['cartCount'] as int;
      final cartTotal = contextData['cartTotal'] as double;

      if (cartCount == 0) {
        return """
🛒 **Your Cart is Empty**

🛍️ Start shopping now! Here are some suggestions:
• Browse trending products
• Check out daily deals
• Search for specific items

🔗 **Start Shopping:** [Browse Products](/)
🔗 **View Cart:** [Open Cart Screen](/cart)
""";
      }

      final buffer = StringBuffer();
      buffer.writeln("🛒 **Your Cart Summary:**\n");
      buffer.writeln(
          "📦 **Items:** $cartCount ${cartCount == 1 ? 'item' : 'items'}");
      buffer.writeln("💰 **Total Value:** ₹${cartTotal.toStringAsFixed(0)}\n");

      if (cartItems.isNotEmpty) {
        buffer.writeln("🛍️ **Recent Items:**");
        for (var item in cartItems.take(3)) {
          buffer.writeln("• ${item.name} (${item.quantity}x) - ₹${item.price}");
        }
        if (cartItems.length > 3) {
          buffer.writeln("• ... and ${cartItems.length - 3} more items");
        }
      }

      buffer.writeln("\n✅ Ready to checkout!");
      buffer.writeln("🔗 **Go to Cart:** [Open Cart Screen](/cart)");

      return buffer.toString();
    }

    return """
🛒 **Cart Information:**

Please sign in to view your cart items.

🔗 **Go to Cart:** [Open Cart Screen](/cart)
🔗 **Sign In:** [Open Account](/account)
""";
  }

  /// Utility methods
  static String _extractSearchTerms(String input) {
    // Remove common filler words and extract key terms
    final cleanInput = input
        .toLowerCase()
        .replaceAll(
            RegExp(
                r'\b(i want|i need|looking for|show me|find|search|get me)\b'),
            '')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();

    return cleanInput.isNotEmpty ? cleanInput : input;
  }

  static Map<String, double>? _extractPriceRange(String input) {
    final pricePattern = RegExp(r'₹?(\d+)');
    final matches = pricePattern.allMatches(input.toLowerCase());

    if (matches.isEmpty) return null;

    final prices = matches.map((m) => double.parse(m.group(1)!)).toList();

    if (input.contains('under') ||
        input.contains('below') ||
        input.contains('less than')) {
      return {'min': 0, 'max': prices.first};
    } else if (input.contains('above') ||
        input.contains('over') ||
        input.contains('more than')) {
      return {'min': prices.first, 'max': 100000};
    } else if (prices.length >= 2) {
      return {'min': prices.first, 'max': prices.last};
    }

    return null;
  }

  static List<Subcategory> _filterByPrice(
      List<Subcategory> products, Map<String, double> range) {
    return products.where((product) {
      final price =
          double.tryParse(product.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      return price >= range['min']! && price <= range['max']!;
    }).toList();
  }

  static Map<String, dynamic> _analyzePricing(List<Subcategory> products) {
    final prices = products
        .map((p) =>
            double.tryParse(p.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0)
        .where((p) => p > 0)
        .toList();

    if (prices.isEmpty) return {};

    prices.sort();
    return {
      'minPrice': prices.first.toInt(),
      'maxPrice': prices.last.toInt(),
      'avgPrice': (prices.reduce((a, b) => a + b) / prices.length).round(),
      'budgetItems': prices.where((p) => p < 1000).length,
      'premiumItems': prices.where((p) => p > 5000).length,
    };
  }

  /// Calculate cart total value
  static double _calculateCartTotal(List<CartItem> cartItems) {
    return cartItems.fold(0.0, (total, item) {
      final price =
          double.tryParse(item.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      return total + (price);
    });
  }

  /// Fallback methods
  static Map<String, dynamic> _fallbackClassification(String input) {
    final lower = input.toLowerCase();
    return {
      "greeting": RegExp(r'\b(hi|hello|hey)\b').hasMatch(lower),
      "goodbye": RegExp(r'\b(bye|goodbye|thanks)\b').hasMatch(lower),
      "product_search": RegExp(r'\b(find|search|looking for|show|want|need)\b')
          .hasMatch(lower),
      "category_browse":
          RegExp(r'\b(category|categories|browse|sections)\b').hasMatch(lower),
      "price_inquiry":
          RegExp(r'\b(price|cost|cheap|expensive|₹|budget)\b').hasMatch(lower),
      "recommendations":
          RegExp(r'\b(recommend|suggest|best|popular)\b').hasMatch(lower),
      "availability_check":
          RegExp(r'\b(available|stock|do you have|in stock)\b').hasMatch(lower),
      "shipping_info":
          RegExp(r'\b(shipping|delivery|dispatch|courier)\b').hasMatch(lower),
      "return_policy":
          RegExp(r'\b(return|refund|exchange|cancel)\b').hasMatch(lower),
      "payment_methods":
          RegExp(r'\b(payment|pay|card|upi|cod|cash)\b').hasMatch(lower),
      "cart_info":
          RegExp(r'\b(cart|shopping cart|my cart|cart items|cart status)\b')
              .hasMatch(lower),
      "order_status": RegExp(
              r'\b(orders|my orders|order status|order history|track|tracking)\b')
          .hasMatch(lower),
      "wishlist_info":
          RegExp(r'\b(wishlist|favorites|saved|wish list)\b').hasMatch(lower),
      "address_info":
          RegExp(r'\b(address|addresses|delivery address|location)\b')
              .hasMatch(lower),
    };
  }

  static String _generateFallbackResponse(
      Map<String, dynamic> classification, Map<String, dynamic> contextData) {
    if (classification['product_search'] == true &&
        contextData['searchResults'] != null) {
      final results = contextData['searchResults'] as List;
      if (results.isNotEmpty) {
        return "I found ${results.length} products for you! Here are some top matches:\n\n" +
            results
                .take(3)
                .map((p) => "• ${p['product_name']} - ₹${p['product_price']}")
                .join('\n') +
            "\n\nWould you like to see more options?";
      }
    }

    return "I'm here to help you shop on Flipto! You can ask me about products, prices, categories, or anything else. What are you looking for today? 🛍️";
  }

  static String _getFallbackResponse(String input) {
    return "I'm having trouble processing that right now, but I'm here to help! Try asking me about:\n\n" +
        "🔍 Product searches\n" +
        "💰 Prices and deals\n" +
        "🛒 Cart status\n" +
        "📦 Order tracking\n" +
        "🚚 Shipping info\n" +
        "🔄 Returns policy\n" +
        "💳 Payment methods\n\n" +
        "What would you like to know about shopping on Flipto?";
  }

  static String _cleanJsonResponse(String response) {
    return response.replaceAll('```json', '').replaceAll('```', '').trim();
  }
}
