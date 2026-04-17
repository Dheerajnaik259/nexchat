import 'package:flutter/material.dart';
class GroupInfoScreen extends StatelessWidget { final String chatId; const GroupInfoScreen({super.key, required this.chatId}); @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Group Info: $chatId'))); }
