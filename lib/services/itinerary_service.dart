import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ItineraryService {
  static const String _key = 'itineraries';

  static Future<List<Map<String, dynamic>>> getAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null) return <Map<String, dynamic>>[];

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((dynamic item) => _normalizeItinerary(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  static Future<void> _saveAll(List<Map<String, dynamic>> list) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<String> create({
    required String name,
    String? startDate,
    String? endDate,
  }) async {
    final List<Map<String, dynamic>> list = await getAll();
    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    list.add(<String, dynamic>{
      'id': id,
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'places': <dynamic>[],
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _saveAll(list);
    return id;
  }

  static Future<void> delete(String id) async {
    final List<Map<String, dynamic>> list = await getAll();
    list.removeWhere((Map<String, dynamic> item) => item['id'] == id);
    await _saveAll(list);
  }

  static Future<void> update(Map<String, dynamic> itinerary) async {
    final List<Map<String, dynamic>> list = await getAll();
    final int index =
        list.indexWhere((Map<String, dynamic> item) => item['id'] == itinerary['id']);
    if (index >= 0) {
      list[index] = _normalizeItinerary(Map<String, dynamic>.from(itinerary));
    }
    await _saveAll(list);
  }

  static Future<void> addPlace(
    String itineraryId,
    Map<String, dynamic> place, {
    int day = 1,
    String note = '',
    String? visitDate,
  }) async {
    final List<Map<String, dynamic>> list = await getAll();
    final int index =
        list.indexWhere((Map<String, dynamic> item) => item['id'] == itineraryId);
    if (index < 0) return;

    final Map<String, dynamic> itinerary = list[index];
    final String? resolvedVisitDate =
        visitDate ?? _deriveVisitDate(itinerary['startDate'] as String?, day);
    final int resolvedDay = resolvedVisitDate != null
        ? _deriveDay(itinerary['startDate'] as String?, resolvedVisitDate) ?? day
        : day;

    (itinerary['places'] as List<dynamic>).add(<String, dynamic>{
      'pid': DateTime.now().microsecondsSinceEpoch.toString(),
      'name': place['name'],
      'location': place['location'],
      'img': place['img'],
      'rating': place['rating'],
      'day': resolvedDay,
      'note': note,
      'visitDate': resolvedVisitDate,
      'lat': place['lat'],
      'lng': place['lng'],
      'tags': place['tags'],
      'price': place['price'],
      'budget': place['budget'],
      'duration': place['duration'],
      'details': place['details'],
      'addedAt': DateTime.now().toIso8601String(),
    });
    await _saveAll(list);
  }

  static Future<void> removePlace(String itineraryId, String pid) async {
    final List<Map<String, dynamic>> list = await getAll();
    final int index =
        list.indexWhere((Map<String, dynamic> item) => item['id'] == itineraryId);
    if (index < 0) return;
    (list[index]['places'] as List<dynamic>)
        .removeWhere((dynamic place) => (place as Map<String, dynamic>)['pid'] == pid);
    await _saveAll(list);
  }

  static Map<String, dynamic> _normalizeItinerary(Map<String, dynamic> raw) {
    final List<dynamic> rawPlaces = raw['places'] as List<dynamic>? ?? <dynamic>[];
    final String? startDate = raw['startDate'] as String?;
    return <String, dynamic>{
      ...raw,
      'places': rawPlaces.map((dynamic place) {
        final Map<String, dynamic> item = Map<String, dynamic>.from(place as Map);
        final int day = item['day'] as int? ?? 1;
        final String? visitDate =
            item['visitDate'] as String? ?? _deriveVisitDate(startDate, day);
        item['visitDate'] = visitDate;
        item['day'] = item['day'] ?? _deriveDay(startDate, visitDate) ?? day;
        return item;
      }).toList(),
    };
  }

  static String? _deriveVisitDate(String? startDate, int day) {
    if (startDate == null) return null;
    try {
      final DateTime base = DateTime.parse(startDate);
      final DateTime target = base.add(Duration(days: day - 1));
      return _formatDate(target);
    } catch (_) {
      return null;
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static int? _deriveDay(String? startDate, String? visitDate) {
    if (startDate == null || visitDate == null) return null;
    try {
      final DateTime start = DateTime.parse(startDate);
      final DateTime visit = DateTime.parse(visitDate);
      return visit.difference(start).inDays + 1;
    } catch (_) {
      return null;
    }
  }
}
