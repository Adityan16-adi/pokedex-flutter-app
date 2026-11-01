class PokemonStat {
  final String name;
  final int baseStat;

  PokemonStat({required this.name, required this.baseStat});

  factory PokemonStat.fromJson(Map<String, dynamic> json) {
    return PokemonStat(
      name: json['stat']['name'] as String,
      baseStat: json['base_stat'] as int,
    );
  }
}

class Pokemon {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;
  final int height; // decimetres, as returned by the API
  final int weight; // hectograms, as returned by the API
  final List<PokemonStat> stats;

  Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
    required this.height,
    required this.weight,
    required this.stats,
  });

  // Height and weight converted to common metric units
  double get heightInMeters => height / 10;
  double get weightInKg => weight / 10;

  // Formatted identifier with leading zeros (e.g. #0025)
  String get formattedId => '#${id.toString().padLeft(4, '0')}';

  // Capitalized display name
  String get displayName =>
      name.isNotEmpty ? '${name[0].toUpperCase()}${name.substring(1)}' : '';

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final typesJson = (json['types'] as List<dynamic>?) ?? [];
    final statsJson = (json['stats'] as List<dynamic>?) ?? [];

    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: (json['sprites']?['other']?['official-artwork']?['front_default'] ??
              json['sprites']?['front_default'] ??
              '') as String,
      types: typesJson
          .map((t) => t['type']['name'] as String)
          .toList(growable: false),
      height: json['height'] as int? ?? 0,
      weight: json['weight'] as int? ?? 0,
      stats: statsJson
          .map((s) => PokemonStat.fromJson(s as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

/// Lightweight item representation for full name lists and search indexing.
class PokemonNamedItem {
  final String name;
  final String url;
  final int id;

  PokemonNamedItem({
    required this.name,
    required this.url,
    required this.id,
  });

  factory PokemonNamedItem.fromJson(Map<String, dynamic> json) {
    final url = (json['url'] ?? '') as String;
    int extractedId = 0;
    if (url.isNotEmpty) {
      final segments = url.split('/').where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) {
        extractedId = int.tryParse(segments.last) ?? 0;
      }
    }
    return PokemonNamedItem(
      name: json['name'] as String,
      url: url,
      id: extractedId,
    );
  }
}

/// Paginated result container holding detailed Pokémon models.
class PokemonPageResult {
  final List<Pokemon> pokemon;
  final int totalCount;
  final bool hasMore;

  PokemonPageResult({
    required this.pokemon,
    required this.totalCount,
    required this.hasMore,
  });
}
