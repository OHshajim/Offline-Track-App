import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class InteractiveLogoWidget extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;

  const InteractiveLogoWidget({
    super.key,
    this.size = 38,
    this.onTap,
  });

  @override
  State<InteractiveLogoWidget> createState() => _InteractiveLogoWidgetState();
}

class _InteractiveLogoWidgetState extends State<InteractiveLogoWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _tapScaleController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _tapScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _tapScaleController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _tapScaleController.dispose();
    super.dispose();
  }

  void _handleTap() async {
    _tapScaleController.forward().then((_) => _tapScaleController.reverse());
    // Spin faster briefly on tap
    _rotationController.animateTo(
      _rotationController.value + 0.25,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    ).then((_) => _rotationController.repeat());

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseController, _tapScaleController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: s,
              height: s,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Rotating Halo Ring
                  Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: Container(
                      width: s,
                      height: s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const SweepGradient(
                          colors: [
                            AppTheme.primaryCyan,
                            AppTheme.accentViolet,
                            AppTheme.accentEmerald,
                            AppTheme.primaryCyan,
                          ],
                          stops: [0.0, 0.4, 0.7, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryCyan.withValues(alpha: _glowAnimation.value * 0.5),
                            blurRadius: 10,
                            spreadRadius: 1.5,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Inner Solid Obsidian Core
                  Container(
                    width: s - 4,
                    height: s - 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceDark,
                      border: Border.all(
                        color: AppTheme.primaryCyan.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.offline_bolt_rounded,
                        size: s * 0.55,
                        color: AppTheme.primaryCyan,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
