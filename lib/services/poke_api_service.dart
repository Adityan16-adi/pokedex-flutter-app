import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

/// Service handling all API calls to PokéAPI (https://pokeapi.co/api/v2)
/// with pagination, in-memory caching, parallel detail fetching, and search support.
class PokeApiService {
  static const String baseUrl = 'https://pokeapi.co/api/v2';

  // In-memory caches to prevent redundant network requests
  final Map<String, Pokemon> _detailCacheByUrl = {};
  final Map<int, Pokemon> _detailCacheById = {};
  List<PokemonNamedItem>? _cachedAllPokemonNames;
  List<String>? _cachedAllTypes;
  final Map<String, List<PokemonNamedItem>> _cachedTypePokemon = {};

  /// Fetches a paginated page of Pokémon using ?limit=30&offset=N.
  /// Full details for the 30 items on this page are fetched in parallel.
  Future<PokemonPageResult> fetchPokemonPage({
    int limit = 30,
    int offset = 0,
  }) async {
    final listUri = Uri.parse('$baseUrl/pokemon?limit=$limit&offset=$offset');
    final response = await http.get(listUri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load Pokémon list (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final count = data['count'] as int? ?? 0;
    final next = data['next'] as String?;
    final results = (data['results'] as List<dynamic>?) ?? [];

    // Fetch details for the current page in parallel
    final futures = results.map((entry) {
      final url = entry['url'] as String;
      return fetchPokemonDetailByUrl(url);
    });

    final pokemonList = await Future.wait(futures);

    final bool hasMore = next != null &&
        results.isNotEmpty &&
        (offset + results.length < count);

    return PokemonPageResult(
      pokemon: pokemonList,
      totalCount: count,
      hasMore: hasMore,
    );
  }

  /// Fetches full detail for a single Pokémon by its API URL.
  /// Results are cached in memory.
  Future<Pokemon> fetchPokemonDetailByUrl(String url) async {
    if (_detailCacheByUrl.containsKey(url)) {
      return _detailCacheByUrl[url]!;
    }

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to load Pokémon detail ($url)');
    }

    final pokemon = Pokemon.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    _detailCacheByUrl[url] = pokemon;
    _detailCacheById[pokemon.id] = pokemon;
    return pokemon;
  }

  /// Fetches full detail by Pokémon name.
  Future<Pokemon> fetchPokemonByName(String name) async {
    return fetchPokemonDetailByUrl('$baseUrl/pokemon/${name.toLowerCase()}');
  }

  /// Fetches details in parallel for a slice of named Pokémon items (used in search & filter).
  Future<List<Pokemon>> fetchPokemonDetailsForItems(
    List<PokemonNamedItem> items,
  ) async {
    final futures = items.map((item) => fetchPokemonDetailByUrl(item.url));
    return Future.wait(futures);
  }

  /// Loads the lightweight full name list once (/pokemon?limit=100000) for instant search indexing.
  Future<List<PokemonNamedItem>> fetchAllPokemonNames() async {
    if (_cachedAllPokemonNames != null) {
      return _cachedAllPokemonNames!;
    }

    final uri = Uri.parse('$baseUrl/pokemon?limit=100000');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load Pokémon names index (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List<dynamic>?) ?? [];

    _cachedAllPokemonNames = results
        .map((entry) => PokemonNamedItem.fromJson(entry as Map<String, dynamic>))
        .toList(growable: false);

    return _cachedAllPokemonNames!;
  }

  /// Returns the list of all Pokémon battle type names (fire, water, etc.).
  Future<List<String>> fetchAllTypeNames() async {
    if (_cachedAllTypes != null) {
      return _cachedAllTypes!;
    }

    final uri = Uri.parse('$baseUrl/type');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load type list (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List<dynamic>?) ?? [];

    _cachedAllTypes = results
        .map((t) => t['name'] as String)
        .where((name) => name != 'unknown' && name != 'shadow')
        .toList(growable: false);

    return _cachedAllTypes!;
  }

  /// Fetches the list of Pokémon names associated with a specific type.
  Future<List<PokemonNamedItem>> fetchPokemonNamesByType(String type) async {
    final lowerType = type.toLowerCase();
    if (_cachedTypePokemon.containsKey(lowerType)) {
      return _cachedTypePokemon[lowerType]!;
    }

    final uri = Uri.parse('$baseUrl/type/$lowerType');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load Pokémon for type $type (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final entries = (data['pokemon'] as List<dynamic>?) ?? [];

    final list = entries.map((entry) {
      final p = entry['pokemon'] as Map<String, dynamic>;
      return PokemonNamedItem.fromJson(p);
    }).toList(growable: false);

    _cachedTypePokemon[lowerType] = list;
    return list;
  }
}
