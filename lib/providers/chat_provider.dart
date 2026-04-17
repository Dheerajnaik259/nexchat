import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../services/supabase/database_service.dart';

/// Stream of user's chats from Supabase (real-time)
final chatListProvider = StreamProvider<List<ChatModel>>((ref) {
  return DatabaseService.instance.streamUserChats();
});

/// Search query for filtering chats
final chatSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered chat list based on search query
final filteredChatsProvider = Provider<AsyncValue<List<ChatModel>>>((ref) {
  final chats = ref.watch(chatListProvider);
  final query = ref.watch(chatSearchQueryProvider).toLowerCase();

  return chats.whenData((chatList) {
    if (query.isEmpty) return chatList;
    return chatList.where((chat) {
      final name = (chat.name ?? '').toLowerCase();
      return name.contains(query);
    }).toList();
  });
});

/// Total unread count across all chats
final totalUnreadCountProvider = Provider<int>((ref) {
  // TODO: Implement per-chat unread tracking
  return 0;
});

/// Selected chat for detail view
final selectedChatProvider = StateProvider<ChatModel?>((ref) => null);
