import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/message_model.dart';

/// A chat message bubble with sent/received styling
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showTail;
  final VoidCallback? onLongPress;
  final String? senderName; // For group chats

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showTail = true,
    this.onLongPress,
    this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return _buildDeletedBubble();
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: EdgeInsets.only(
            left: isMe ? 60 : 8,
            right: isMe ? 8 : 60,
            top: 2,
            bottom: 2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isMe
                ? const LinearGradient(
                    colors: [AppColors.neonPurple, Color(0xFF6C5CE7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isMe ? null : AppColors.surfaceDark,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe || !showTail ? 18 : 4),
              bottomRight: Radius.circular(!isMe || !showTail ? 18 : 4),
            ),
            border: isMe
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sender name for group chats
              if (senderName != null && !isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    senderName!,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.neonCyan,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

              // Reply preview
              if (message.replyToMessageId != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: AppColors.neonCyan,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    'Replying to message...',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white60,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              // Message content
              _buildContent(),

              // Timestamp + status row
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.edited)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        'edited',
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white54 : AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white60 : AppColors.textTertiary,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.encryptedText,
          style: AppTextStyles.messageBubble.copyWith(
            color: isMe ? Colors.white : AppColors.textPrimary,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                if (message.encryptedMediaUrl == null) return;
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _FullScreenImageViewer(
                    heroTag: message.messageId,
                    url: message.encryptedMediaUrl!,
                  ),
                ));
              },
              child: Hero(
                tag: message.messageId,
                child: Container(
                  constraints: const BoxConstraints(
                    maxHeight: 300,
                    maxWidth: 250,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: message.encryptedMediaUrl == null
                    ? const Center(child: CircularProgressIndicator())
                    : (message.encryptedMediaUrl!.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: message.encryptedMediaUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.surfaceDark,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          )
                        : Image.file(
                            File(message.encryptedMediaUrl!),
                            fit: BoxFit.cover,
                          )),
                ),
              ),
            ),
            if (message.encryptedText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  message.encryptedText,
                  style: AppTextStyles.messageBubble.copyWith(
                    color: isMe ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
          ],
        );
      case MessageType.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_filled_rounded,
              color: isMe ? Colors.white : AppColors.neonPurple,
              size: 36,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: isMe ? Colors.white38 : AppColors.neonPurple.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '0:00',
              style: TextStyle(
                fontSize: 12,
                color: isMe ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        );
      case MessageType.document:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description_rounded, color: AppColors.neonCyan, size: 24),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Document',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        );
      default:
        return Text(
          message.encryptedText,
          style: AppTextStyles.messageBubble.copyWith(
            color: isMe ? Colors.white : AppColors.textPrimary,
          ),
        );
    }
  }

  Widget _buildDeletedBubble() {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(
              isMe ? 'You deleted this message' : 'This message was deleted',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;
    switch (message.status) {
      case MessageStatus.sent:
        icon = Icons.check_rounded;
        color = Colors.white54;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all_rounded;
        color = Colors.white54;
        break;
      case MessageStatus.read:
        icon = Icons.done_all_rounded;
        color = AppColors.neonCyan;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline_rounded;
        color = AppColors.error;
        break;
    }
    return Icon(icon, size: 14, color: color);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String heroTag;
  final String url;

  const _FullScreenImageViewer({required this.heroTag, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Hero(
        tag: heroTag,
        child: PhotoView(
          imageProvider: url.startsWith('http')
              ? CachedNetworkImageProvider(url) as ImageProvider
              : FileImage(File(url)),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
      ),
    );
  }
}
