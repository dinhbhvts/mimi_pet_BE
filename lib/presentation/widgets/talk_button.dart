import 'package:flutter/material.dart';

/// Nút micro chính - bé bấm vào để nói tiếng Anh cho Mimi nghe.
/// Tự "đập nhẹ" (pulse) khi đang lắng nghe để bé biết Mimi đang chờ mình nói.
class TalkButton extends StatefulWidget {
  final bool isListening;
  final bool enabled;
  final VoidCallback onTap;
  final String label;

  const TalkButton({
    super.key,
    required this.isListening,
    required this.onTap,
    this.enabled = true,
    this.label = 'Tap to talk',
  });

  @override
  State<TalkButton> createState() => _TalkButtonState();
}

class _TalkButtonState extends State<TalkButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = widget.isListening ? 1 + (_pulseController.value * 0.08) : 1.0;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
          decoration: BoxDecoration(
            color: widget.enabled ? const Color(0xFF7C5CFC) : const Color(0xFFBBBBBB),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
