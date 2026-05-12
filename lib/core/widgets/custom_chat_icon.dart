import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomChatIcon extends StatelessWidget {
  final Color color;
  final double size;
  final bool isSolid;

  const CustomChatIcon({
    super.key,
    required this.color,
    this.size = 24,
    this.isSolid = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            LucideIcons.messageSquare,
            size: size,
            color: color,
          ),
          Padding(
            padding: EdgeInsets.only(bottom: size * 0.1, right: size * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLine(size * 0.5),
                SizedBox(height: size * 0.08),
                _buildLine(size * 0.35),
                SizedBox(height: size * 0.08),
                _buildLine(size * 0.2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(double width) {
    return Container(
      width: width,
      height: 1.5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
