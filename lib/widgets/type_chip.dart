import 'package:flutter/material.dart';
import 'type_colors.dart';

/// A glass-styled chip displaying a Pokémon's elemental type with softened colors.
class TypeChip extends StatelessWidget {
  final String type;
  final bool isSelected;
  final VoidCallback? onTap;

  const TypeChip({
    super.key,
    required this.type,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = colorForType(type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chip = Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? typeColor.withValues(alpha: 0.85)
            : typeColor.withValues(alpha: isDark ? 0.24 : 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? typeColor
              : typeColor.withValues(alpha: isDark ? 0.50 : 0.35),
          width: 1,
        ),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : (isDark
                  ? Colors.white.withValues(alpha: 0.95)
                  : const Color(0xFF2B2D42)),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: chip,
      );
    }

    return chip;
  }
}
