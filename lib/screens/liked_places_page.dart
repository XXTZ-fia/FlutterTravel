import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/details.dart';
import 'package:flutter_travel/services/destination_repository.dart';
import 'package:flutter_travel/util/history_service.dart';
import 'package:flutter_travel/widgets/app_image.dart';

class LikedPlacesPage extends StatefulWidget {
  const LikedPlacesPage({super.key, this.onStateChanged});

  final ValueChanged<int>? onStateChanged;

  @override
  State<LikedPlacesPage> createState() => LikedPlacesPageState();
}

class LikedPlacesPageState extends State<LikedPlacesPage> {
  List<Map<String, dynamic>> _likedPlaces = <Map<String, dynamic>>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<dynamic> results = await Future.wait(<Future<dynamic>>[
      HistoryService.getLiked(),
      DestinationRepository.getFastDestinations(),
      HistoryService.getLikedPlacesData(),
    ]);
    final List<String> likedNames = results[0] as List<String>;
    final List<Map<String, dynamic>> allPlaces =
        results[1] as List<Map<String, dynamic>>;
    final List<Map<String, dynamic>> extraPlaces =
        results[2] as List<Map<String, dynamic>>;
    final List<Map<String, dynamic>> liked = allPlaces
        .where((Map<String, dynamic> place) => likedNames.contains(place['name']))
        .toList();
    final Set<String> foundNames =
        liked.map((Map<String, dynamic> p) => p['name'] as String).toSet();
    for (final Map<String, dynamic> extra in extraPlaces) {
      final String? name = extra['name'] as String?;
      if (name != null && likedNames.contains(name) && !foundNames.contains(name)) {
        liked.add(extra);
        foundNames.add(name);
      }
    }
    liked.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      return likedNames.indexOf(a['name'] as String)
          .compareTo(likedNames.indexOf(b['name'] as String));
    });
    if (!mounted) return;
    setState(() {
      _likedPlaces = liked;
      _loading = false;
    });
    widget.onStateChanged?.call(_likedPlaces.length);
  }

  Future<void> _removeLike(Map<String, dynamic> place) async {
    await HistoryService.toggleLike(place['name'] as String);
    if (!mounted) return;
    setState(() {
      _likedPlaces.removeWhere((Map<String, dynamic> item) => item['name'] == place['name']);
    });
    widget.onStateChanged?.call(_likedPlaces.length);
    await _load();
  }

  Future<void> refreshLikedPlaces() async {
    if (!mounted) return;
    setState(() => _loading = true);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        title: const Text('我喜欢的地方'),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _likedPlaces.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.favorite_border,
                            size: 72, color: Colors.blueGrey[300]),
                        const SizedBox(height: 18),
                        const Text(
                          '还没有喜欢的地方',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16324F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '在详情页点亮心形后，喜欢的地点会出现在这里。',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.blueGrey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    itemCount: _likedPlaces.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> place = _likedPlaces[index];
                      return InkWell(
                        onTap: () => Navigator.of(context)
                            .push(
                              MaterialPageRoute<void>(
                                builder: (_) => Details(
                                  place: Map<String, dynamic>.from(place),
                                ),
                              ),
                            )
                            .then((_) => refreshLikedPlaces()),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x0F16324F),
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: <Widget>[
                              AppImage(
                                src: place['img'] as String? ?? '',
                                height: 84,
                                width: 94,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      place['name'] as String? ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF16324F),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      place['location'] as String? ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.blueGrey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: <Widget>[
                                        const Icon(Icons.star_rounded,
                                            size: 16, color: Colors.amber),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${place['rating']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeLike(place),
                                icon: const Icon(Icons.favorite, color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
