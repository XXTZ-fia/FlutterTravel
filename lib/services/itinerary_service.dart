import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ItineraryService {
  static const String _key = 'itineraries';

  static Future<List<Map<String, dynamic>>> getAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null) return <Map<String, dynamic>>[];
    return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  static Future<void> _saveAll(List<Map<String, dynamic>> list) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<void> create({
    required String name,
    String? startDate,
    String? endDate,
  }) async {
    final List<Map<String, dynamic>> list = await getAll();
    list.add(<String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'places': <dynamic>[],
    });
    await _saveAll(list);
  }

  static Future<void> delete(String id) async {
    final List<Map<String, dynamic>> list = await getAll();
    list.removeWhere((Map<String, dynamic> m) => m['id'] == id);
    await _saveAll(list);
  }

  static Future<void> update(Map<String, dynamic> itinerary) async {
    final List<Map<String, dynamic>> list = await getAll();
    final int idx = list.indexWhere(
        (Map<String, dynamic> m) => m['id'] == itinerary['id']);
    if (idx >= 0) list[idx] = itinerary;
    await _saveAll(list);
  }

  static Future<void> addPlace(
    String itineraryId,
    Map<String, dynamic> place, {
    int day = 1,
    String note = '',
  }) async {
    final List<Map<String, dynamic>> list = await getAll();
    final int idx = list
        .indexWhere((Map<String, dynamic> m) => m['id'] == itineraryId);
    if (idx < 0) return;
    (list[idx]['places'] as List<dynamic>).add(<String, dynamic>{
      'pid': DateTime.now().microsecondsSinceEpoch.toString(),
      'name': place['name'],
      'location': place['location'],
      'img': place['img'],
      'rating': place['rating'],
      'day': day,
      'note': note,
    });
    await _saveAll(list);
  }

  static Future<void> removePlace(String itineraryId, String pid) async {
    final List<Map<String, dynamic>> list = await getAll();
    final int idx = list
        .indexWhere((Map<String, dynamic> m) => m['id'] == itineraryId);
    if (idx < 0) return;
    (list[idx]['places'] as List<dynamic>)
        .removeWhere((dynamic p) => (p as Map<String, dynamic>)['pid'] == pid);
    await _saveAll(list);
  }
}
