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

  // Height/weight helpers converted to more familiar units.
  double get heightInMeters => height / 10;
  double get weightInKg => weight / 10;

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final typesJson = json['types'] as List<dynamic>;
    final statsJson = json['stats'] as List<dynamic>;

    return Pokemon(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: (json['sprites']?['other']?['official-artwork']?['front_default'] ??
              json['sprites']?['front_default'] ??
              '') as String,
      types: typesJson
          .map((t) => t['type']['name'] as String)
          .toList(growable: false),
      height: json['height'] as int,
      weight: json['weight'] as int,
      stats: statsJson
          .map((s) => PokemonStat.fromJson(s as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
