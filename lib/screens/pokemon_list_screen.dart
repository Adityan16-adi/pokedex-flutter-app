import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pokemon.dart';
import '../services/poke_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/pokemon_skeleton_grid.dart';
import '../widgets/type_colors.dart';
import 'pokemon_detail_screen.dart';

/// Main Pokédex list screen featuring infinite pagination, glass search bar,
/// glass type filter chips, shimmer skeleton loading, and error retry flows.
class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  final PokeApiService _apiService = PokeApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Currently displayed Pokémon in the 2-column grid
  final List<Pokemon> _displayedPokemon = [];
  final Set<int> _loadedPokemonIds = {};

  // Preserved default stream of Pokémon for fast restoration when clearing filters
  final List<Pokemon> _defaultPokemon = [];
  final Set<int> _defaultPokemonIds = {};
  int _defaultOffset = 0;
  bool _defaultHasMore = true;

  // Type filter & search candidates
  List<String> _allTypes = [];
  List<PokemonNamedItem> _allNamedItems = [];
  List<PokemonNamedItem> _filteredCandidates = [];
  int _filteredOffset = 0;

  String _searchQuery = '';
  String? _selectedType;
  Timer? _debounceTimer;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  String? _paginationError;

  bool get _isFilteringActive =>
      _searchQuery.trim().isNotEmpty || _selectedType != null;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Automatically triggers loading the next page when scrolling near the bottom.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Trigger load when 300px away from the bottom of the list
    if (currentScroll >= maxScroll - 300) {
      _loadMore();
    }
  }

  /// Initial startup data loading: fetches type list, name index, and first 30 Pokémon.
  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.fetchAllTypeNames(),
        _apiService.fetchAllPokemonNames(),
        _apiService.fetchPokemonPage(limit: 30, offset: 0),
      ]);

      final types = results[0] as List<String>;
      final names = results[1] as List<PokemonNamedItem>;
      final firstPage = results[2] as PokemonPageResult;

      _allTypes = types;
      _allNamedItems = names;

      _defaultPokemon.clear();
      _defaultPokemonIds.clear();
      for (final p in firstPage.pokemon) {
        if (_defaultPokemonIds.add(p.id)) {
          _defaultPokemon.add(p);
        }
      }
      _defaultOffset = firstPage.pokemon.length;
      _defaultHasMore = firstPage.hasMore;

      _displayedPokemon.clear();
      _loadedPokemonIds.clear();
      _displayedPokemon.addAll(_defaultPokemon);
      _loadedPokemonIds.addAll(_defaultPokemonIds);
      _hasMore = _defaultHasMore;

      setState(() {
        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Could not load Pokémon. Check your connection and try again.';
        _isInitialLoading = false;
      });
    }
  }

  /// Fetches the next page of 30 Pokémon either from PokéAPI pagination
  /// or from the filtered candidate list.
  Future<void> _loadMore() async {
    if (_isInitialLoading || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _paginationError = null;
    });

    try {
      if (_isFilteringActive) {
        // Load next slice of matching search/type items
        final nextSlice =
            _filteredCandidates.skip(_filteredOffset).take(30).toList();

        if (nextSlice.isEmpty) {
          setState(() {
            _hasMore = false;
            _isLoadingMore = false;
          });
          return;
        }

        final details =
            await _apiService.fetchPokemonDetailsForItems(nextSlice);

        final newItems = <Pokemon>[];
        for (final p in details) {
          if (_loadedPokemonIds.add(p.id)) {
            newItems.add(p);
          }
        }

        setState(() {
          _displayedPokemon.addAll(newItems);
          _filteredOffset += nextSlice.length;
          _hasMore = _filteredOffset < _filteredCandidates.length;
          _isLoadingMore = false;
        });
      } else {
        // Load next 30 from the general PokéAPI stream (?limit=30&offset=N)
        final result = await _apiService.fetchPokemonPage(
          limit: 30,
          offset: _defaultOffset,
        );

        final newItems = <Pokemon>[];
        for (final p in result.pokemon) {
          if (_defaultPokemonIds.add(p.id)) {
            _defaultPokemon.add(p);
            newItems.add(p);
          }
        }

        _defaultOffset += result.pokemon.length;
        _defaultHasMore = result.hasMore;

        setState(() {
          _displayedPokemon.addAll(newItems);
          _loadedPokemonIds.addAll(_defaultPokemonIds);
          _hasMore = _defaultHasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _paginationError = 'Failed to load more Pokémon. Tap to retry.';
      });
    }
  }

  /// Handles search text input with debounce to prevent excessive queries.
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
      });
      _applyFilters();
    });
  }

  /// Handles type chip selection.
  void _onTypeSelected(String? type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
    });
    _applyFilters();
  }

  /// Recomputes displayed Pokémon when query or type filter updates.
  Future<void> _applyFilters() async {
    if (!_isFilteringActive) {
      // Revert to the cached default list immediately without network latency
      setState(() {
        _displayedPokemon.clear();
        _loadedPokemonIds.clear();
        _displayedPokemon.addAll(_defaultPokemon);
        _loadedPokemonIds.addAll(_defaultPokemonIds);
        _hasMore = _defaultHasMore;
        _isInitialLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });

    try {
      List<PokemonNamedItem> candidates;

      if (_selectedType != null) {
        candidates =
            await _apiService.fetchPokemonNamesByType(_selectedType!);
      } else {
        candidates = _allNamedItems;
      }

      final query = _searchQuery.trim().toLowerCase();
      if (query.isNotEmpty) {
        candidates = candidates
            .where((item) => item.name.toLowerCase().contains(query))
            .toList(growable: false);
      }

      _filteredCandidates = candidates;
      _filteredOffset = 0;
      _displayedPokemon.clear();
      _loadedPokemonIds.clear();

      if (candidates.isEmpty) {
        setState(() {
          _hasMore = false;
          _isInitialLoading = false;
        });
        return;
      }

      // Fetch first page of 30 matches
      final firstSlice = candidates.take(30).toList();
      final details =
          await _apiService.fetchPokemonDetailsForItems(firstSlice);

      for (final p in details) {
        if (_loadedPokemonIds.add(p.id)) {
          _displayedPokemon.add(p);
        }
      }
      _filteredOffset = firstSlice.length;
      _hasMore = _filteredOffset < candidates.length;

      setState(() {
        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load search results. Please try again.';
        _isInitialLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAppBar(isDark),
              _buildSearchBar(isDark),
              _buildTypeFilterBar(isDark),
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.primaryRed,
                  onRefresh: () async {
                    if (_isFilteringActive) {
                      await _applyFilters();
                    } else {
                      await _loadInitialData();
                    }
                  },
                  child: _buildGridBody(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// App bar with logo, Pokédex branding, and live count badge.
  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(
        children: [
          // App Logo
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.60),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.50),
              ),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              width: 30,
              height: 30,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          // App Name
          Text(
            'Pokédex',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : AppTheme.charcoal,
            ),
          ),
          const Spacer(),
          // Live items loaded badge
          if (_displayedPokemon.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withValues(
                  alpha: isDark ? 0.25 : 0.12,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryRed.withValues(
                    alpha: isDark ? 0.45 : 0.30,
                  ),
                ),
              ),
              child: Text(
                '${_displayedPokemon.length} loaded',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryRed,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Glassmorphic search input bar.
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 22,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search Pokémon by name...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.45)
                        : Colors.grey.shade500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: TextStyle(
                  fontSize: 14.5,
                  color: isDark ? Colors.white : AppTheme.charcoal,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                child: Icon(
                  Icons.cancel_rounded,
                  size: 20,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.grey.shade500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Horizontal scrolling bar of glass type filter chips.
  Widget _buildTypeFilterBar(bool isDark) {
    if (_allTypes.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _allTypes.length + 1,
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final typeName = isAll ? null : _allTypes[index - 1];
          final label = isAll ? 'All' : _allTypes[index - 1];
          final isSelected = _selectedType == typeName;
          final accentColor =
              isAll ? AppTheme.primaryRed : colorForType(label);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: GlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: isSelected
                  ? accentColor.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: isDark ? 0.08 : 0.60),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : Colors.white.withValues(alpha: isDark ? 0.20 : 0.40),
                width: 1,
              ),
              onTap: () => _onTypeSelected(typeName),
              child: Center(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.85)
                            : const Color(0xFF2B2D42)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Main scrollable body showing shimmer skeletons, error card, empty state, or Pokémon grid.
  Widget _buildGridBody(bool isDark) {
    if (_isInitialLoading) {
      return const PokemonSkeletonGrid(itemCount: 8);
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: GlassCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: AppTheme.primaryRed,
                ),
                const SizedBox(height: 14),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14.5),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _isFilteringActive
                      ? _applyFilters
                      : _loadInitialData,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_displayedPokemon.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: GlassCard(
            borderRadius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.grey.shade500,
                ),
                const SizedBox(height: 12),
                Text(
                  'No Pokémon match your search.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.74,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final pokemon = _displayedPokemon[index];
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
              childCount: _displayedPokemon.length,
            ),
          ),
        ),

        // Infinite scroll footer: loading indicator, error retry bar, or end-of-list message
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildPaginationFooter(isDark),
          ),
        ),
      ],
    );
  }

  /// Small indicator or retry trigger at the bottom of the infinite scroll view.
  Widget _buildPaginationFooter(bool isDark) {
    if (_paginationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            onTap: _loadMore,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppTheme.primaryRed,
                ),
                const SizedBox(width: 8),
                Text(
                  _paginationError!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoadingMore) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.65),
          ),
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
            ),
          ),
        ),
      );
    }

    if (!_hasMore && _displayedPokemon.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'You have reached the end of the Pokédex!',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
