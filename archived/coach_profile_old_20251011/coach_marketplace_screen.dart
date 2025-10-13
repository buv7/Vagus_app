import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/branding/vagus_appbar.dart';
import '../../widgets/coaches/coach_marketplace_card.dart';
import '../../widgets/coaches/marketplace_search_bar.dart';
import '../../widgets/fab/qr_scanner_fab.dart';
import '../coach/coach_profile_public_screen.dart';
import 'qr_scanner_screen.dart';

class CoachMarketplaceScreen extends StatefulWidget {
  const CoachMarketplaceScreen({super.key});

  @override
  State<CoachMarketplaceScreen> createState() => _CoachMarketplaceScreenState();
}

class _CoachMarketplaceScreenState extends State<CoachMarketplaceScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _coaches = [];
  bool _loading = true;
  bool _loadingMore = false;
  String _error = '';
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadCoaches();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) {
        _loadMoreCoaches();
      }
    }
  }

  Future<void> _loadCoaches({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _coaches.clear();
        _hasMore = true;
        _error = '';
      });
    }

    setState(() {
      _loading = refresh || _currentPage == 0;
    });

    try {
      await _fetchCoaches();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading coaches: $e';
        });
      }
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreCoaches() async {
    if (_loadingMore || !_hasMore) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      await _fetchCoaches();
    } catch (e) {
      // Silently handle load more errors
      debugPrint('Error loading more coaches: $e');
    }

    if (mounted) {
      setState(() {
        _loadingMore = false;
      });
    }
  }

  Future<void> _fetchCoaches() async {
    final offset = _currentPage * _pageSize;
    
    // Use RPC function to fetch coaches with proper JOIN
    final response = await _supabase.rpc(
      'get_marketplace_coaches',
      params: {
        'search_query': _searchQuery.isEmpty ? null : _searchQuery,
        'limit_count': _pageSize,
        'offset_count': offset,
      }
    );

    final coaches = List<Map<String, dynamic>>.from(response as List);

    if (mounted) {
      setState(() {
        if (_currentPage == 0) {
          _coaches = coaches;
        } else {
          _coaches.addAll(coaches);
        }
        _currentPage++;
        _hasMore = coaches.length == _pageSize;
      });
    }
  }

  Future<void> _search(String query) async {
    if (_searchQuery == query) return;
    
    setState(() {
      _searchQuery = query;
    });
    
    await _loadCoaches(refresh: true);
  }

  void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );
  }

  void _openCoachProfile(Map<String, dynamic> coach) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoachProfilePublicScreen(
          coachId: coach['coach_id'],
          coachData: coach,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.primaryDark,
      appBar: VagusAppBar(
        title: const Text('Find a Coach'),
        backgroundColor: DesignTokens.primaryDark,
        foregroundColor: DesignTokens.neutralWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _openQRScanner,
            tooltip: 'Scan QR Code',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(DesignTokens.space16),
            child: MarketplaceSearchBar(
              controller: _searchController,
              onSearch: _search,
              hintText: 'Search by @username, name, or specialty',
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: QRScannerFAB(
        onPressed: _openQRScanner,
      ),
    );
  }

  Widget _buildContent() {
    if (_loading && _coaches.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: DesignTokens.accentGreen,
        ),
      );
    }

    if (_error.isNotEmpty && _coaches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: DesignTokens.accentPink,
              size: 64,
            ),
            const SizedBox(height: DesignTokens.space16),
            Text(
              _error,
              style: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.accentPink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space24),
            ElevatedButton(
              onPressed: () => _loadCoaches(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_coaches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              color: DesignTokens.textSecondary,
              size: 64,
            ),
            const SizedBox(height: DesignTokens.space16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No coaches found for "$_searchQuery"'
                  : 'No coaches found',
              style: DesignTokens.bodyMedium.copyWith(
                color: DesignTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCoaches(refresh: true),
      color: DesignTokens.accentGreen,
      backgroundColor: DesignTokens.cardBackground,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(DesignTokens.space16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: DesignTokens.space16,
          mainAxisSpacing: DesignTokens.space16,
        ),
        itemCount: _coaches.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _coaches.length) {
            // Loading indicator at the end
            return const Center(
              child: CircularProgressIndicator(
                color: DesignTokens.accentGreen,
              ),
            );
          }

          final coach = _coaches[index];
          return CoachMarketplaceCard(
            coach: coach,
            onTap: () => _openCoachProfile(coach),
          );
        },
      ),
    );
  }
}