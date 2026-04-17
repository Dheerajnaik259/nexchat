import 'package:flutter/material.dart';
class StatusViewScreen extends StatelessWidget { final String statusId; const StatusViewScreen({super.key, required this.statusId}); @override Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Viewing Status: $statusId'))); }
