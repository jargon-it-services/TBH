import 'dart:math';

import 'package:flutter/material.dart';

class WavingFlag extends StatefulWidget {
  final double width;
  final double height;

  const WavingFlag({super.key, this.width = 22, this.height = 14});

  @override
  State<WavingFlag> createState() => _WavingFlagState();
}

class _WavingFlagState extends State<WavingFlag>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final wave = sin(_controller.value * 2 * pi) * 2;
        return Transform.translate(
          offset: Offset(0, wave),
          child: Image.asset(
            'assets/images/india_flag.png',
            width: widget.width,
            height: widget.height,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
