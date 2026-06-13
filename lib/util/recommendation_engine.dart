import 'package:flutter_travel/services/itinerary_service.dart';
import 'package:flutter_travel/util/history_service.dart';
import 'package:flutter_travel/util/preference_service.dart';

class RecommendationEngine {
  static Future<List<Map<String, dynamic>>> rank(
    List<Map<String, dynamic>> places,
  ) async {
    final List<String> preferredTags = await PreferenceService.getTags();
    final String budget = await PreferenceService.getBudget();
    final List<String> liked = await HistoryService.getLiked();
    final List<String> viewed = await HistoryService.getViewed();
    final List<Map<String, dynamic>> itineraries = await ItineraryService.getAll();

    // Collect tags from liked places to infer indirect preference
    final Set<String> likedTags = <String>{};
    final Set<String> scheduledNames = <String>{};
    final Set<String> scheduledTags = <String>{};
    for (final Map<String, dynamic> itinerary in itineraries) {
      final List<dynamic> plannedPlaces = itinerary['places'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic rawPlace in plannedPlaces) {
        final Map<String, dynamic> place = Map<String, dynamic>.from(rawPlace as Map);
        final String name = place['name'] as String? ?? '';
        if (name.isNotEmpty) scheduledNames.add(name);
        scheduledTags.addAll(List<String>.from(place['tags'] as List? ?? <String>[]));
      }
    }
    for (final Map<String, dynamic> place in places) {
      if (liked.contains(place['name'] as String)) {
        likedTags.addAll(List<String>.from(place['tags'] as List));
      }
    }

    final List<MapEntry<Map<String, dynamic>, double>> scored =
        places.map((Map<String, dynamic> place) {
      double score = ((place['rating'] as num?) ?? 0).toDouble() * 1.8;
      final List<String> tags = List<String>.from(place['tags'] as List);
      final String name = place['name'] as String;
      final List<String> reasons = <String>[];

      int preferredMatches = 0;
      for (final String tag in tags) {
        if (preferredTags.contains(tag)) {
          preferredMatches++;
          score += 2.4;
        }
      }
      if (preferredMatches > 0) reasons.add('匹配 $preferredMatches 个旅行偏好');

      int likedMatches = 0;
      for (final String tag in tags) {
        if (likedTags.contains(tag)) {
          likedMatches++;
          score += 1.4;
        }
      }
      if (likedMatches > 0) reasons.add('和你喜欢的地点风格接近');

      int scheduleMatches = 0;
      for (final String tag in tags) {
        if (scheduledTags.contains(tag)) {
          scheduleMatches++;
          score += 0.9;
        }
      }
      if (scheduleMatches > 0) reasons.add('适合和现有行程串联');

      if (_matchesBudget(place, budget)) {
        score += 1.2;
        reasons.add('预算匹配');
      }

      if (viewed.take(5).contains(name)) {
        score -= 0.7;
      }

      if (liked.contains(name)) {
        score += 3.2;
        reasons.add('你已经收藏过');
      }

      if (scheduledNames.contains(name)) {
        score -= 2.5;
      }

      final String duration = place['duration'] as String? ?? '';
      if (duration.contains('半天') || duration.contains('1 day')) {
        score += 0.5;
      }

      final String location = place['location'] as String? ?? '';
      if (location.contains('公园') || location.contains('古镇') || location.contains('博物馆')) {
        score += 0.4;
      }

      final double diversityBoost = 0.15 * tags.toSet().length;
      score += diversityBoost;

      return MapEntry<Map<String, dynamic>, double>(<String, dynamic>{
        ...place,
        'recommendationScore': score,
        'recommendationReasons': reasons.take(3).toList(),
      }, score);
    }).toList();

    scored.sort(
      (MapEntry<Map<String, dynamic>, double> a,
              MapEntry<Map<String, dynamic>, double> b) =>
          b.value.compareTo(a.value),
    );
    return scored.map((MapEntry<Map<String, dynamic>, double> e) => e.key).toList();
  }

  static bool _matchesBudget(Map<String, dynamic> place, String budget) {
    final String price = (place['price'] as String? ?? '').toLowerCase();
    switch (budget) {
      case 'low':
        return price.contains('budget') ||
            price.contains('¥') ||
            price.contains('cheap') ||
            price.contains('economy');
      case 'high':
        return price.contains('luxury') ||
            price.contains('premium') ||
            price.contains('resort') ||
            price.contains('high');
      default:
        return true;
    }
  }
}
