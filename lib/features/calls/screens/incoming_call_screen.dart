import 'package:flutter/material.dart';
class IncomingCallScreen extends StatelessWidget { final String callId; const IncomingCallScreen({super.key, required this.callId}); @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Incoming Call: $callId'))); }
