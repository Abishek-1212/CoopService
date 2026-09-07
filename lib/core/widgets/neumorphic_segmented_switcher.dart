import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SegmentItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final String? badge;

  const SegmentItem({
    required this.value,
    required this.label,
    this.icon,
    this.badge,
  });
}

/// An ultra-smooth, premium Neumorphic Segmented Switcher.
/// Features a carved debossed track, a tactile sliding pebble with spring curve physics,
/// and smooth color transitions.
class NeumorphicSegmentedSwitcher<T> extends StatefulWidget {
  final List<SegmentItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final double height;
  final EdgeInsetsGeometry padding;

  const NeumorphicSegmentedSwitcher({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.height = 54.0,
    this.padding = const EdgeInsets.all(4.0),
  });

  @override
  State<NeumorphicSegmentedSwitcher<T>> createState() =>
      _NeumorphicSegmentedSwitcherState<T>();
}

class _NeumorphicSegmentedSwitcherState<T>
    extends State<NeumorphicSegmentedSwitcher<T>> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final int selectedIndex =
        widget.items.indexWhere((it) => it.value == widget.selectedValue);
    final int activeIndex = selectedIndex >= 0 ? selectedIndex : 0;

    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutQuad,
      child: Container(
        height: widget.height,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: AppColors.neuTrackBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.neuBorder,
            width: 1.0,
          ),
          boxShadow: [
            // Top-left debossed cavity shadow
            BoxShadow(
              color: AppColors.neuInsetShadow,
              offset: const Offset(2, 2),
              blurRadius: 5,
              spreadRadius: 0,
            ),
            // Bottom-right soft light rim
            BoxShadow(
              color: AppColors.neuLightShadow.withValues(alpha: 0.9),
              offset: const Offset(-2, -2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final int itemCount = widget.items.length;
            final double totalWidth = constraints.maxWidth;
            final double itemWidth = itemCount > 0 ? (totalWidth / itemCount) : 0;
            final double thumbLeft = activeIndex * itemWidth;

            return Stack(
              children: [
                // 1. Smooth Spring-Sliding Floating Pebble (Indicator)
                if (itemCount > 0)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutBack,
                    left: thumbLeft,
                    top: 0,
                    bottom: 0,
                    width: itemWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Color(0xFFF6FBF8), // Delicate mint-white sheen
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.2,
                        ),
                        boxShadow: [
                          // Specular top-left reflection
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.95),
                            offset: const Offset(-2, -2),
                            blurRadius: 6,
                          ),
                          // Organic forest-tinted elevation shadow
                          BoxShadow(
                            color: AppColors.neuDarkShadow,
                            offset: const Offset(2, 4),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),

                // 2. Interactive Item Buttons
                Row(
                  children: List.generate(widget.items.length, (index) {
                    final item = widget.items[index];
                    final bool isSelected = index == activeIndex;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => setState(() => _isPressed = true),
                        onTapUp: (_) {
                          setState(() => _isPressed = false);
                          if (item.value != widget.selectedValue) {
                            widget.onChanged(item.value);
                          }
                        },
                        onTapCancel: () => setState(() => _isPressed = false),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeInOut,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.greenForest
                                  : AppColors.textSecondary,
                              letterSpacing: isSelected ? -0.2 : 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item.icon != null) ...[
                                  TweenAnimationBuilder<Color?>(
                                    duration: const Duration(milliseconds: 240),
                                    curve: Curves.easeInOut,
                                    tween: ColorTween(
                                      begin: isSelected
                                          ? AppColors.textSecondary
                                          : AppColors.greenForest,
                                      end: isSelected
                                          ? AppColors.greenForest
                                          : AppColors.textSecondary,
                                    ),
                                    builder: (context, color, _) {
                                      return Icon(
                                        item.icon,
                                        size: 19,
                                        color: color,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(item.label),
                                if (item.badge != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.greenMint
                                          : AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      item.badge!,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? AppColors.greenDeep
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
    );
  }
}
