import 'package:flutter/material.dart';

/// Softened modern palette for Pokémon types, designed for glassmorphic accents.
const Map<String, Color> _typeColors = {
  'normal': Color(0xFFA8A77A),
  'fire': Color(0xFFF08030),
  'water': Color(0xFF6890F0),
  'electric': Color(0xFFF8D030),
  'grass': Color(0xFF78C850),
  'ice': Color(0xFF98D8D8),
  'fighting': Color(0xFFC03028),
  'poison': Color(0xFFA040A0),
  'ground': Color(0xFFE0C068),
  'flying': Color(0xFFA890F0),
  'psychic': Color(0xFFF85888),
  'bug': Color(0xFFA8B820),
  'rock': Color(0xFFB8A038),
  'ghost': Color(0xFF705898),
  'dragon': Color(0xFF7038F8),
  'dark': Color(0xFF705848),
  'steel': Color(0xFFB8B8D0),
  'fairy': Color(0xFFEE99AC),
};

/// Returns the primary accent color for a given Pokémon type.
Color colorForType(String type) {
  return _typeColors[type.toLowerCase()] ?? const Color(0xFF8D99AE);
}

/// Returns a softened translucent accent tint for glass card backgrounds and glows.
Color softTintForType(String type, {double alpha = 0.18}) {
  return colorForType(type).withValues(alpha: alpha);
}
