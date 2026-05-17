import 'package:flutter_travel/util/history_service.dart';
import 'package:flutter_travel/util/preference_service.dart';

class RecommendationEngine {
  static Future<List<Map<String, dynamic>>> rank(
    List<Map<String, dynamic>> places,
  ) async {
    final List<String> preferredTags = await PreferenceService.getTags();
    final List<String> liked = await HistoryService.getLiked();
    final List<String> viewed = await HistoryService.getViewed();

    // Collect tags from liked places to infer indirect preference
    final Set<String> likedTags = <String>{};
    for (final Map<String, dynamic> place in places) {
      if (liked.contains(place['name'] as String)) {
        likedTags.addAll(List<String>.from(place['tags'] as List));
      }
    }

    final List<MapEntry<Map<String, dynamic>, double>> scored =
        places.map((Map<String, dynamic> place) {
      double score = (place['rating'] as num).toDouble();
      final List<String> tags = List<String>.from(place['tags'] as List);
      final String name = place['name'] as String;

      // +2.0 per preferred tag match
      for (final String tag in tags) {
        if (preferredTags.contains(tag)) score += 2.0;
      }

      // +1.5 per tag shared with liked places
      for (final String tag in tags) {
        if (likedTags.contains(tag)) score += 1.5;
      }

      // −0.5 if in recent 5 views (encourage variety)
      if (viewed.take(5).contains(name)) score -= 0.5;

      // +3.0 if directly liked
      if (liked.contains(name)) score += 3.0;

      return MapEntry<Map<String, dynamic>, double>(place, score);
    }).toList();

    scored.sort(
      (MapEntry<Map<String, dynamic>, double> a,
              MapEntry<Map<String, dynamic>, double> b) =>
          b.value.compareTo(a.value),
    );
    return scored.map((MapEntry<Map<String, dynamic>, double> e) => e.key).toList();
  }
}
