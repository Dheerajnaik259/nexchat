import 'package:flutter/material.dart';
class VoiceCallScreen extends StatelessWidget { final String callId; const VoiceCallScreen({super.key, required this.callId}); @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Voice Call: $callId'))); }
