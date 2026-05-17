import 'package:flutter/material.dart';
import 'package:flutter_travel/services/api_key_service.dart';
import 'package:flutter_travel/services/deepseek_service.dart';
import 'package:flutter_travel/services/destination_repository.dart';
import 'package:flutter_travel/util/history_service.dart';
import 'package:flutter_travel/widgets/app_image.dart';
import 'package:flutter_travel/widgets/icon_badge.dart';

class Details extends StatefulWidget {
  const Details({super.key, required this.place});

  final Map<String, dynamic> place;

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  bool _isLiked = false;
  List<Map<String, dynamic>> _allPlaces = <Map<String, dynamic>>[];
  late String _details;
  bool _loadingDesc = false;

  @override
  void initState() {
    super.initState();
    _details = widget.place['details'] as String? ?? '';
    _init();
  }

  Future<void> _init() async {
    final String name = widget.place['name'] as String;
    final List<dynamic> results = await Future.wait(<Future<dynamic>>[
      HistoryService.recordView(name),
      HistoryService.isLiked(name),
      DestinationRepository.getDestinations(),
    ]);
    if (mounted) {
      setState(() {
        _isLiked = results[1] as bool;
        _allPlaces = results[2] as List<Map<String, dynamic>>;
      });
    }
    // 若描述过短（仅地址 fallback），自动调用 AI 补充
    if (_details.length < 80) {
      _loadAiDescription();
    }
  }

  Future<void> _loadAiDescription() async {
    final String apiKey = await ApiKeyService.load();
    if (apiKey.isEmpty) return;
    if (mounted) setState(() => _loadingDesc = true);
    try {
      final String? desc = await DeepSeekService.generatePlaceDescription(
        apiKey: apiKey,
        place: widget.place,
      );
      if (desc != null && mounted) {
        setState(() {
          _details = desc;
          _loadingDesc = false;
        });
      } else if (mounted) {
        setState(() => _loadingDesc = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDesc = false);
    }
  }

  Future<void> _toggleLike() async {
    final String name = widget.place['name'] as String;
    await HistoryService.toggleLike(name);
    if (mounted) setState(() => _isLiked = !_isLiked);
  }

  List<Map<String, dynamic>> get _similarPlaces {
    final List<String> currentTags =
        List<String>.from(widget.place['tags'] as List);
    final String currentName = widget.place['name'] as String;
    return _allPlaces
        .where((Map<String, dynamic> p) {
          if (p['name'] == currentName) return false;
          final List<String> tags = List<String>.from(p['tags'] as List);
          return tags.any((String t) => currentTags.contains(t));
        })
        .take(3)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> tags = List<String>.from(
      widget.place['tags'] as List? ?? <String>[],
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Destination Details'),
        actions: <Widget>[
          IconButton(
            icon: IconBadge(icon: Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          _buildHeaderImage(context),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${widget.place["name"]}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (Widget child,
                            Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          key: ValueKey<bool>(_isLiked),
                          color: _isLiked ? Colors.red : null,
                        ),
                      ),
                      onPressed: _toggleLike,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Icon(Icons.location_on,
                        size: 16, color: Colors.blueGrey[400]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${widget.place["location"]}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.blueGrey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    _InfoCard(
                      icon: Icons.star_rounded,
                      label: 'Rating',
                      value: '${widget.place["rating"]}',
                    ),
                    const SizedBox(width: 12),
                    _InfoCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Budget',
                      value: '${widget.place["budget"]}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    _InfoCard(
                      icon: Icons.schedule,
                      label: 'Duration',
                      value: '${widget.place["duration"]}',
                    ),
                    const SizedBox(width: 12),
                    _InfoCard(
                      icon: Icons.hotel_outlined,
                      label: 'Stay',
                      value: '${widget.place["price"]}',
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'Tags',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: tags
                      .map(
                        (String tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: Colors.blueGrey[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 28),
                Row(
                  children: <Widget>[
                    const Text(
                      'Description',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (_loadingDesc) ...<Widget>[
                      const SizedBox(width: 8),
                      const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _details,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 32),
                _buildSimilarPlaces(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: AppImage(
        src: '${widget.place["img"]}',
        height: 260,
        width: MediaQuery.of(context).size.width,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  Widget _buildSimilarPlaces(BuildContext context) {
    final List<Map<String, dynamic>> similar = _similarPlaces;
    if (similar.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'You might also like',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (BuildContext context, int i) {
              final Map<String, dynamic> p = similar[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        Details(place: Map<String, dynamic>.from(p)),
                  ),
                ),
                child: SizedBox(
                  width: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppImage(
                        src: p['img'] as String,
                        height: 110,
                        width: 160,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        p['location'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey[400],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.blueGrey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
