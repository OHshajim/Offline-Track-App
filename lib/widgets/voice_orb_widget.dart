import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/services/voice_assistant_service.dart';
import 'voice_assistant_modal.dart';

/// Futuristic Holographic Voice Assistant Orb Widget
class VoiceOrbWidget extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;

  const VoiceOrbWidget({
    super.key,
    this.size = 56.0,
    this.onTap,
  });

  @override
  State<VoiceOrbWidget> createState() => _VoiceOrbWidgetState();
}

class _VoiceOrbWidgetState extends State<VoiceOrbWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openVoiceModal() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceAssistantModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = VoiceAssistantService.instance;
    final isListening = voiceService.isListening;
    final isSpeaking = voiceService.isSpeaking;

    Color coreColor = AppTheme.primaryCyan;
    Color glowColor = AppTheme.cyanGlow;

    if (isListening) {
      coreColor = AppTheme.accentRose;
      glowColor = AppTheme.accentAmber;
    } else if (isSpeaking) {
      coreColor = AppTheme.accentEmerald;
      glowColor = AppTheme.primaryCyan;
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return GestureDetector(
          onTap: _openVoiceModal,
          child: Transform.scale(
            scale: (isListening || isSpeaking) ? _pulseAnimation.value * 1.08 : _pulseAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    coreColor,
                    const Color(0xFF060B14),
                  ],
                  stops: const [0.25, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: _glowAnimation.value * 0.6),
                    blurRadius: 22,
                    spreadRadius: (isListening || isSpeaking) ? 4 : 1,
                  ),
                  BoxShadow(
                    color: coreColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  isListening
                      ? Icons.mic_rounded
                      : (isSpeaking ? Icons.volume_up_rounded : Icons.graphic_eq_rounded),
                  color: Colors.white,
                  size: widget.size * 0.48,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
