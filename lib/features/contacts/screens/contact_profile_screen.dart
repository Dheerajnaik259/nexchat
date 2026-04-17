import 'package:flutter/material.dart';
class ContactProfileScreen extends StatelessWidget { final String userId; const ContactProfileScreen({super.key, required this.userId}); @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Contact: $userId'))); }
