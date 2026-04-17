import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/avatar_widget.dart';

/// Chat list tile widget — displays a single chat in the chat list
class ChatListTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final String? avatarUrl;
  final int unreadCount;
  final bool isOnline;
  final bool isMuted;
  final bool isPinned;
  final bool isTyping;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ChatListTile({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.avatarUrl,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isMuted = false,
    this.isPinned = false,
    this.isTyping = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // ── Avatar ───────────────────────────────
              AvatarWidget(
                name: name,
                imageUrl: avatarUrl,
                radius: 28,
                showOnlineIndicator: true,
                isOnline: isOnline,
              ),

              const SizedBox(width: 14),

              // ── Content ──────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + time row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTextStyles.chatName.copyWith(
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          time,
                          style: AppTextStyles.chatTime.copyWith(
                            color: unreadCount > 0
                                ? AppColors.neonPurple
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Last message + badges row
                    Row(
                      children: [
                        // Message status icon
                        if (!isTyping) ...[
                          Icon(
                            Icons.done_all_rounded,
                            size: 16,
                            color: unreadCount > 0
                                ? AppColors.textTertiary
                                : AppColors.neonCyan,
                          ),
                          const SizedBox(width: 4),
                        ],

                        // Message preview or typing indicator
                        Expanded(
                          child: isTyping
                              ? Text(
                                  'typing...',
                                  style: AppTextStyles.chatPreview.copyWith(
                                    color: AppColors.neonCyan,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Text(
                                  lastMessage,
                                  style: AppTextStyles.chatPreview.copyWith(
                                    color: unreadCount > 0
                                        ? AppColors.textSecondary
                                        : AppColors.textTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),

                        const SizedBox(width: 8),

                        // Badges: pin, mute, unread
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPinned)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.push_pin_rounded,
                                  size: 14,
                                  color: AppColors.textTertiary.withValues(alpha: 0.5),
                                ),
                              ),
                            if (isMuted)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.volume_off_rounded,
                                  size: 14,
                                  color: AppColors.textTertiary.withValues(alpha: 0.5),
                                ),
                              ),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isMuted
                                      ? AppColors.textTertiary
                                      : AppColors.neonPurple,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
