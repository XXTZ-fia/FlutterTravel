import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AmapFetchConfig {
  const AmapFetchConfig({
    required this.cities,
    required this.keywords,
    required this.countPerCity,
    required this.useAiDescriptions,
  });

  final List<String> cities;
  final String keywords;
  final int countPerCity;
  final bool useAiDescriptions;

  static const String _key = 'amap_fetch_config';

  static const List<String> availableCities = <String>[
    '北京', '上海', '成都', '西安', '杭州', '桂林', '三亚', '丽江', '厦门', '张家界',
    '重庆', '广州', '深圳', '苏州', '南京', '武汉', '青岛', '大连', '昆明', '贵阳',
    '拉萨', '哈尔滨', '海口', '南宁', '西宁', '乌鲁木齐',
  ];

  static const List<String> keywordPresets = <String>[
    '旅游景点', '酒店', '美食餐厅', '购物中心', '主题公园', '自然风景区', '历史古迹',
  ];

  static const AmapFetchConfig defaults = AmapFetchConfig(
    cities: <String>[
      '北京', '上海', '成都', '西安', '杭州',
      '桂林', '三亚', '丽江', '厦门', '张家界',
    ],
    keywords: '旅游景点',
    countPerCity: 10,
    useAiDescriptions: false,
  );

  static Future<AmapFetchConfig> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null) return defaults;
    try {
      final Map<String, dynamic> map =
          jsonDecode(raw) as Map<String, dynamic>;
      return AmapFetchConfig(
        cities: List<String>.from(map['cities'] as List),
        keywords: map['keywords'] as String? ?? defaults.keywords,
        countPerCity: map['countPerCity'] as int? ?? defaults.countPerCity,
        useAiDescriptions:
            map['useAiDescriptions'] as bool? ?? false,
      );
    } catch (_) {
      return defaults;
    }
  }

  static Future<void> save(AmapFetchConfig config) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(<String, dynamic>{
        'cities': config.cities,
        'keywords': config.keywords,
        'countPerCity': config.countPerCity,
        'useAiDescriptions': config.useAiDescriptions,
      }),
    );
  }

  AmapFetchConfig copyWith({
    List<String>? cities,
    String? keywords,
    int? countPerCity,
    bool? useAiDescriptions,
  }) {
    return AmapFetchConfig(
      cities: cities ?? this.cities,
      keywords: keywords ?? this.keywords,
      countPerCity: countPerCity ?? this.countPerCity,
      useAiDescriptions: useAiDescriptions ?? this.useAiDescriptions,
    );
  }
}
