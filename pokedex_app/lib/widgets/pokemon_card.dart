import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import 'type_chip.dart';
import 'type_colors.dart';

class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;
  final VoidCallback onTap;

  const PokemonCard({super.key, required this.pokemon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primaryColor = colorForType(pokemon.types.first).withOpacity(0.15);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: primaryColor,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#${pokemon.id.toString().padLeft(3, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: pokemon.imageUrl.isNotEmpty
                    ? Image.network(pokemon.imageUrl, fit: BoxFit.contain)
                    : const Icon(Icons.image_not_supported),
              ),
              Text(
                pokemon.name[0].toUpperCase() + pokemon.name.substring(1),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.center,
                children: pokemon.types.map((t) => TypeChip(type: t)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
