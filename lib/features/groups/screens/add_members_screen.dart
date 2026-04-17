import 'package:flutter/material.dart';
class AddMembersScreen extends StatelessWidget { final String chatId; const AddMembersScreen({super.key, required this.chatId}); @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Add Members: $chatId'))); }
