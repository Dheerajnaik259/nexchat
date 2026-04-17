import 'package:flutter/material.dart';
class VideoCallScreen extends StatelessWidget { final String callId; const VideoCallScreen({super.key, required this.callId}); @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Video Call: $callId'))); }
