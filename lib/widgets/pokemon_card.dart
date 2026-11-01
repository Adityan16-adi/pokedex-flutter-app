import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/pokemon.dart';
import '../theme/app_theme.dart';
import 'type_chip.dart';
import 'type_colors.dart';

/// Glass Pokémon card displaying sprite, name, formatted ID, and type chips.
class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;
  final VoidCallback onTap;

  const PokemonCard({
    super.key,
    required this.pokemon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryType =
        pokemon.types.isNotEmpty ? pokemon.types.first : 'normal';
    final accentColor = colorForType(primaryType);

    return GlassCard(
      borderRadius: 20,
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      color: isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.white.withValues(alpha: 0.68),
      border: Border.all(
        color: accentColor.withValues(alpha: isDark ? 0.38 : 0.45),
        width: 1.2,
      ),
      child: Stack(
        children: [
          // Soft radial glow matching the Pokémon's primary type
          Positioned(
            top: 20,
            left: 10,
            right: 10,
            bottom: 30,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: isDark ? 0.22 : 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main vertical content
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top right ID badge
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.black : Colors.white)
                        .withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    pokemon.formattedId,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.75)
                          : const Color(0xFF4A4E69),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Centered sprite with Hero transition
              Expanded(
                child: Center(
                  child: Hero(
                    tag: 'pokemon-image-${pokemon.id}',
                    child: pokemon.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: pokemon.imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    accentColor.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.catching_pokemon_outlined,
                              size: 48,
                              color: accentColor.withValues(alpha: 0.5),
                            ),
                          )
                        : const Icon(
                            Icons.catching_pokemon_outlined,
                            size: 48,
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Pokémon Name
              Text(
                pokemon.displayName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 6),

              // Type Badges
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 2,
                runSpacing: 2,
                children: pokemon.types.map((t) => TypeChip(type: t)).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
