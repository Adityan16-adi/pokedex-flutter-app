# Pokédex App (Flutter)

A Flutter app that consumes the [PokéAPI](https://pokeapi.co/docs/v2) to display, search, and filter Pokémon.

## Features
- **List screen**: grid of Pokémon (Gen 1, #1–151) showing image, ID, name, and type badges.
- **Search bar**: live, case-insensitive filter by name as you type.
- **Type filter**: horizontal chip row to filter the grid to a single type (e.g. Fire, Water).
- **Detail screen**: tapping a Pokémon shows its official artwork, name, ID, types, height, weight, and a base-stats breakdown with progress bars.
- **Pull to refresh** and a retry button on network failure.

## Project structure
```
lib/
  models/
    pokemon.dart          # Pokemon + PokemonStat data classes, parsed from PokéAPI JSON
  services/
    poke_api_service.dart # All PokéAPI HTTP calls (list, detail, types)
  widgets/
    pokemon_card.dart      # Grid item used on the list screen
    type_chip.dart         # Colored badge for a Pokémon type
    type_colors.dart       # Type -> color mapping
  screens/
    pokemon_list_screen.dart   # Search + filter + grid
    pokemon_detail_screen.dart # Full detail view
  main.dart                # App entry point / theme
```

## How the data flows
1. On launch, `PokemonListScreen` calls `PokeApiService.fetchPokemonList()`, which:
   - Hits `GET /pokemon?limit=151` to get the base list (name + URL per Pokémon).
   - Hits each Pokémon's own URL in parallel (`Future.wait`) to get full details (sprite, types, height, weight, stats), since the list endpoint alone doesn't include them.
2. It also calls `fetchAllTypeNames()` (`GET /type`) to populate the filter chips.
3. Search and type filtering are done **client-side** against the already-fetched list, so typing/filtering feels instant with no extra network calls.
4. Tapping a card passes the already-fetched `Pokemon` object straight to `PokemonDetailScreen` — no second API call needed.

## Running it
```bash
flutter pub get
flutter run
```

## Building a release APK
```bash
flutter build apk --release
```
The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.
