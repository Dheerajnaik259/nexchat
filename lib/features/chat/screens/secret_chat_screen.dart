import 'package:flutter/material.dart';

/// Secret (self-destructing) chat screen
class SecretChatScreen extends StatelessWidget {
  final String chatId;
  const SecretChatScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Secret Chat: $chatId')));
  }
}
