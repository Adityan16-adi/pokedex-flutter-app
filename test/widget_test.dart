import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/main.dart';
import 'package:pokedex_app/models/pokemon.dart';
import 'package:pokedex_app/screens/pokemon_detail_screen.dart';
import 'package:pokedex_app/theme/app_theme.dart';

void main() {
  testWidgets('App builds and displays landing screen smoke test',
      (WidgetTester tester) async {
    // Build the Pokédex app and trigger initial frames
    await tester.pumpWidget(const PokedexApp());

    // Advance past landing screen entry animations
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify app title, tagline, and call-to-action button
    expect(find.text('Pokédex'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  test('Pokemon and PokemonStat json parsing test', () {
    final json = {
      'id': 25,
      'name': 'pikachu',
      'sprites': {
        'front_default': 'https://example.com/25.png',
        'other': {
          'official-artwork': {
            'front_default': 'https://example.com/25_art.png'
          }
        }
      },
      'types': [
        {
          'type': {'name': 'electric'}
        }
      ],
      'height': 4,
      'weight': 60,
      'stats': [
        {
          'base_stat': 35,
          'stat': {'name': 'hp'}
        },
        {
          'base_stat': 55,
          'stat': {'name': 'attack'}
        }
      ]
    };

    final pokemon = Pokemon.fromJson(json);
    expect(pokemon.id, 25);
    expect(pokemon.name, 'pikachu');
    expect(pokemon.displayName, 'Pikachu');
    expect(pokemon.formattedId, '#0025');
    expect(pokemon.imageUrl, 'https://example.com/25_art.png');
    expect(pokemon.heightInMeters, 0.4);
    expect(pokemon.weightInKg, 6.0);
    expect(pokemon.types, ['electric']);
    expect(pokemon.stats.length, 2);
    expect(pokemon.stats.first.name, 'hp');
    expect(pokemon.stats.first.baseStat, 35);
  });

  test('PokemonNamedItem json parsing extracts id from url', () {
    final item = PokemonNamedItem.fromJson({
      'name': 'bulbasaur',
      'url': 'https://pokeapi.co/api/v2/pokemon/1/',
    });
    expect(item.name, 'bulbasaur');
    expect(item.id, 1);
  });

  testWidgets('GlassCard renders child with BackdropFilter',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            child: Text('Glass Content'),
          ),
        ),
      ),
    );
    expect(find.text('Glass Content'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('PokemonDetailScreen renders pokemon stats and details',
      (WidgetTester tester) async {
    final testPokemon = Pokemon(
      id: 1,
      name: 'bulbasaur',
      imageUrl: '',
      types: ['grass', 'poison'],
      height: 7,
      weight: 69,
      stats: [
        PokemonStat(name: 'hp', baseStat: 45),
        PokemonStat(name: 'attack', baseStat: 49),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: PokemonDetailScreen(pokemon: testPokemon),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('#0001'), findsOneWidget);
    expect(find.text('0.7 m'), findsOneWidget);
    expect(find.text('6.9 kg'), findsOneWidget);
    expect(find.text('Base Stats'), findsOneWidget);
    expect(find.text('GRASS'), findsOneWidget);
    expect(find.text('POISON'), findsOneWidget);
  });
}
