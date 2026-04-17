import 'package:flutter/material.dart';

/// Channel screen (broadcast channel)
class ChannelScreen extends StatelessWidget {
  final String chatId;
  const ChannelScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Channel: $chatId')));
  }
}
