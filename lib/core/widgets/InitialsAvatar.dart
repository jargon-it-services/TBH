import 'package:flutter/material.dart';

class InitialsAvatar extends StatelessWidget {
  final String? name;
  final double radius;

  const InitialsAvatar({super.key, required this.name, this.radius = 24});

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';

    final words = name.trim().split(RegExp(r'\s+'));

    if (words.length == 1) {
      return words.first[0].toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  Color _getBackgroundColor(String? name) {
    const colors = [
      Color(0xFF1976D2), // Blue
      Color(0xFF388E3C), // Green
      Color(0xFFF57C00), // Orange
      Color(0xFFD32F2F), // Red
      Color(0xFF7B1FA2), // Purple
      Color(0xFF00796B), // Teal
      Color(0xFF5D4037), // Brown
      Color(0xFF455A64), // Blue Grey
      Color(0xFFC2185B), // Pink
      Color(0xFF512DA8), // Deep Purple
    ];

    if (name == null || name.isEmpty) {
      return colors.first;
    }

    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _getBackgroundColor(name),
      child: Text(
        _getInitials(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}
