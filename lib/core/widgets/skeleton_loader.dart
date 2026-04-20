import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

/// Basic component for skeleton loaders
class SkeletonItem extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonItem({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton loader for the Chat List (HomeScreen)
class ChatListSkeleton extends StatelessWidget {
  final int itemCount;

  const ChatListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView.builder(
        itemCount: itemCount,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Avatar
                const SkeletonItem(width: 56, height: 56, borderRadius: 28),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          SkeletonItem(width: 120, height: 16),
                          SkeletonItem(width: 40, height: 12),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Message
                      const SkeletonItem(width: double.infinity, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton loader for the Messages List (ChatScreen)
class MessageListSkeleton extends StatelessWidget {
  const MessageListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulated sequence of received and sent messages
    final messagePatterns = [
      {'isMe': false, 'width': 220.0},
      {'isMe': false, 'width': 160.0},
      {'isMe': true, 'width': 200.0},
      {'isMe': false, 'width': 240.0},
      {'isMe': true, 'width': 120.0},
      {'isMe': true, 'width': 260.0},
      {'isMe': false, 'width': 180.0},
    ];

    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: ListView.builder(
        reverse: true, // typical for chat
        itemCount: messagePatterns.length,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final isMe = messagePatterns[index]['isMe'] as bool;
          final width = messagePatterns[index]['width'] as double;

          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 4,
                bottom: 4,
                left: 14,
                right: 14,
              ),
              child: SkeletonItem(
                width: width,
                height: 40,
                borderRadius: 16,
              ),
            ),
          );
        },
      ),
    );
  }
}
