import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_travel/screens/details.dart';
import 'package:flutter_travel/services/amap_key_service.dart';
import 'package:flutter_travel/services/amap_service.dart';
import 'package:flutter_travel/services/destination_repository.dart';
import 'package:flutter_travel/services/itinerary_service.dart';
import 'package:flutter_travel/util/places.dart' as local_places;
import 'package:flutter_travel/util/travel_tags.dart';
import 'package:flutter_travel/widgets/app_image.dart';
import 'package:flutter_travel/widgets/schedule_add_sheet.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, this.initialSelectedPlace});

  final Map<String, dynamic>? initialSelectedPlace;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const List<String> _tags = <String>[
    TravelTags.all,
    TravelTags.nature,
    TravelTags.culture,
    TravelTags.food,
    TravelTags.city,
    TravelTags.family,
    TravelTags.budget,
  ];

  static const List<Color> _routePalette = <Color>[
    Color(0xFFEF6C57),
    Color(0xFF2C6E63),
    Color(0xFF5A67D8),
    Color(0xFFE39B2F),
    Color(0xFF0F9D91),
    Color(0xFFCA5C8A),
  ];

  static const LatLng _chinaCenter = LatLng(35.0, 105.0);
  static const double _defaultZoom = 4.0;

  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _places = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _schedules = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _nearbyPlaces = <Map<String, dynamic>>[];
  Map<String, dynamic>? _selected;
  LatLng? _tapPoint;
  String _selectedTag = TravelTags.all;
  bool _loading = true;
  bool _mapReady = false;
  bool _queryingNearby = false;
  String? _nearbyMessage;
  bool _appliedInitialFocus = false;

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
    final List<Map<String, dynamic>> quickPlaces =
        await DestinationRepository.getFastDestinations();
    final List<Map<String, dynamic>> itineraries = await ItineraryService.getAll();
    if (!mounted) return;
    setState(() {
      _places = quickPlaces;
      _schedules = itineraries;
      _loading = false;
    });
    _fitBoundsIfReady();
    _applyInitialFocusIfNeeded();

    final String amapKey = await AmapKeyService.load();
    if (amapKey.isEmpty) return;

    final List<dynamic> results = await Future.wait(<Future<dynamic>>[
      DestinationRepository.getDestinations(),
    ]);
    if (!mounted) return;
    setState(() {
      _places = results[0] as List<Map<String, dynamic>>;
    });
    _fitBoundsIfReady();
    _applyInitialFocusIfNeeded();
  }

  void _applyInitialFocusIfNeeded() {
    if (_appliedInitialFocus) return;
    final Map<String, dynamic>? place = widget.initialSelectedPlace;
    if (place == null) return;
    final double? lat = _toDouble(place['lat']);
    final double? lng = _toDouble(place['lng']);
    if (lat == null || lng == null) return;
    _appliedInitialFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(LatLng(lat, lng), 13.5);
      setState(() {
        _selected = place;
        _tapPoint = LatLng(lat, lng);
      });
    });
  }

  Future<void> _reloadSchedules() async {
    final List<Map<String, dynamic>> itineraries = await ItineraryService.getAll();
    if (!mounted) return;
    setState(() => _schedules = itineraries);
    _fitBoundsIfReady();
  }

  void _onMapReady() {
    _mapReady = true;
    _fitBoundsIfReady();
  }

  void _fitBoundsIfReady() {
    if (!_mapReady || _loading) return;

    final List<LatLng> points = <LatLng>[
      ..._allMappable.map(
        (Map<String, dynamic> place) =>
            LatLng(_toDouble(place['lat'])!, _toDouble(place['lng'])!),
      ),
      ..._scheduledStops.map(
        (Map<String, dynamic> stop) =>
            LatLng(_toDouble(stop['lat'])!, _toDouble(stop['lng'])!),
      ),
    ];
    if (points.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (points.length == 1) {
        _mapController.move(points.first, 12.0);
      } else {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.fromLTRB(40, 120, 40, 40),
          ),
        );
      }
    });
  }

  List<Map<String, dynamic>> get _allMappable {
    final Iterable<Map<String, dynamic>> source =
        _places.isNotEmpty ? _places : local_places.places;
    return source.where((Map<String, dynamic> place) {
      return _toDouble(place['lat']) != null && _toDouble(place['lng']) != null;
    }).toList();
  }

  List<Map<String, dynamic>> get _mappable {
    return _allMappable.where((Map<String, dynamic> place) {
      if (_selectedTag == TravelTags.all) return true;
      final List<dynamic> tags = place['tags'] as List<dynamic>? ?? <dynamic>[];
      return tags.contains(_selectedTag);
    }).toList();
  }

  List<Map<String, dynamic>> get _scheduledStops {
    final List<Map<String, dynamic>> stops = <Map<String, dynamic>>[];
    for (int scheduleIndex = 0; scheduleIndex < _schedules.length; scheduleIndex++) {
      final Map<String, dynamic> schedule = _schedules[scheduleIndex];
      final List<dynamic> places = schedule['places'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic rawPlace in places) {
        final Map<String, dynamic> place = Map<String, dynamic>.from(rawPlace as Map);
        if (_toDouble(place['lat']) == null || _toDouble(place['lng']) == null) continue;
        stops.add(<String, dynamic>{
          ...place,
          'scheduleId': schedule['id'],
          'scheduleName': schedule['name'],
          'routeColor': _routePalette[scheduleIndex % _routePalette.length].value,
        });
      }
    }
    return stops;
  }

  List<Polyline> get _schedulePolylines {
    final List<Polyline> lines = <Polyline>[];
    for (int scheduleIndex = 0; scheduleIndex < _schedules.length; scheduleIndex++) {
      final Map<String, dynamic> schedule = _schedules[scheduleIndex];
      final List<Map<String, dynamic>> points = (schedule['places'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .where((Map<String, dynamic> place) {
            return _toDouble(place['lat']) != null && _toDouble(place['lng']) != null;
          })
          .toList();
      points.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
        final String aDate = a['visitDate'] as String? ?? '';
        final String bDate = b['visitDate'] as String? ?? '';
        final int dateCompare = aDate.compareTo(bDate);
        if (dateCompare != 0) return dateCompare;
        final String aTime = a['addedAt'] as String? ?? '';
        final String bTime = b['addedAt'] as String? ?? '';
        return aTime.compareTo(bTime);
      });
      if (points.length < 2) continue;
      lines.add(
        Polyline(
          points: points
              .map((Map<String, dynamic> place) => LatLng(
                    _toDouble(place['lat'])!,
                    _toDouble(place['lng'])!,
                  ))
              .toList(),
          strokeWidth: 4,
          color: _routePalette[scheduleIndex % _routePalette.length],
        ),
      );
    }
    return lines;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Color _tagColor(List<dynamic> tags) {
    if (tags.contains(TravelTags.nature)) return Colors.blue.shade600;
    if (tags.contains(TravelTags.culture)) return Colors.orange.shade700;
    if (tags.contains(TravelTags.food)) return Colors.red.shade600;
    if (tags.contains(TravelTags.city)) return Colors.purple.shade600;
    if (tags.contains(TravelTags.family)) return Colors.green.shade700;
    if (tags.contains(TravelTags.budget)) return Colors.teal.shade600;
    return Colors.blueGrey.shade600;
  }

  void _onMarkerTap(Map<String, dynamic> place) {
    final double? lat = _toDouble(place['lat']);
    final double? lng = _toDouble(place['lng']);
    if (lat != null && lng != null) {
      _mapController.move(LatLng(lat, lng), 13.2);
    }
    setState(() => _selected = place);
  }

  Future<void> _onMapTap(LatLng point) async {
    setState(() {
      _tapPoint = point;
      _selected = null;
      _queryingNearby = true;
      _nearbyMessage = null;
      _nearbyPlaces = <Map<String, dynamic>>[];
    });

    final String amapKey = await AmapKeyService.load();
    if (amapKey.isEmpty) {
      if (!mounted) return;
      setState(() {
        _queryingNearby = false;
        _nearbyMessage = '请先在设置中配置高德 API Key，才能查询附近地点。';
      });
      return;
    }

    try {
      final List<Map<String, dynamic>> nearby = await AmapService.fetchNearbyPlaces(
        apiKey: amapKey,
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (!mounted) return;
      setState(() {
        _nearbyPlaces = nearby;
        _queryingNearby = false;
        _nearbyMessage = nearby.isEmpty ? '这个位置附近暂时没有找到合适地点。' : null;
        if (nearby.isNotEmpty) {
          _selected = nearby.first;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _queryingNearby = false;
        _nearbyMessage = '附近地点加载失败，请稍后再试。';
      });
    }
  }

  Future<void> _addToSchedule(Map<String, dynamic> place) async {
    final bool added = await showAddToScheduleSheet(context, place);
    if (!mounted || !added) return;
    await _reloadSchedules();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已将「${place['name']}」加入行程')),
    );
  }

  void _resetView() {
    setState(() {
      _tapPoint = null;
      _nearbyPlaces = <Map<String, dynamic>>[];
      _nearbyMessage = null;
      _selected = null;
    });
    if (_allMappable.isNotEmpty || _scheduledStops.isNotEmpty) {
      _fitBoundsIfReady();
    } else {
      _mapController.move(_chinaCenter, _defaultZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> scheduledStops = _scheduledStops;
    final List<Polyline> polylines = _schedulePolylines;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: <Widget>[
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _chinaCenter,
                    initialZoom: _defaultZoom,
                    onMapReady: _onMapReady,
                    onTap: (_, LatLng point) => _onMapTap(point),
                  ),
                  children: <Widget>[
                    TileLayer(
                      urlTemplate:
                          'https://webrd0{s}.is.autonavi.com/appmaptile'
                          '?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
                      subdomains: const <String>['1', '2', '3', '4'],
                      userAgentPackageName: 'com.flutter_travel.app',
                      maxZoom: 18,
                    ),
                    if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                    MarkerLayer(
                      markers: _mappable.map((Map<String, dynamic> place) {
                        final List<dynamic> tags = place['tags'] as List<dynamic>? ?? <dynamic>[];
                        return Marker(
                          point: LatLng(
                            _toDouble(place['lat'])!,
                            _toDouble(place['lng'])!,
                          ),
                          width: 34,
                          height: 38,
                          child: GestureDetector(
                            onTap: () => _onMarkerTap(place),
                            child: Icon(
                              Icons.location_pin,
                              size: 34,
                              color: _tagColor(tags).withOpacity(0.72),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    MarkerLayer(
                      markers: scheduledStops.map((Map<String, dynamic> stop) {
                        final Color color = Color(stop['routeColor'] as int);
                        return Marker(
                          point: LatLng(
                            _toDouble(stop['lat'])!,
                            _toDouble(stop['lng'])!,
                          ),
                          width: 46,
                          height: 46,
                          child: GestureDetector(
                            onTap: () => _onMarkerTap(stop),
                            child: Transform.rotate(
                              angle: -math.pi / 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const <BoxShadow>[
                                    BoxShadow(
                                      color: Color(0x22000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Transform.rotate(
                                  angle: math.pi / 4,
                                  child: const Icon(
                                    Icons.navigation_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_tapPoint != null)
                      MarkerLayer(
                        markers: <Marker>[
                          Marker(
                            point: _tapPoint!,
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF16324F),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.white.withAlpha(236),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            height: 52,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              scrollDirection: Axis.horizontal,
                              itemCount: _tags.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 6),
                              itemBuilder: (BuildContext context, int index) {
                                final String tag = _tags[index];
                                final bool selected = _selectedTag == tag;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedTag = tag),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          selected ? const Color(0xFF16324F) : Colors.white,
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
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: selected ? Colors.white : Colors.blueGrey[700],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F9FC),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16324F),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.touch_app_outlined, color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '点击地图任意位置，用高德 API 查附近地点；带箭头的点表示已加入行程，并按同色线路连接。',
                                      style: TextStyle(
                                        height: 1.35,
                                        color: Colors.blueGrey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 126,
                  right: 16,
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        _MiniBadge(label: '${_mappable.length} 个目的地'),
                        const SizedBox(height: 8),
                        _MiniBadge(label: '${_schedules.length} 条行程'),
                      ],
                    ),
                  ),
                ),
                if (_tapPoint == null)
                  Positioned(
                    left: 16,
                    bottom: _selected != null ? 318 : 24,
                    child: SafeArea(
                      top: false,
                      child: _RouteLegend(schedules: _schedules, palette: _routePalette),
                    ),
                  ),
                if (_tapPoint != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: _selected != null ? 318 : 24,
                    child: _NearbyPanel(
                      loading: _queryingNearby,
                      message: _nearbyMessage,
                      places: _nearbyPlaces,
                      onSelect: _onMarkerTap,
                      onAdd: _addToSchedule,
                    ),
                  ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  bottom: _selected != null ? 0 : -330,
                  left: 0,
                  right: 0,
                  child: _selected == null
                      ? const SizedBox.shrink()
                      : _PlaceCard(
                          place: _selected!,
                          onClose: () => setState(() => _selected = null),
                          onDetails: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => Details(
                                  place: Map<String, dynamic>.from(_selected!),
                                ),
                              ),
                            );
                          },
                          onAdd: () => _addToSchedule(_selected!),
                        ),
                ),
                Positioned(
                  right: 16,
                  bottom: _selected != null ? 292 : 24,
                  child: Column(
                    children: <Widget>[
                      if (_tapPoint != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FloatingActionButton.small(
                            heroTag: 'clear-selection',
                            onPressed: _resetView,
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF16324F),
                            child: const Icon(Icons.close),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FloatingActionButton.small(
                          heroTag: 'refresh-routes',
                          onPressed: _load,
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF16324F),
                          child: const Icon(Icons.refresh),
                        ),
                      ),
                      FloatingActionButton.small(
                        heroTag: 'fit-all',
                        onPressed: _resetView,
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF16324F),
                        child: const Icon(Icons.fit_screen),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x22000000), blurRadius: 6),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF16324F),
        ),
      ),
    );
  }
}

class _RouteLegend extends StatelessWidget {
  const _RouteLegend({
    required this.schedules,
    required this.palette,
  });

  final List<Map<String, dynamic>> schedules;
  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(242),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            '路线图例',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF16324F)),
          ),
          const SizedBox(height: 10),
          ...schedules.asMap().entries.take(4).map((MapEntry<int, Map<String, dynamic>> entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: palette[entry.key % palette.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value['name'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.blueGrey[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NearbyPanel extends StatelessWidget {
  const _NearbyPanel({
    required this.loading,
    required this.message,
    required this.places,
    required this.onSelect,
    required this.onAdd,
  });

  final bool loading;
  final String? message;
  final List<Map<String, dynamic>> places;
  final void Function(Map<String, dynamic> place) onSelect;
  final void Function(Map<String, dynamic> place) onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x22000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            '附近地点',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF16324F)),
          ),
          const SizedBox(height: 4),
          Text(
            '基于地图点选结果，可直接查看并加入行程。',
            style: TextStyle(color: Colors.blueGrey[500], fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(message!, style: TextStyle(color: Colors.blueGrey[500])),
            )
          else
            SizedBox(
              height: 196,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: places.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (BuildContext context, int index) {
                  final Map<String, dynamic> place = places[index];
                  final int? distance = place['distance'] as int?;
                  final String distanceLabel = distance == null
                      ? '附近'
                      : distance >= 1000
                          ? '${(distance / 1000).toStringAsFixed(1)} km'
                          : '$distance m';
                  return InkWell(
                    onTap: () => onSelect(place),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 214,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFD),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AppImage(
                              src: place['img'] as String? ?? '',
                              height: 74,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            place['name'] as String? ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16324F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            distanceLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2C6E63),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => onAdd(place),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF16324F),
                                side: const BorderSide(color: Color(0xFF16324F)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('加入行程'),
                            ),
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

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.onClose,
    required this.onDetails,
    required this.onAdd,
  });

  final Map<String, dynamic> place;
  final VoidCallback onClose;
  final VoidCallback onDetails;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final List<String> tags = List<String>.from(place['tags'] as List? ?? <String>[]);
    final double bottomPad = MediaQuery.of(context).padding.bottom;
    final int? distance = place['distance'] as int?;
    final String? visitDate = place['visitDate'] as String?;
    final String? scheduleName = place['scheduleName'] as String?;
    final String distanceLabel = distance == null
        ? ''
        : distance >= 1000
            ? '${(distance / 1000).toStringAsFixed(1)} km'
            : '$distance m';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Color(0x30000000), blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
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
                borderRadius: BorderRadius.circular(14),
                child: AppImage(
                  src: place['img'] as String? ?? '',
                  height: 92,
                  width: 92,
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
                            place['name'] as String? ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.blueGrey[400], size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place['location'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey[500]),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                        const SizedBox(width: 2),
                        Text(
                          '${place['rating']}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        if (distanceLabel.isNotEmpty) ...<Widget>[
                          const SizedBox(width: 10),
                          Icon(Icons.near_me_outlined, size: 13, color: Colors.blueGrey[400]),
                          const SizedBox(width: 3),
                          Text(
                            distanceLabel,
                            style: TextStyle(fontSize: 11, color: Colors.blueGrey[600]),
                          ),
                        ],
                      ],
                    ),
                    if (visitDate != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        scheduleName == null
                            ? '已安排在 $visitDate'
                            : '$scheduleName · $visitDate',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C6E63),
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags.take(3).map((String tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1F8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tag,
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
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: const Text('加入行程'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF16324F),
                    side: const BorderSide(color: Color(0xFF16324F)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.explore_outlined, size: 18),
                  label: const Text('查看详情'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16324F),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
