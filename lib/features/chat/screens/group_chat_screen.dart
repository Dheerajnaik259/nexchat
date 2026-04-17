import 'package:flutter/material.dart';

/// Group chat screen
class GroupChatScreen extends StatelessWidget {
  final String chatId;
  const GroupChatScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Group Chat: $chatId')));
  }
}
