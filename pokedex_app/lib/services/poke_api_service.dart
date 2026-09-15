import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class PokeApiService {
  static const String baseUrl = 'https://pokeapi.co/api/v2';

  /// Fetches [limit] Pokémon (starting from Gen 1 by default) with full
  /// details (image, types, height, weight, stats) needed for the list
  /// and detail screens.
  Future<List<Pokemon>> fetchPokemonList({int limit = 151, int offset = 0}) async {
    final listUri = Uri.parse('$baseUrl/pokemon?limit=$limit&offset=$offset');
    final listResponse = await http.get(listUri);

    if (listResponse.statusCode != 200) {
      throw Exception('Failed to load Pokémon list (${listResponse.statusCode})');
    }

    final listJson = jsonDecode(listResponse.body) as Map<String, dynamic>;
    final results = listJson['results'] as List<dynamic>;

    // Fetch full details for every Pokémon in parallel.
    final futures = results.map((entry) {
      final url = entry['url'] as String;
      return fetchPokemonDetailByUrl(url);
    });

    return Future.wait(futures);
  }

  Future<Pokemon> fetchPokemonDetailByUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to load Pokémon detail ($url)');
    }
    return Pokemon.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Pokemon> fetchPokemonByName(String name) async {
    return fetchPokemonDetailByUrl('$baseUrl/pokemon/${name.toLowerCase()}');
  }

  /// Returns the list of all Pokémon type names (e.g. fire, water, grass)
  /// for use in the filter UI.
  Future<List<String>> fetchAllTypeNames() async {
    final uri = Uri.parse('$baseUrl/type');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load type list (${response.statusCode})');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final results = json['results'] as List<dynamic>;
    return results
        .map((t) => t['name'] as String)
        // "unknown" and "shadow" are not real battle types.
        .where((name) => name != 'unknown' && name != 'shadow')
        .toList(growable: false);
  }
}
