import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeepSeekService {
  static const String _apiUrl = 'https://api.deepseek.com/chat/completions';
  static const String _cachePrefix = 'ai_rec_';
  static const String _cacheTagsKey = 'ai_cache_tags';

  /// Generate personalized 2-sentence recommendation blurbs for For-You cards.
  static Future<Map<String, String>> generateRecommendations({
    required String apiKey,
    required List<String> preferredTags,
    required List<Map<String, dynamic>> topPlaces,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String cachedTags = prefs.getString(_cacheTagsKey) ?? '';
    final String currentTags = preferredTags.join(',');

    if (cachedTags == currentTags) {
      final Map<String, String> cached = <String, String>{};
      for (final Map<String, dynamic> place in topPlaces) {
        final String name = place['name'] as String;
        final String? text = prefs.getString('$_cachePrefix$name');
        if (text != null) cached[name] = text;
      }
      if (cached.length == topPlaces.length) return cached;
    }

    final Map<String, String> results = <String, String>{};
    for (final Map<String, dynamic> place in topPlaces.take(5)) {
      final String name = place['name'] as String;
      final String location = place['location'] as String;
      final List<String> tags = List<String>.from(place['tags'] as List);

      final String prompt =
          '你是专业旅游专家。该旅行者喜欢：${preferredTags.join('、')}。'
          '请用中文写恰好2句充满热情的话，说明为什么位于$location的"$name"'
          '（以${tags.join('、')}著称）对他们来说是完美之选。'
          '语言生动具体，不要用项目符号，不要用Markdown格式。';

      try {
        final String? text =
            await _call(apiKey: apiKey, prompt: prompt, maxTokens: 120);
        if (text != null) {
          results[name] = text.trim();
          await prefs.setString('$_cachePrefix$name', text.trim());
        }
      } catch (_) {}
    }

    await prefs.setString(_cacheTagsKey, currentTags);
    return results;
  }

  /// Enrich place data with AI-generated descriptions and structured fields.
  /// Updates each place's details / duration / budget / price (stay) in-place.
  static Future<void> enrichPlacesWithDescriptions({
    required String apiKey,
    required List<Map<String, dynamic>> places,
    void Function(int done, int total)? onProgress,
  }) async {
    // Group by city (prefix before '·', or full location)
    final Map<String, List<Map<String, dynamic>>> byCity =
        <String, List<Map<String, dynamic>>>{};
    for (final Map<String, dynamic> p in places) {
      final String loc = p['location'] as String? ?? '';
      final String city =
          loc.contains('·') ? loc.split('·').first.trim() : loc;
      byCity.putIfAbsent(city, () => <Map<String, dynamic>>[]).add(p);
    }

    final List<String> cityKeys = byCity.keys.toList();
    int done = 0;

    for (final String city in cityKeys) {
      final List<Map<String, dynamic>> cityPlaces = byCity[city]!;
      try {
        final Map<String, Map<String, String>> enriched =
            await _generateCityEnrichment(
          apiKey: apiKey,
          city: city,
          places: cityPlaces,
        );
        for (final Map<String, dynamic> p in cityPlaces) {
          final String name = p['name'] as String;
          final Map<String, String>? data = enriched[name];
          if (data == null) continue;
          if (data['details']?.isNotEmpty ?? false) {
            p['details'] = data['details'];
          }
          if (data['duration']?.isNotEmpty ?? false) {
            p['duration'] = data['duration'];
          }
          if (data['budget']?.isNotEmpty ?? false) {
            p['budget'] = data['budget'];
          }
          if (data['stay']?.isNotEmpty ?? false) {
            p['price'] = data['stay'];
          }
        }
      } catch (_) {}
      done++;
      onProgress?.call(done, cityKeys.length);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  static Future<Map<String, Map<String, String>>> _generateCityEnrichment({
    required String apiKey,
    required String city,
    required List<Map<String, dynamic>> places,
  }) async {
    final String placeList = places
        .map((Map<String, dynamic> p) {
          final List<dynamic> tags = p['tags'] as List<dynamic>;
          final String ticketHint = p['budget'] as String? ?? '未知';
          return '${p['name']}（${p['location']}，特色：${tags.join('/')}，高德门票参考：$ticketHint）';
        })
        .join('\n');

    final String prompt =
        '你是专业旅游内容编辑。请为以下${city}的每个景点提供详细信息，严格以JSON格式返回。\n\n'
        '每个景点对应一个对象，包含4个字段：\n'
        '- details：3-4句生动中文介绍，专门描述该景点本身的特色、历史背景、视觉亮点和适合人群（不要泛泛描述城市整体）\n'
        '- duration：在该景点的推荐游览时间，格式如"1–2 小时"、"半天"、"1 天"\n'
        '- budget：该景点的门票价格，格式如"¥60/人"、"¥120–180/人"、"免费"（确认无门票则填"免费"）\n'
        '- stay：该景点附近区域的酒店参考价格（根据景点所在具体位置和周边酒店档次判断，而非城市平均），格式如"¥300–600/晚"\n\n'
        '只返回JSON，不要其他内容，不要Markdown代码块。\n\n'
        '景点列表：\n$placeList';

    final String? raw =
        await _call(apiKey: apiKey, prompt: prompt, maxTokens: 2500);
    if (raw == null) return <String, Map<String, String>>{};

    String jsonStr = raw.trim();
    if (jsonStr.contains('```')) {
      final RegExp re = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
      final RegExpMatch? m = re.firstMatch(jsonStr);
      if (m != null) jsonStr = m.group(1)!.trim();
    }

    try {
      final Map<String, dynamic> parsed =
          jsonDecode(jsonStr) as Map<String, dynamic>;
      return parsed.map((String k, dynamic v) {
        final Map<String, dynamic> obj =
            Map<String, dynamic>.from(v as Map);
        return MapEntry(
          k,
          obj.map((String fk, dynamic fv) => MapEntry(fk, fv.toString())),
        );
      });
    } catch (_) {
      return <String, Map<String, String>>{};
    }
  }

  static Future<String?> _call({
    required String apiKey,
    required String prompt,
    int maxTokens = 120,
  }) async {
    final http.Response response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(<String, dynamic>{
            'model': 'deepseek-chat',
            'messages': <Map<String, String>>[
              <String, String>{'role': 'user', 'content': prompt},
            ],
            'max_tokens': maxTokens,
            'temperature': 0.7,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> choices = body['choices'] as List<dynamic>;
      if (choices.isNotEmpty) {
        return (choices.first['message'] as Map<String, dynamic>)['content']
            as String?;
      }
    }
    return null;
  }

  /// Generate a Chinese description for a single place on-demand.
  /// Result is cached in SharedPreferences by place name.
  static Future<String?> generatePlaceDescription({
    required String apiKey,
    required Map<String, dynamic> place,
  }) async {
    final String name = place['name'] as String? ?? '';
    if (name.isEmpty) return null;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String cacheKey = 'place_desc_$name';
    final String? cached = prefs.getString(cacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    final String location = place['location'] as String? ?? '';
    final List<dynamic> tags = place['tags'] as List<dynamic>? ?? <dynamic>[];
    final String budget = place['budget'] as String? ?? '';

    final String prompt =
        '你是专业旅游内容编辑。请用中文为"$name"（位于$location，'
        '特色：${tags.join('/')}，门票：$budget）写3-4句生动介绍，'
        '专注于该景点本身的特色、历史背景、视觉亮点和适合人群。'
        '不要泛泛描述城市，语言生动具体，无Markdown格式。';

    final String? text =
        await _call(apiKey: apiKey, prompt: prompt, maxTokens: 220);
    if (text != null && text.trim().isNotEmpty) {
      await prefs.setString(cacheKey, text.trim());
      return text.trim();
    }
    return null;
  }

  static Future<void> clearCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> keys = prefs
        .getKeys()
        .where((String k) =>
            k.startsWith(_cachePrefix) ||
            k.startsWith('place_desc_') ||
            k == _cacheTagsKey)
        .toList();
    for (final String k in keys) {
      await prefs.remove(k);
    }
  }
}
