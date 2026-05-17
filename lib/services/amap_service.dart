import 'dart:convert';
import 'package:http/http.dart' as http;

class AmapService {
  static const String _baseUrl = 'https://restapi.amap.com/v3/place/text';

  static const List<String> defaultCities = <String>[
    '北京', '上海', '成都', '西安', '杭州',
    '桂林', '三亚', '丽江', '厦门', '张家界',
  ];

  // Maps keyword preset → Amap type code
  static const Map<String, String> _keywordType = <String, String>{
    '旅游景点':  '110000',
    '主题公园':  '110102',
    '自然风景区': '110100',
    '历史古迹':  '110200',
    '酒店':    '100000',
    '美食餐厅':  '050000',
    '购物中心':  '060000',
  };

  static const Map<String, List<String>> _cityTags =
      <String, List<String>>{
    '北京':    <String>['Culture', 'Shopping', 'Food'],
    '上海':    <String>['Shopping', 'Food', 'Culture'],
    '成都':    <String>['Food', 'Culture', 'Budget'],
    '西安':    <String>['Culture', 'Food', 'Adventure'],
    '杭州':    <String>['Culture', 'Adventure', 'Budget'],
    '桂林':    <String>['Adventure', 'Culture', 'Budget'],
    '三亚':    <String>['Beach', 'Adventure', 'Budget'],
    '丽江':    <String>['Adventure', 'Culture', 'Budget'],
    '厦门':    <String>['Beach', 'Culture', 'Food'],
    '张家界':  <String>['Adventure', 'Culture', 'Budget'],
    '重庆':    <String>['Food', 'Adventure', 'Culture'],
    '广州':    <String>['Food', 'Shopping', 'Culture'],
    '深圳':    <String>['Shopping', 'Culture', 'Adventure'],
    '苏州':    <String>['Culture', 'Budget', 'Adventure'],
    '南京':    <String>['Culture', 'Food', 'Adventure'],
    '武汉':    <String>['Culture', 'Food', 'Budget'],
    '青岛':    <String>['Beach', 'Food', 'Culture'],
    '大连':    <String>['Beach', 'Culture', 'Budget'],
    '昆明':    <String>['Adventure', 'Culture', 'Budget'],
    '贵阳':    <String>['Adventure', 'Culture', 'Budget'],
    '拉萨':    <String>['Adventure', 'Culture', 'Budget'],
    '哈尔滨':  <String>['Culture', 'Adventure', 'Budget'],
    '海口':    <String>['Beach', 'Adventure', 'Budget'],
    '南宁':    <String>['Adventure', 'Culture', 'Budget'],
    '西宁':    <String>['Adventure', 'Culture', 'Budget'],
    '乌鲁木齐': <String>['Adventure', 'Culture', 'Budget'],
  };

  static const Map<String, String> _cityStay = <String, String>{
    '北京':    '¥400–800/晚',
    '上海':    '¥450–900/晚',
    '成都':    '¥200–500/晚',
    '西安':    '¥180–450/晚',
    '杭州':    '¥250–600/晚',
    '桂林':    '¥150–350/晚',
    '三亚':    '¥350–800/晚',
    '丽江':    '¥200–500/晚',
    '厦门':    '¥220–550/晚',
    '张家界':  '¥150–350/晚',
    '重庆':    '¥200–500/晚',
    '广州':    '¥300–700/晚',
    '深圳':    '¥350–800/晚',
    '苏州':    '¥250–600/晚',
    '南京':    '¥220–550/晚',
    '武汉':    '¥180–450/晚',
    '青岛':    '¥200–500/晚',
    '大连':    '¥180–450/晚',
    '昆明':    '¥150–400/晚',
    '贵阳':    '¥130–350/晚',
    '拉萨':    '¥200–600/晚',
    '哈尔滨':  '¥160–400/晚',
    '海口':    '¥200–500/晚',
    '南宁':    '¥150–380/晚',
    '西宁':    '¥130–350/晚',
    '乌鲁木齐': '¥150–400/晚',
  };

  static Future<List<Map<String, dynamic>>> fetchAllDestinations(
    String apiKey, {
    List<String>? cities,
    String keywords = '旅游景点',
    int countPerCity = 10,
    void Function(int completed, int total)? onProgress,
  }) async {
    final List<String> targetCities = cities ?? defaultCities;
    final List<Map<String, dynamic>> all = <Map<String, dynamic>>[];
    int completed = 0;

    for (int i = 0; i < targetCities.length; i++) {
      final String city = targetCities[i];
      try {
        final List<Map<String, dynamic>> pois = await _fetchCity(
          apiKey: apiKey,
          city: city,
          keywords: keywords,
          countPerCity: countPerCity,
          fallbackIndex: i,
        );
        all.addAll(pois);
      } catch (_) {}
      completed++;
      onProgress?.call(completed, targetCities.length);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    return all;
  }

  static Future<List<Map<String, dynamic>>> _fetchCity({
    required String apiKey,
    required String city,
    required String keywords,
    required int countPerCity,
    required int fallbackIndex,
  }) async {
    // Map keyword to the appropriate Amap type code
    final String typeCode = _keywordType[keywords] ?? '';

    final Map<String, String> queryParams = <String, String>{
      'key': apiKey,
      'keywords': keywords,
      'city': city,
      'extensions': 'all',
      'output': 'json',
      'offset': countPerCity.clamp(1, 25).toString(),
      'page': '1',
    };
    // Only add types filter when we have a known code (avoids over-restricting)
    if (typeCode.isNotEmpty) {
      queryParams['types'] = typeCode;
    }

    final Uri uri =
        Uri.parse(_baseUrl).replace(queryParameters: queryParams);

    final http.Response response =
        await http.get(uri).timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) return <Map<String, dynamic>>[];

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    if (body['status'] != '1') return <Map<String, dynamic>>[];

    final List<dynamic> pois =
        body['pois'] as List<dynamic>? ?? <dynamic>[];

    return pois
        .map((dynamic p) =>
            _parsePoi(p as Map<String, dynamic>, city, fallbackIndex, keywords))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static Map<String, dynamic>? _parsePoi(
    Map<String, dynamic> poi,
    String city,
    int fallbackIndex,
    String keywords,
  ) {
    final String name = poi['name'] as String? ?? '';
    if (name.isEmpty) return null;

    final String cityname = poi['cityname'] as String? ?? city;
    final String adname = poi['adname'] as String? ?? '';
    final String displayLocation =
        adname.isNotEmpty ? '$cityname · $adname' : cityname;

    // Parse coordinates — Amap format: "longitude,latitude"
    double? lat, lng;
    final String coordStr = poi['location'] as String? ?? '';
    if (coordStr.contains(',')) {
      final List<String> parts = coordStr.split(',');
      if (parts.length == 2) {
        lng = double.tryParse(parts[0].trim());
        lat = double.tryParse(parts[1].trim());
      }
    }

    // Rating: use Amap value when available, otherwise hash-based variation
    final String ratingStr = poi['rating'] as String? ?? '';
    final double rawRating = double.tryParse(ratingStr) ??
        (3.8 + (name.hashCode.abs() % 13) * 0.1);
    final double rating =
        double.parse(rawRating.clamp(3.5, 5.0).toStringAsFixed(1));

    final String costStr = poi['cost'] as String? ?? '';
    final double cost = double.tryParse(costStr) ?? 0;

    final List<dynamic> photos =
        poi['photos'] as List<dynamic>? ?? <dynamic>[];
    String imgUrl = '';
    if (photos.isNotEmpty) {
      imgUrl =
          (photos.first as Map<String, dynamic>)['url'] as String? ?? '';
    }
    if (imgUrl.startsWith('http://')) {
      imgUrl = imgUrl.replaceFirst('http://', 'https://');
    }

    // Assign tags based on keyword type, not just city
    List<String> tags;
    if (keywords == '酒店') {
      tags = <String>['Budget', 'Culture'];
    } else if (keywords == '美食餐厅') {
      tags = <String>['Food', 'Budget'];
    } else if (keywords == '购物中心') {
      tags = <String>['Shopping', 'Culture'];
    } else {
      tags = List<String>.from(
        _cityTags[city] ?? <String>['Culture'],
      );
    }
    if (cost > 0 && cost < 80 && !tags.contains('Budget')) {
      tags.add('Budget');
    }

    // Duration based on Amap typecode for scenic spots; keyword for others
    final String typecode = poi['typecode'] as String? ?? '';
    final String duration = _estimateDuration(typecode, tags, cost, keywords);

    // Budget: entry ticket price for this specific attraction
    final String budget = cost > 0 ? '¥$costStr/人' : '免费';

    // Stay: hotel price near this attraction (city-level fallback until AI enriches)
    final String stay = _cityStay[city] ?? '¥200–500/晚';

    // Details: attraction-specific description (city intro removed)
    final String address = poi['address'] as String? ?? '';
    final StringBuffer details = StringBuffer();
    details.write('$name位于$displayLocation');
    if (address.isNotEmpty) details.write('（$address）');
    details.write('。');
    if (cost > 0) details.write('门票约¥$costStr元/人。');

    final String fallbackImg = 'assets/${(fallbackIndex % 5) + 1}.jpeg';

    final Map<String, dynamic> result = <String, dynamic>{
      'name': name,
      'img': imgUrl.isNotEmpty ? imgUrl : fallbackImg,
      'price': stay,
      'budget': budget,
      'duration': duration,
      'rating': rating,
      'tags': tags,
      'location': displayLocation,
      'details': details.toString(),
    };

    if (lat != null && lng != null) {
      result['lat'] = lat;
      result['lng'] = lng;
    }

    return result;
  }

  static String _estimateDuration(
    String typecode,
    List<String> tags,
    double cost,
    String keywords,
  ) {
    // Duration = how long to spend at THIS specific place
    if (keywords == '酒店') return '1–7 晚';
    if (keywords == '美食餐厅') return '1–2 小时';
    if (keywords == '购物中心') return '2–4 小时';

    // Typecode-based estimates (more specific than tags)
    if (typecode.startsWith('110102')) return '半天–1 天'; // theme park
    if (typecode.startsWith('110200') || typecode.startsWith('110201') ||
        typecode.startsWith('110202')) return '1–3 小时'; // historical site
    if (typecode.startsWith('110103')) return '2–3 小时'; // zoo / botanical
    if (typecode.startsWith('110104')) return '1–2 小时'; // aquarium / museum
    if (typecode.startsWith('110100') || typecode.startsWith('110101')) {
      return cost > 100 ? '半天–1 天' : '2–4 小时'; // natural scenic area
    }

    // Generic cost heuristic — avoid using city-level tags for attraction duration
    if (cost > 300) return '1–2 天';
    if (cost > 100) return '半天–1 天';
    if (cost > 20) return '2–4 小时';
    return '1–3 小时'; // free / low cost (parks, squares, streets)
  }

}
