import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pokemon.dart';
import '../theme/app_theme.dart';
import '../widgets/type_chip.dart';
import '../widgets/type_colors.dart';

/// Detail screen presenting large Pokémon artwork over a type-colored glass panel,
/// animated base stat bars, physical measurements, and elemental type chips.
class PokemonDetailScreen extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonDetailScreen({super.key, required this.pokemon});

  String _formatStatName(String name) {
    switch (name.toLowerCase()) {
      case 'hp':
        return 'HP';
      case 'attack':
        return 'ATK';
      case 'defense':
        return 'DEF';
      case 'special-attack':
        return 'SP. ATK';
      case 'special-defense':
        return 'SP. DEF';
      case 'speed':
        return 'SPD';
      default:
        return name.replaceAll('-', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryType =
        pokemon.types.isNotEmpty ? pokemon.types.first : 'normal';
    final accentColor = colorForType(primaryType);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GlassCard(
            borderRadius: 14,
            padding: EdgeInsets.zero,
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : AppTheme.charcoal,
            ),
          ),
        ),
        title: Text(
          pokemon.displayName,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.charcoal,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.35 : 0.20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: isDark ? 0.55 : 0.45),
                  ),
                ),
                child: Text(
                  pokemon.formattedId,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : AppTheme.charcoal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: GlassBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
            children: [
              // Large Artwork Panel with type-colored glass styling
              GlassCard(
                borderRadius: 28,
                blur: 16,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                color: accentColor.withValues(alpha: isDark ? 0.16 : 0.12),
                border: Border.all(
                  color: accentColor.withValues(alpha: isDark ? 0.40 : 0.35),
                  width: 1.5,
                ),
                child: Column(
                  children: [
                    // Glowing radial halo & Pokémon Sprite
                    SizedBox(
                      height: 230,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  accentColor.withValues(
                                    alpha: isDark ? 0.35 : 0.25,
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          Hero(
                            tag: 'pokemon-image-${pokemon.id}',
                            child: pokemon.imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: pokemon.imageUrl,
                                    height: 220,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          accentColor,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.catching_pokemon_outlined,
                                      size: 100,
                                      color: accentColor,
                                    ),
                                  )
                                : Icon(
                                    Icons.catching_pokemon_outlined,
                                    size: 100,
                                    color: accentColor,
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Type Chips
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      children: pokemon.types
                          .map((t) => TypeChip(type: t, isSelected: true))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Height & Weight Measurements Row
              Row(
                children: [
                  Expanded(
                    child: GlassCard(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        children: [
                          Icon(
                            Icons.straighten_rounded,
                            size: 24,
                            color: accentColor,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${pokemon.heightInMeters} m',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Height',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GlassCard(
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Column(
                        children: [
                          Icon(
                            Icons.scale_rounded,
                            size: 24,
                            color: accentColor,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${pokemon.weightInKg} kg',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Weight',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Base Stats Section with animated progress bars
              GlassCard(
                borderRadius: 22,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 22,
                          color: accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Base Stats',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Animated Stat Bars
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, animValue, _) {
                        return Column(
                          children: pokemon.stats.map((stat) {
                            return _buildAnimatedStatRow(
                              name: _formatStatName(stat.name),
                              value: stat.baseStat,
                              progressFactor: animValue,
                              accentColor: accentColor,
                              isDark: isDark,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStatRow({
    required String name,
    required int value,
    required double progressFactor,
    required Color accentColor,
    required bool isDark,
  }) {
    // Normal base stats cap at 255
    final double maxStat = 255.0;
    final double targetRatio = (value / maxStat).clamp(0.0, 1.0);
    final double animatedRatio = targetRatio * progressFactor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Row(
        children: [
          // Stat abbreviation label
          SizedBox(
            width: 70,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.70)
                    : const Color(0xFF6C757D),
              ),
            ),
          ),

          // Stat numeric value
          SizedBox(
            width: 36,
            child: Text(
              value.toString(),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Animated Progress Bar
          Expanded(
            child: Container(
              height: 9,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(5),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: animatedRatio,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.75),
                        accentColor,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
