import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/services/voice_assistant_service.dart';
import '../core/services/voice_command_processor.dart';
import '../providers/task_provider.dart';
import '../providers/meeting_provider.dart';
import '../providers/lead_provider.dart';
import '../providers/dashboard_provider.dart';

class VoiceAssistantModal extends StatefulWidget {
  const VoiceAssistantModal({super.key});

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final VoiceAssistantService _voiceService = VoiceAssistantService.instance;

  String _userSpeech = '';
  String _assistantSpeech = "Hello! I am your OfflineTrack Voice Assistant. I can observe what you did, brief you on today's schedule, schedule meetings, or set offline reminders.";
  String? _lastActionDetails;
  bool _isProcessing = false;

  late AnimationController _waveController;

  final List<String> _quickPrompts = [
    "What do I have to do today?",
    "Observe what I did",
    "Any overdue alerts?",
    "Remind me to review contracts tomorrow",
    "Schedule meeting with client",
    "Add lead John from Apex Tech",
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _textController.dispose();
    _voiceService.stopSpeaking();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _handleUserCommand(String command) async {
    if (command.trim().isEmpty) return;

    setState(() {
      _userSpeech = command;
      _isProcessing = true;
    });

    final taskProvider = context.read<TaskProvider>();
    final meetingProvider = context.read<MeetingProvider>();
    final leadProvider = context.read<LeadProvider>();
    final dashboardProvider = context.read<DashboardProvider>();

    final result = await VoiceCommandProcessor.processCommand(
      rawCommand: command,
      taskProvider: taskProvider,
      meetingProvider: meetingProvider,
      leadProvider: leadProvider,
      dashboardProvider: dashboardProvider,
    );

    // Refresh dashboard to reflect any newly created items
    dashboardProvider.refreshDashboard();

    setState(() {
      _assistantSpeech = result.speechResponse;
      _lastActionDetails = result.details;
      _isProcessing = false;
    });

    // Assistant speaks the response aloud!
    await _voiceService.speak(result.speechResponse);
  }

  void _toggleListening() async {
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
      setState(() {});
    } else {
      if (_voiceService.isSpeaking) {
        await _voiceService.stopSpeaking();
      }

      await _voiceService.startListening(
        onResult: (words) {
          setState(() {
            _userSpeech = words;
          });
        },
        onStateChange: (state) {
          setState(() {});
          if (state == VoiceState.processing && _userSpeech.isNotEmpty) {
            _handleUserCommand(_userSpeech);
          }
        },
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _voiceService.isListening;
    final isSpeaking = _voiceService.isSpeaking;

    String statusText = "Ready to assist offline";
    Color statusColor = AppTheme.accentCyan;

    if (isListening) {
      statusText = "Listening to your voice...";
      statusColor = AppTheme.accentRose;
    } else if (_isProcessing) {
      statusText = "Processing command offline...";
      statusColor = AppTheme.accentAmber;
    } else if (isSpeaking) {
      statusText = "Voice Assistant Speaking...";
      statusColor = AppTheme.accentEmerald;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppTheme.cardBorderDark, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryViolet.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryGlow, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Offline Voice Assistant',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const Divider(color: AppTheme.cardBorderDark, height: 24),

          // Conversation Scroll Area
          Expanded(
            child: ListView(
              children: [
                // Animated Soundwave Visualizer
                Center(
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(12, (index) {
                        return AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            double heightMultiplier = 0.2;
                            if (isListening || isSpeaking) {
                              heightMultiplier = ((index % 3 + 1) * 0.3 * _waveController.value).clamp(0.2, 1.0);
                            }
                            return Container(
                              width: 4,
                              height: 40 * heightMultiplier,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: (isListening || isSpeaking) ? statusColor : AppTheme.cardBorderDark,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ),

                // User Speech Bubble (if any)
                if (_userSpeech.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryViolet.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(18).copyWith(bottomRight: Radius.zero),
                        border: Border.all(color: AppTheme.primaryViolet.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        _userSpeech,
                        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),

                // Assistant Response Bubble
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(18).copyWith(bottomLeft: Radius.zero),
                      border: Border.all(color: AppTheme.cardBorderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.volume_up_rounded, size: 16, color: AppTheme.accentCyan),
                            const SizedBox(width: 8),
                            const Text(
                              'Voice Assistant',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.accentCyan),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.replay_rounded, size: 16, color: AppTheme.textMuted),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Speak again',
                              onPressed: () => _voiceService.speak(_assistantSpeech),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _assistantSpeech,
                          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.45),
                        ),
                        if (_lastActionDetails != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.accentEmerald.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.accentEmerald.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.accentEmerald),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _lastActionDetails!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.accentEmerald,
                                    ),
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

                const SizedBox(height: 16),

                // Quick Suggestion Chips
                const Text(
                  'Quick Voice Actions',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickPrompts.map((prompt) {
                    return InkWell(
                      onTap: () => _handleUserCommand(prompt),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.cardBorderDark),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, size: 14, color: AppTheme.accentAmber),
                            const SizedBox(width: 6),
                            Text(
                              prompt,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Bottom Bar: Mic Trigger & Text Input
          Row(
            children: [
              // Large Mic Button
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isListening ? AppTheme.accentRose : AppTheme.primaryViolet,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isListening ? AppTheme.accentRose : AppTheme.primaryViolet).withValues(alpha: 0.4),
                        blurRadius: 14,
                        spreadRadius: isListening ? 4 : 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Text Field fallback
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Or type a command / reminder...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppTheme.accentCyan, size: 20),
                      onPressed: () {
                        final text = _textController.text.trim();
                        if (text.isNotEmpty) {
                          _handleUserCommand(text);
                          _textController.clear();
                        }
                      },
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      _handleUserCommand(val.trim());
                      _textController.clear();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
