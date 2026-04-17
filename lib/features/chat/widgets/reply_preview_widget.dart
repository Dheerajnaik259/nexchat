import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/message_model.dart';

/// Preview bar shown above input when replying to a message
class ReplyPreviewWidget extends StatelessWidget {
  final MessageModel message;
  final String senderName;
  final bool isMe;
  final VoidCallback onClose;

  const ReplyPreviewWidget({
    super.key,
    required this.message,
    required this.senderName,
    required this.isMe,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgDarkTertiary,
        border: Border(
          top: BorderSide(
            color: AppColors.neonPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left accent bar
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: isMe ? AppColors.neonPurple : AppColors.neonCyan,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),

          // Reply content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isMe ? 'You' : senderName,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isMe ? AppColors.neonPurple : AppColors.neonCyan,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getPreviewText(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Type icon for media messages
          if (message.type != MessageType.text) ...[
            const SizedBox(width: 8),
            _buildTypeIcon(),
          ],

          // Close button
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPreviewText() {
    if (message.isDeleted) return 'This message was deleted';
    switch (message.type) {
      case MessageType.image:
        return '📸 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.document:
        return '📄 Document';
      case MessageType.sticker:
        return '🎨 Sticker';
      case MessageType.gif:
        return 'GIF';
      case MessageType.location:
        return '📍 Location';
      case MessageType.contact:
        return '👤 Contact';
      case MessageType.poll:
        return '📊 Poll';
      case MessageType.system:
        return message.encryptedText;
      case MessageType.text:
        return message.encryptedText;
    }
  }

  Widget _buildTypeIcon() {
    IconData icon;
    switch (message.type) {
      case MessageType.image:
        icon = Icons.photo_rounded;
        break;
      case MessageType.video:
        icon = Icons.videocam_rounded;
        break;
      case MessageType.audio:
        icon = Icons.headphones_rounded;
        break;
      case MessageType.document:
        icon = Icons.description_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }
    return Icon(icon, size: 18, color: AppColors.textTertiary);
  }
}
