import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_travel/services/amap_fetch_config.dart';
import 'package:flutter_travel/services/amap_key_service.dart';
import 'package:flutter_travel/services/amap_service.dart';
import 'package:flutter_travel/services/api_key_service.dart';
import 'package:flutter_travel/services/deepseek_service.dart';
import 'package:flutter_travel/util/places.dart';

class DestinationRepository {
  static const String _cacheKey = 'destinations_cache';
  static const String _cacheDateKey = 'destinations_cache_date';
  static const int _cacheDays = 7;

  /// Returns destinations from cache, Amap, or local fallback — in that order.
  static Future<List<Map<String, dynamic>>> getDestinations() async {
    final String amapKey = await AmapKeyService.load();
    if (amapKey.isEmpty) return List<Map<String, dynamic>>.from(places);

    final List<Map<String, dynamic>>? cached = await _loadCache();
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final AmapFetchConfig config = await AmapFetchConfig.load();
      final List<Map<String, dynamic>> fetched =
          await AmapService.fetchAllDestinations(
        amapKey,
        cities: config.cities,
        keywords: config.keywords,
        countPerCity: config.countPerCity,
      );
      if (fetched.isNotEmpty) {
        await _saveCache(fetched);
        return fetched;
      }
    } catch (_) {}

    return List<Map<String, dynamic>>.from(places);
  }

  /// Fetch fresh data using saved config.
  /// [onProgress] receives (done, total, phase) where phase is 'amap' or 'ai'.
  static Future<int> refresh({
    void Function(int done, int total, String phase)? onProgress,
  }) async {
    final String amapKey = await AmapKeyService.load();
    if (amapKey.isEmpty) return 0;

    final AmapFetchConfig config = await AmapFetchConfig.load();

    // Phase 1: Amap data fetch
    final List<Map<String, dynamic>> fetched =
        await AmapService.fetchAllDestinations(
      amapKey,
      cities: config.cities,
      keywords: config.keywords,
      countPerCity: config.countPerCity,
      onProgress: (int done, int total) =>
          onProgress?.call(done, total, 'amap'),
    );

    if (fetched.isEmpty) return 0;

    // Phase 2: AI descriptions (optional)
    if (config.useAiDescriptions) {
      final String deepseekKey = await ApiKeyService.load();
      if (deepseekKey.isNotEmpty) {
        await DeepSeekService.enrichPlacesWithDescriptions(
          apiKey: deepseekKey,
          places: fetched,
          onProgress: (int done, int total) =>
              onProgress?.call(done, total, 'ai'),
        );
      }
    }

    await _saveCache(fetched);
    return fetched.length;
  }

  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheDateKey);
  }

  /// Delete a single destination by name from cache.
  static Future<void> deleteDestination(String name) async {
    final List<Map<String, dynamic>>? cached = await _loadCache();
    if (cached == null) return;
    final List<Map<String, dynamic>> updated = cached
        .where((Map<String, dynamic> p) => p['name'] != name)
        .toList();
    await _saveCache(updated);
  }

  static Future<bool> get hasCachedData async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_cacheKey);
  }

  static Future<int> get cachedCount async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_cacheKey);
    if (raw == null) return 0;
    try {
      return (jsonDecode(raw) as List<dynamic>).length;
    } catch (_) {
      return 0;
    }
  }

  static Future<DateTime?> get cacheDate async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? ms = prefs.getInt(_cacheDateKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<List<Map<String, dynamic>>?> _loadCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? savedMs = prefs.getInt(_cacheDateKey);
    if (savedMs == null) return null;

    final DateTime savedDate = DateTime.fromMillisecondsSinceEpoch(savedMs);
    if (DateTime.now().difference(savedDate).inDays >= _cacheDays) {
      return null;
    }

    final String? raw = prefs.getString(_cacheKey);
    if (raw == null) return null;

    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((dynamic e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveCache(List<Map<String, dynamic>> data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(data));
    await prefs.setInt(
      _cacheDateKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
