import 'package:flutter/material.dart';

class VagusLogo extends StatelessWidget {
  final double size;
  final bool white; // true = white logo, false = black
  const VagusLogo({super.key, this.size = 28, this.white = true});

  @override
  Widget build(BuildContext context) {
    final path = white
        ? 'assets/branding/vagus_logo_white.png'
        : 'assets/branding/vagus_logo_black.png';
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text(
        'V',
        style: TextStyle(
          color: white ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: size,
        ),
      ),
    );
  }
}
