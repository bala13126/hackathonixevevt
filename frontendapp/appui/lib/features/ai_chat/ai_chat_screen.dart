import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/backend_api_service.dart';
import '../../models/chat_message.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      text:
          'Hello! I can help you report a missing person, suggest next steps, or review case details. How can I help today?',
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
    ),
  ];
  bool _isTyping = false;
  bool _speechReady = false;
  bool _isListening = false;
  String _speechTranscript = '';
  Completer<String>? _speechCompleter;

  static const String _latestVoiceDetailsKey = 'latest_voice_details';
  static const String _latestVoiceTextKey = 'latest_voice_text';
  static const String _latestVoiceTimeKey = 'latest_voice_time';

  final List<String> _suggestions = [
    'Report a missing person',
    'How to submit a tip',
    'Show nearby cases',
    'Emergency steps',
    'What info do I need to report?',
    'Photo requirements',
    'How to search safely',
    'How to track my case',
  ];

  @override
  void dispose() {
    _speech.stop();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speech error: ${error.errorMsg}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );

    if (mounted) {
      setState(() {
        _speechReady = available;
      });
    }
  }

  Future<void> _sendMessage([String? text, bool skipParse = false]) async {
    final content = text ?? _messageController.text.trim();
    if (content.isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: content,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _messageController.clear();

    try {
      final reply = await BackendApiService.aiChat(text: userMessage.text);
      if (!mounted) return;
      final aiResponse = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: reply.isEmpty
            ? 'Thanks. Let me know if you want to report a missing person.'
            : reply,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiResponse);
        _isTyping = false;
      });

      if (!skipParse) {
        await _storeParsedDetails(userMessage.text);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI assistant failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _startListening() async {
    if (_isListening) return;
    if (!_speechReady) {
      await _initSpeech();
    }
    if (!_speechReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone not available.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() {
      _isListening = true;
    });

    final transcript = await _captureSpeechText();
    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    if (transcript.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No speech detected.')));
      return;
    }

    await _handleVoiceMessage(transcript);
  }

  Future<String> _captureSpeechText() async {
    final completer = Completer<String>();
    _speechCompleter = completer;
    _speechTranscript = '';

    await _speech.listen(
      onResult: (result) {
        _speechTranscript = result.recognizedWords;
        if (result.finalResult && !completer.isCompleted) {
          completer.complete(_speechTranscript);
        }
      },
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 10),
    );

    Future<void>.delayed(const Duration(seconds: 60)).then((_) {
      if (!completer.isCompleted) {
        completer.complete(_speechTranscript);
      }
    });

    final result = await completer.future;
    _speechCompleter = null;
    await _speech.stop();
    return result.trim();
  }

  Future<void> _stopListening() async {
    if (!_speech.isListening) return;
    await _speech.stop();
    if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
      _speechCompleter!.complete(_speechTranscript);
    }
  }

  Future<void> _handleVoiceMessage(String transcript) async {
    await _sendMessage(transcript, true);

    try {
      final parsed = await BackendApiService.parseVoiceReport(text: transcript);
      final prefs = await SharedPreferences.getInstance();
      if (!_hasAnyParsedValue(parsed)) {
        parsed['description'] = transcript;
      }
      await prefs.setString(_latestVoiceDetailsKey, jsonEncode(parsed));
      await prefs.setString(_latestVoiceTextKey, transcript);
      await prefs.setInt(
        _latestVoiceTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (error) {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _latestVoiceDetailsKey,
        jsonEncode({'description': transcript}),
      );
      await prefs.setString(_latestVoiceTextKey, transcript);
      await prefs.setInt(
        _latestVoiceTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice parse failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _storeParsedDetails(String text) async {
    try {
      final parsed = await BackendApiService.parseVoiceReport(text: text);
      final prefs = await SharedPreferences.getInstance();
      if (!_hasAnyParsedValue(parsed)) {
        parsed['description'] = text;
      }
      await prefs.setString(_latestVoiceDetailsKey, jsonEncode(parsed));
      await prefs.setString(_latestVoiceTextKey, text);
      await prefs.setInt(
        _latestVoiceTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _latestVoiceDetailsKey,
        jsonEncode({'description': text}),
      );
      await prefs.setString(_latestVoiceTextKey, text);
      await prefs.setInt(
        _latestVoiceTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  bool _hasAnyParsedValue(Map<String, dynamic> parsed) {
    const keys = [
      'name',
      'age',
      'gender',
      'height',
      'hairColor',
      'eyeColor',
      'clothing',
      'lastSeenLocation',
      'lastSeenTime',
      'description',
      'contactName',
      'contactPhone',
    ];

    for (final key in keys) {
      final value = parsed[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: AppConstants.spacing12),
            const Text('AI Assistant'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.spacing16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          if (_messages.length == 1)
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ActionChip(
                    label: Text(_suggestions[index]),
                    onPressed: () => _sendMessage(_suggestions[index]),
                  );
                },
              ),
            ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing16,
                vertical: AppConstants.spacing8,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacing12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypingDot(0),
                        const SizedBox(width: 4),
                        _buildTypingDot(1),
                        const SizedBox(width: 4),
                        _buildTypingDot(2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (_isListening)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.info.withOpacity(0.08),
              child: Row(
                children: [
                  const Icon(Icons.graphic_eq, color: AppColors.info),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Listening... speak the details clearly.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: _stopListening,
                    child: const Text('Stop'),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(AppConstants.spacing16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.border.withOpacity(0.5)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isListening
                          ? Icons.stop_circle_outlined
                          : Icons.mic_outlined,
                    ),
                    onPressed: _isListening ? _stopListening : _startListening,
                    color: AppColors.primary,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacing8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                      color: AppColors.white,
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

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacing12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.white,
                size: 16,
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF2C2C2C) : AppColors.grey100),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : (isDark ? Colors.white : AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.textSecondary,
        shape: BoxShape.circle,
      ),
    );
  }
}
