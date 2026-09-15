import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Pokedex(),
  ));
}

class Pokedex extends StatefulWidget {
  const Pokedex({super.key});

  @override
  State<Pokedex> createState() => _PokedexState();
}

class _PokedexState extends State<Pokedex> {
  List<dynamic> pokemon = [];
  List<dynamic> filtered = [];

  String selectedType = 'all';

  final types = [
    'all',
    'normal',
    'fire',
    'water',
    'electric',
    'grass',
    'ice',
    'fighting',
    'poison',
    'ground',
    'flying',
    'psychic',
    'bug',
    'rock',
    'ghost',
    'dragon',
    'dark',
    'steel',
    'fairy',
  ];

  @override
  void initState() {
    super.initState();
    loadPokemon();
  }

  Future<void> loadPokemon() async {
    final response = await http.get(
      Uri.parse(
        'https://pokeapi.co/api/v2/pokemon?limit=50',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        pokemon = data['results'];
        filtered = pokemon;
      });
    }
  }

  void search(String text) {
    final query = text.toLowerCase();

    setState(() {
      filtered = pokemon.where((p) {
        return p['name'].toString().contains(query);
      }).toList();
    });
  }

  Future<void> filterPokemon(String type) async {
    setState(() {
      selectedType = type;
    });

    if (type == 'all') {
      setState(() {
        filtered = pokemon;
      });
      return;
    }

    final response = await http.get(
      Uri.parse(
        'https://pokeapi.co/api/v2/type/$type',
      ),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List<dynamic> typePokemon = data['pokemon'];

      final Set<String> names = typePokemon
          .map<String>((p) => p['pokemon']['name'].toString())
          .toSet();

      setState(() {
        filtered = pokemon
            .where((p) => names.contains(p['name'].toString()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  onChanged: search,
                  decoration: const InputDecoration(
                    hintText: 'Search Pokémon',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedType,
                  isExpanded: true,
                  items: types.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (type) {
                    if (type != null) {
                      filterPokemon(type);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No Pokémon found'),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];

                      // Get the real ID from the API URL.
                      final url = p['url'].toString();
                      final parts = url.split('/');
                      final id = int.parse(
                        parts[parts.length - 2],
                      );

                      return Card(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Details(
                                  name: p['name'].toString(),
                                ),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
                                height: 100,
                              ),
                              Text(
                                p['name']
                                    .toString()
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '#${id.toString().padLeft(3, '0')}',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class Details extends StatefulWidget {
  final String name;

  const Details({
    super.key,
    required this.name,
  });

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  Map<String, dynamic> data = {};

  @override
  void initState() {
    super.initState();
    loadDetails();
  }

  Future<void> loadDetails() async {
    final response = await http.get(
      Uri.parse(
        'https://pokeapi.co/api/v2/pokemon/${widget.name}',
      ),
    );

    if (response.statusCode == 200) {
      setState(() {
        data = jsonDecode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final List<dynamic> typeList = data['types'];

    final String types = typeList
        .map<String>(
          (t) => t['type']['name'].toString(),
        )
        .join(' / ');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          data['name'].toString().toUpperCase(),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),

              Image.network(
                data['sprites']['other']['official-artwork']
                    ['front_default'],
                height: 200,
              ),

              Text(
                data['name'].toString().toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text('Type: $types'),
              Text('Height: ${data['height']}'),
              Text('Weight: ${data['weight']}'),

              const SizedBox(height: 20),

              const Text(
                'Base Stats',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              ...((data['stats'] as List).map<Widget>((s) {
                return Text(
                  '${s['stat']['name']}: ${s['base_stat']}',
                );
              })),
            ],
          ),
        ),
      ),
    );
  }
}