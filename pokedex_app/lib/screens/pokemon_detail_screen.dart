import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../widgets/type_chip.dart';
import '../widgets/type_colors.dart';

class PokemonDetailScreen extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonDetailScreen({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    final headerColor = colorForType(pokemon.types.first);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: headerColor,
        title: Text(
          pokemon.name[0].toUpperCase() + pokemon.name.substring(1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: pokemon.imageUrl.isNotEmpty
                ? Image.network(pokemon.imageUrl, height: 200)
                : const Icon(Icons.image_not_supported, size: 120),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '#${pokemon.id.toString().padLeft(3, '0')}',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: pokemon.types.map((t) => TypeChip(type: t)).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _buildMeasurementsRow(),
          const SizedBox(height: 24),
          const Text(
            'Base Stats',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...pokemon.stats.map((stat) => _buildStatBar(stat.name, stat.baseStat)),
        ],
      ),
    );
  }

  Widget _buildMeasurementsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMeasurement(Icons.height, '${pokemon.heightInMeters} m', 'Height'),
        _buildMeasurement(
            Icons.monitor_weight, '${pokemon.weightInKg} kg', 'Weight'),
      ],
    );
  }

  Widget _buildMeasurement(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.grey.shade700),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatBar(String name, int value) {
    // Base stats max out around 255; clamp the progress bar accordingly.
    final progress = (value / 255).clamp(0.0, 1.0);
    final label = name.replaceAll('-', ' ').toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          SizedBox(
            width: 32,
            child: Text(value.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: colorForType(name.contains('attack') ? 'fire' : 'water'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
