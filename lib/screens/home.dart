import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/details.dart';
import 'package:flutter_travel/services/amap_key_service.dart';
import 'package:flutter_travel/services/amap_service.dart';
import 'package:flutter_travel/services/api_key_service.dart';
import 'package:flutter_travel/services/deepseek_service.dart';
import 'package:flutter_travel/services/destination_repository.dart';
import 'package:flutter_travel/util/preference_service.dart';
import 'package:flutter_travel/util/recommendation_engine.dart';
import 'package:flutter_travel/widgets/app_image.dart';
import 'package:flutter_travel/widgets/icon_badge.dart';
import 'package:flutter_travel/widgets/todo_sheet.dart';
import 'package:flutter_travel/widgets/vertical_place_item.dart';
import 'package:flutter_travel/util/multilingual_search.dart';
import 'package:flutter_travel/util/travel_tags.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedTag = TravelTags.all;
  bool _searchingRemote = false;
  int _searchRequestId = 0;

  List<Map<String, dynamic>> _rankedPlaces = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _localSearchResults = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _remoteSearchResults = <Map<String, dynamic>>[];
  Map<String, String> _aiTexts = <String, String>{};
  List<String> _preferredTags = <String>[];
  bool _loadingRec = true;
  bool _loadingAi = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String value) async {
    final String query = value.trim();
    final List<Map<String, dynamic>> localMatches = query.isEmpty
        ? <Map<String, dynamic>>[]
        : _rankedPlaces
            .where((Map<String, dynamic> p) => MultilingualSearch.matchesPlace(p, query))
            .toList();

    setState(() {
      _searchQuery = value;
      _localSearchResults = localMatches;
      _searchingRemote = query.isNotEmpty;
      if (query.isEmpty) {
        _remoteSearchResults = <Map<String, dynamic>>[];
      }
    });

    if (query.isEmpty) return;

    final int requestId = ++_searchRequestId;
    final String amapKey = await AmapKeyService.load();
    if (requestId != _searchRequestId || !mounted) return;

    if (amapKey.isEmpty) {
      setState(() {
        _remoteSearchResults = <Map<String, dynamic>>[];
        _searchingRemote = false;
      });
      return;
    }

    try {
      final List<Map<String, dynamic>> results = await AmapService.searchPlaces(
        apiKey: amapKey,
        query: query,
      );
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _remoteSearchResults = results;
        _searchingRemote = false;
      });
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _remoteSearchResults = <Map<String, dynamic>>[];
        _searchingRemote = false;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    // Phase 1 — local ranking (fast)
    final List<String> prefs = await PreferenceService.getTags();
    final List<Map<String, dynamic>> allDests =
        await DestinationRepository.getDestinations();
    final List<Map<String, dynamic>> ranked =
        await RecommendationEngine.rank(allDests);

    if (!mounted) return;
    setState(() {
      _preferredTags = prefs;
      _rankedPlaces = ranked;
      _loadingRec = false;
    });

    // Phase 2 — AI texts (potentially slow, shown when ready)
    if (prefs.isEmpty) return;
    final String apiKey = await ApiKeyService.load();
    if (apiKey.isEmpty) return;

    setState(() => _loadingAi = true);
    try {
      final Map<String, String> aiTexts =
          await DeepSeekService.generateRecommendations(
        apiKey: apiKey,
        preferredTags: prefs,
        topPlaces: _forYouPlaces,
      );
      if (mounted) {
        setState(() {
          _aiTexts = aiTexts;
          _loadingAi = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingAi = false);
    }
  }

  List<Map<String, dynamic>> get _forYouPlaces {
    if (_preferredTags.isEmpty) return _rankedPlaces.take(5).toList();
    return _rankedPlaces
        .where((Map<String, dynamic> p) {
          final List<String> tags = List<String>.from(p['tags'] as List);
          return tags.any((String t) => _preferredTags.contains(t));
        })
        .take(5)
        .toList();
  }

  List<Map<String, dynamic>> get _displayedPlaces {
    List<Map<String, dynamic>> result;
    if (_searchQuery.isNotEmpty) {
      // Merge local (immediate, English-friendly) + remote (AMap async), deduplicated by name
      final Map<String, Map<String, dynamic>> merged = <String, Map<String, dynamic>>{};
      for (final Map<String, dynamic> p in _localSearchResults) {
        merged[p['name'] as String? ?? ''] = p;
      }
      for (final Map<String, dynamic> p in _remoteSearchResults) {
        merged[p['name'] as String? ?? ''] = p;
      }
      result = merged.values.toList();
    } else {
      result = List<Map<String, dynamic>>.from(_rankedPlaces);
    }

    if (_selectedTag != TravelTags.all) {
      result = result.where((Map<String, dynamic> p) {
        final List<String> tags = List<String>.from(p['tags'] as List? ?? <String>[]);
        return tags.contains(_selectedTag);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发现'),
        actions: <Widget>[
          IconButton(
            icon: IconBadge(icon: Icons.notifications_none),
            onPressed: () => showTodoSheet(context),
          ),
        ],
      ),
      body: _loadingRec
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecommendations,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  _buildHeader(),
                  _buildSearchBar(),
                  _buildFilterChips(),
                  if (_preferredTags.isNotEmpty &&
                      _searchQuery.isEmpty &&
                      _selectedTag == TravelTags.all)
                    _buildForYouSection(),
                  _buildAllDestinations(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '下一站\n想去哪里？',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '根据你的旅行偏好，为你挑选更对味的目的地。',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: '搜索目的地、城市或景点…',
          prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
          filled: true,
          fillColor: const Color(0xFFF6F8FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _localSearchResults = <Map<String, dynamic>>[];
                      _remoteSearchResults = <Map<String, dynamic>>[];
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final List<String> chips = <String>[TravelTags.all, ...PreferenceService.allTags];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int i) {
          final String tag = chips[i];
          final bool selected = _selectedTag == tag;
          return GestureDetector(
            onTap: () => setState(() => _selectedTag = tag),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF16324F)
                    : const Color(0xFFF6F8FB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF16324F)
                      : const Color(0xFFD6E0EA),
                ),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.blueGrey[700],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForYouSection() {
    final List<Map<String, dynamic>> forYou = _forYouPlaces;
    if (forYou.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Row(
            children: <Widget>[
              const Text(
                '为你推荐',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              if (_loadingAi)
                const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        SizedBox(
          height: _aiTexts.isNotEmpty ? 312 : 252,
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 20, right: 4),
            scrollDirection: Axis.horizontal,
            itemCount: forYou.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (BuildContext context, int i) {
              final Map<String, dynamic> place = forYou[i];
              final String name = place['name'] as String;
              return _ForYouCard(
                place: place,
                aiText: _aiTexts[name],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAllDestinations() {
    final List<Map<String, dynamic>> shown = _displayedPlaces;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _searchQuery.isNotEmpty
                ? (_searchingRemote ? '正在搜索高德结果…' : '高德搜索结果')
                : (_selectedTag == TravelTags.all ? '全部目的地' : '$_selectedTag 推荐'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          if (_searchQuery.isNotEmpty && _searchingRemote)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (shown.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  _searchQuery.isNotEmpty
                      ? '没有找到高德搜索结果。'
                      : '没有找到匹配的目的地。',
                  style: TextStyle(color: Colors.blueGrey[400]),
                ),
              ),
            )
          else
            ListView.builder(
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: shown.length,
              itemBuilder: (BuildContext context, int i) =>
                  VerticalPlaceItem(place: shown[i]),
            ),
        ],
      ),
    );
  }
}

class _ForYouCard extends StatelessWidget {
  const _ForYouCard({required this.place, this.aiText});

  final Map<String, dynamic> place;
  final String? aiText;

  @override
  Widget build(BuildContext context) {
    final List<String> reasons =
        List<String>.from(place['recommendationReasons'] as List? ?? <String>[]);
    return GestureDetector(
      onTap: () {
        final Map<String, dynamic> enriched =
            Map<String, dynamic>.from(place);
        if (aiText != null) {
          final String existing = enriched['details'] as String? ?? '';
          enriched['details'] =
              existing.isNotEmpty ? '$aiText\n\n$existing' : aiText!;
        }
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Details(place: enriched),
          ),
        );
      },
      child: SizedBox(
        width: 200,
        height: aiText != null ? 312 : 252,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                AppImage(
                  src: place['img'] as String,
                  height: 142,
                  width: 200,
                  borderRadius: BorderRadius.circular(14),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          '${place["rating"]}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              place['name'] as String,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                Icon(Icons.location_on, size: 12, color: Colors.blueGrey[400]),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    place['location'] as String,
                    style: TextStyle(
                        fontSize: 12, color: Colors.blueGrey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (aiText != null)
                      Text(
                        aiText!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey[600],
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (aiText != null && reasons.isNotEmpty) const SizedBox(height: 8),
                    if (reasons.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: reasons.take(1).map((String reason) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F1F8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              reason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF16324F),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
