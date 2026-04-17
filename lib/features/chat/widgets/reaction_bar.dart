import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Floating emoji reaction bar for messages
class ReactionBar extends StatefulWidget {
  final Map<String, String> currentReactions; // userId → emoji
  final String currentUserId;
  final Function(String emoji) onReactionSelected;

  const ReactionBar({
    super.key,
    required this.currentReactions,
    required this.currentUserId,
    required this.onReactionSelected,
  });

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar>
    with SingleTickerProviderStateMixin {
  static const _quickEmojis = ['❤️', '😂', '😮', '😢', '🙏', '👍'];
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myReaction = widget.currentReactions[widget.currentUserId];

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgDarkTertiary,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._quickEmojis.map((emoji) {
                final isSelected = myReaction == emoji;
                return GestureDetector(
                  onTap: () => widget.onReactionSelected(emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.neonPurple.withValues(alpha: 0.25)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      emoji,
                      style: TextStyle(
                        fontSize: isSelected ? 26 : 22,
                      ),
                    ),
                  ),
                );
              }),
              // More emoji button
              GestureDetector(
                onTap: () {
                  // TODO: open full emoji picker
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small inline reaction display below message bubble
class ReactionChips extends StatelessWidget {
  final Map<String, String> reactions; // userId → emoji
  final VoidCallback? onTap;

  const ReactionChips({
    super.key,
    required this.reactions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions by emoji
    final Map<String, int> grouped = {};
    for (final emoji in reactions.values) {
      grouped[emoji] = (grouped[emoji] ?? 0) + 1;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        child: Wrap(
          spacing: 4,
          children: grouped.entries.map((entry) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.bgDarkTertiary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 14)),
                  if (entry.value > 1) ...[
                    const SizedBox(width: 3),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
