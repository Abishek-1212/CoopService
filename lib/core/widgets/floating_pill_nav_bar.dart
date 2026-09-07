import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FloatingNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int? badgeCount;

  const FloatingNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}

/// A modern, ultra-smooth floating pill-shaped bottom navigation bar.
/// Features a fluid sliding circular highlight that glides between tabs with spring physics.
class FloatingPillNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavItem> items;

  const FloatingPillNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    const double barHeight = 62.0;
    const double circleSize = 42.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: const Color(0xFFDCE7E1),
              width: 1.0,
            ),
            boxShadow: [
              // Top-left specular highlight
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.95),
                offset: const Offset(-2, -2),
                blurRadius: 6,
              ),
              // Soft diffused depth shadow
              BoxShadow(
                color: AppColors.neuDarkShadow,
                offset: const Offset(0, 6),
                blurRadius: 16,
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final int count = items.length;
              if (count == 0) return const SizedBox.shrink();

              final double itemWidth = constraints.maxWidth / count;
              final double circleLeft =
                  (currentIndex * itemWidth) + (itemWidth - circleSize) / 2;
              final double circleTop = (barHeight - circleSize) / 2;

              return Stack(
                children: [
                  // 1. Sliding Circular Indicator with Spring Physics
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    left: circleLeft,
                    top: circleTop,
                    width: circleSize,
                    height: circleSize,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.greenEmerald,
                            AppColors.greenForest,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.greenForest.withValues(alpha: 0.35),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Interactive Navigation Items
                  Row(
                    children: List.generate(count, (index) {
                      final item = items[index];
                      final bool isSelected = index == currentIndex;

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTap(index),
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                TweenAnimationBuilder<Color?>(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeInOut,
                                  tween: ColorTween(
                                    begin: isSelected ? const Color(0xFF6E877D) : Colors.white,
                                    end: isSelected ? Colors.white : const Color(0xFF6E877D),
                                  ),
                                  builder: (context, color, _) {
                                    return Icon(
                                      isSelected
                                          ? (item.activeIcon ?? item.icon)
                                          : item.icon,
                                      size: isSelected ? 24 : 22,
                                      color: color,
                                    );
                                  },
                                ),

                                // Optional Badge
                                if (item.badgeCount != null && item.badgeCount! > 0)
                                  Positioned(
                                    top: -4,
                                    right: -8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.statusError,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${item.badgeCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
