import 'package:flutter/material.dart';

class VozLumeIcon extends StatelessWidget {
  final double size;

  const VozLumeIcon({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.21),
      child: Image.asset(
        'assets/icons/vozlume_icon_v1.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: const Color(0xFFE7DFC6),
          child: Icon(Icons.book, size: size * 0.6, color: const Color(0xFF242229)),
        ),
      ),
    );
  }
}
