import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/poke_api_service.dart';
import '../widgets/pokemon_card.dart';
import 'pokemon_detail_screen.dart';

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  final PokeApiService _apiService = PokeApiService();

  List<Pokemon> _allPokemon = [];
  List<String> _allTypes = [];
  List<Pokemon> _filteredPokemon = [];

  String _searchQuery = '';
  String? _selectedType; // null = no filter

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _apiService.fetchPokemonList(limit: 151),
        _apiService.fetchAllTypeNames(),
      ]);
      final pokemonList = results[0] as List<Pokemon>;
      final typeList = results[1] as List<String>;

      pokemonList.sort((a, b) => a.id.compareTo(b.id));

      setState(() {
        _allPokemon = pokemonList;
        _allTypes = typeList;
        _filteredPokemon = pokemonList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load Pokémon. Check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPokemon = _allPokemon.where((p) {
        final matchesSearch =
            p.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesType =
            _selectedType == null || p.types.contains(_selectedType);
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            _buildSearchBar(),
            _buildTypeFilter(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search Pokémon by name...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        onChanged: (value) {
          _searchQuery = value;
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildTypeFilter() {
    if (_allTypes.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _buildTypeChoice(null, 'All'),
          ..._allTypes.map((t) => _buildTypeChoice(t, t)),
        ],
      ),
    );
  }

  Widget _buildTypeChoice(String? type, String label) {
    final isSelected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          _selectedType = type;
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_filteredPokemon.isEmpty) {
      return const Center(child: Text('No Pokémon match your search.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredPokemon.length,
      itemBuilder: (context, index) {
        final pokemon = _filteredPokemon[index];
        return PokemonCard(
          pokemon: pokemon,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PokemonDetailScreen(pokemon: pokemon),
              ),
            );
          },
        );
      },
    );
  }
}
