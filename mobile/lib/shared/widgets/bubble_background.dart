import 'package:flutter/material.dart';

/// Decorative glowing ambient bubble/orb widget for luxury cards and headers
class AmbientBubbles extends StatelessWidget {
  const AmbientBubbles({
    super.key,
    this.primaryColor = const Color(0xFFE11D48),
    this.secondaryColor = const Color(0xFFF97316),
  });

  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Bubble 1: Top Right Glow
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        secondaryColor.withValues(alpha: 0.45),
                        secondaryColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Bubble 2: Bottom Left Glow
              Positioned(
                bottom: -50,
                left: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.4),
                        primaryColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Bubble 3: Center Small Shimmer Bubble
              Positioned(
                top: 20,
                left: 80,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ),
              ),

              // Bubble 4: Subtle Floating Ring
              Positioned(
                bottom: 25,
                right: 50,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
