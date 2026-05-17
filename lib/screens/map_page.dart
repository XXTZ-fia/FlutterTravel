import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_travel/screens/details.dart';
import 'package:flutter_travel/services/destination_repository.dart';
import 'package:flutter_travel/widgets/app_image.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _places = <Map<String, dynamic>>[];
  Map<String, dynamic>? _selected;
  String _selectedTag = 'All';
  bool _loading = true;
  bool _mapReady = false;

  static const List<String> _tags = <String>[
    'All', 'Beach', 'Adventure', 'Culture', 'Food', 'Shopping', 'Budget',
  ];

  static const LatLng _chinaCenter = LatLng(35.0, 105.0);
  static const double _defaultZoom = 4.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final List<Map<String, dynamic>> data =
        await DestinationRepository.getDestinations();
    if (mounted) {
      setState(() {
        _places = data;
        _loading = false;
      });
      _fitBoundsIfReady();
    }
  }

  void _onMapReady() {
    _mapReady = true;
    _fitBoundsIfReady();
  }

  void _fitBoundsIfReady() {
    if (!_mapReady || _loading) return;
    final List<Map<String, dynamic>> withCoords = _allMappable;
    if (withCoords.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final List<LatLng> points = withCoords
          .map((Map<String, dynamic> p) =>
              LatLng(_toDouble(p['lat'])!, _toDouble(p['lng'])!))
          .toList();
      if (points.length == 1) {
        _mapController.move(points.first, 12.0);
      } else {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.fromLTRB(40, 80, 40, 40),
          ),
        );
      }
    });
  }

  // All places with valid coordinates, regardless of tag filter
  List<Map<String, dynamic>> get _allMappable {
    return _places.where((Map<String, dynamic> p) {
      return _toDouble(p['lat']) != null && _toDouble(p['lng']) != null;
    }).toList();
  }

  // Filtered + mappable for marker rendering
  List<Map<String, dynamic>> get _mappable {
    return _places.where((Map<String, dynamic> p) {
      if (_toDouble(p['lat']) == null || _toDouble(p['lng']) == null) {
        return false;
      }
      if (_selectedTag == 'All') return true;
      final List<dynamic> tags = p['tags'] as List<dynamic>;
      return tags.contains(_selectedTag);
    }).toList();
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  Color _tagColor(List<dynamic> tags) {
    if (tags.contains('Beach')) return Colors.blue.shade600;
    if (tags.contains('Adventure')) return Colors.green.shade700;
    if (tags.contains('Culture')) return Colors.orange.shade700;
    if (tags.contains('Food')) return Colors.red.shade600;
    if (tags.contains('Shopping')) return Colors.purple.shade600;
    if (tags.contains('Budget')) return Colors.teal.shade600;
    return Colors.blueGrey.shade600;
  }

  void _onMarkerTap(Map<String, dynamic> place) {
    final double? lat = _toDouble(place['lat']);
    final double? lng = _toDouble(place['lng']);
    if (lat != null && lng != null) {
      _mapController.move(LatLng(lat, lng), 13.0);
    }
    setState(() => _selected = place);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: <Widget>[
                // ── Map ──────────────────────────────────────────────
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _chinaCenter,
                    initialZoom: _defaultZoom,
                    onMapReady: _onMapReady,
                    onTap: (_, __) => setState(() => _selected = null),
                  ),
                  children: <Widget>[
                    TileLayer(
                      // Amap CDN tiles — reliable in mainland China
                      urlTemplate:
                          'https://webrd0{s}.is.autonavi.com/appmaptile'
                          '?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
                      subdomains: const <String>['1', '2', '3', '4'],
                      userAgentPackageName: 'com.flutter_travel.app',
                      maxZoom: 18,
                    ),
                    MarkerLayer(
                      markers: _mappable
                          .map((Map<String, dynamic> p) {
                            final double lat = _toDouble(p['lat'])!;
                            final double lng = _toDouble(p['lng'])!;
                            final List<dynamic> tags =
                                p['tags'] as List<dynamic>;
                            final Color color = _tagColor(tags);
                            final bool isSelected =
                                _selected?['name'] == p['name'];

                            return Marker(
                              point: LatLng(lat, lng),
                              width: 40,
                              height: 44,
                              child: GestureDetector(
                                onTap: () => _onMarkerTap(p),
                                child: AnimatedScale(
                                  scale: isSelected ? 1.35 : 1.0,
                                  duration:
                                      const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.location_pin,
                                    color: color,
                                    size: 40,
                                    shadows: const <Shadow>[
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 4,
                                        offset: Offset(1, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ],
                ),

                // ── Tag filter bar (top) ──────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.white.withAlpha(235),
                    child: SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: 52,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          scrollDirection: Axis.horizontal,
                          itemCount: _tags.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 6),
                          itemBuilder: (BuildContext ctx, int i) {
                            final String tag = _tags[i];
                            final bool sel = _selectedTag == tag;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedTag = tag;
                                _selected = null;
                              }),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? const Color(0xFF16324F)
                                      : Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  border: Border.all(
                                    color: sel
                                        ? const Color(0xFF16324F)
                                        : const Color(0xFFD6E0EA),
                                  ),
                                  boxShadow: sel
                                      ? const <BoxShadow>[]
                                      : const <BoxShadow>[
                                          BoxShadow(
                                            color: Color(0x14000000),
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? Colors.white
                                        : Colors.blueGrey[700],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Stats badge ───────────────────────────────────────
                Positioned(
                  top: 60,
                  right: 16,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                              color: Color(0x22000000), blurRadius: 6),
                        ],
                      ),
                      child: Text(
                        '${_mappable.length} 个目的地',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16324F),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── No-coords hint ────────────────────────────────────
                if (_allMappable.isEmpty && !_loading)
                  Positioned(
                    bottom: 100,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                              color: Color(0x22000000), blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.location_off_outlined,
                              size: 28, color: Colors.blueGrey[400]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text('暂无可定位目的地',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text(
                                  '请前往 Profile → 高德地图数据 获取真实目的地坐标',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey[500]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Place card (bottom slide-up) ──────────────────────
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  bottom: _selected != null ? 0 : -260,
                  left: 0,
                  right: 0,
                  child: _selected != null
                      ? _PlaceCard(
                          place: _selected!,
                          onClose: () =>
                              setState(() => _selected = null),
                          onDetails: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => Details(
                                  place: Map<String, dynamic>.from(
                                      _selected!),
                                ),
                              ),
                            );
                          },
                        )
                      : const SizedBox.shrink(),
                ),

                // ── Reset-view FAB ────────────────────────────────────
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  right: 16,
                  bottom: _selected != null ? 256 : 24,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      if (_allMappable.isNotEmpty) {
                        _fitBoundsIfReady();
                      } else {
                        _mapController.move(_chinaCenter, _defaultZoom);
                      }
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF16324F),
                    tooltip: '显示全部',
                    child: const Icon(Icons.fit_screen),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Place card ────────────────────────────────────────────────────────────────

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.onClose,
    required this.onDetails,
  });

  final Map<String, dynamic> place;
  final VoidCallback onClose;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final List<String> tags =
        List<String>.from(place['tags'] as List<dynamic>);
    final double bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.blueGrey[200],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppImage(
                  src: place['img'] as String,
                  height: 88,
                  width: 88,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            place['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: Colors.blueGrey[400], size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: <Widget>[
                        Icon(Icons.location_on,
                            size: 12, color: Colors.blueGrey[400]),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            place['location'] as String,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${place['rating']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        ...tags.take(2).map(
                              (String t) => Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F1F8),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    t,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF16324F),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Icon(Icons.hotel_outlined,
                            size: 12, color: Colors.blueGrey[400]),
                        const SizedBox(width: 3),
                        Text(
                          place['price'] as String,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.blueGrey[600]),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.schedule,
                            size: 12, color: Colors.blueGrey[400]),
                        const SizedBox(width: 3),
                        Text(
                          place['duration'] as String,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.blueGrey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onDetails,
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text('查看详情'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16324F),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
