class MultilingualSearch {
  static bool matchesPlace(Map<String, dynamic> place, String query) {
    final String normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final String searchableText = _normalize(<String>[
      place['name'] as String? ?? '',
      place['location'] as String? ?? '',
      place['details'] as String? ?? '',
      _joinStrings(place['tags']),
    ].join(' '));

    if (searchableText.contains(normalizedQuery)) {
      return true;
    }

    final List<String> parts = _meaningfulParts(query);
    if (parts.isEmpty) {
      return searchableText.contains(normalizedQuery.replaceAll(' ', ''));
    }

    return parts.every((String part) => _matchesPart(searchableText, part));
  }

  static bool _matchesPart(String searchableText, String part) {
    final Set<String> aliases = _expandAliases(part);
    return aliases.any((String alias) => searchableText.contains(alias));
  }

  static Set<String> _expandAliases(String term) {
    final String normalized = _normalize(term);
    final String compact = normalized.replaceAll(' ', '');
    final Set<String> aliases = <String>{
      normalized,
      compact,
    };

    for (final String token in normalized.split(' ')) {
      if (token.isNotEmpty) {
        aliases.add(token);
      }
    }

    final List<String>? mapped = _keywordAliases[compact] ?? _keywordAliases[normalized];
    if (mapped != null) {
      for (final String value in mapped) {
        final String alias = _normalize(value);
        if (alias.isNotEmpty) {
          aliases.add(alias);
        }
      }
    }

    return aliases.where((String value) => value.isNotEmpty).toSet();
  }

  static List<String> _meaningfulParts(String query) {
    return query
        .toLowerCase()
        .split(_separatorPattern)
        .map((String part) => part.trim())
        .where((String part) => part.isNotEmpty)
        .where((String part) => !_stopWords.contains(part))
        .toList();
  }

  static String _joinStrings(dynamic value) {
    if (value is Iterable) {
      return value.map((dynamic item) => item.toString()).join(' ');
    }
    return value?.toString() ?? '';
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(_separatorPattern, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const Set<String> _stopWords = <String>{
    'a',
    'an',
    'and',
    'at',
    'be',
    'for',
    'from',
    'in',
    'into',
    'of',
    'on',
    'or',
    'the',
    'to',
    'with',
    'by',
    'near',
    'around',
    'about',
    'my',
    'me',
    'is',
    'are',
    'do',
    'go',
    'de',
    'la',
    'el',
    '的',
    '在',
    '和',
    '到',
    '去',
    '与',
    '于',
  };

  static final RegExp _separatorPattern = RegExp(r'[\s,，。.!?;；、/\\|_\-]+');

  static const Map<String, List<String>> _keywordAliases = <String, List<String>>{
    'beach': <String>['海滩', '沙滩', '海滨', '海岸', '滨海'],
    'beaches': <String>['海滩', '沙滩', '海滨', '海岸', '滨海'],
    'ocean': <String>['海洋', '海边', '海岸'],
    'sea': <String>['大海', '海边', '海岸'],
    'island': <String>['海岛', '岛屿', '岛'],
    'mountain': <String>['山', '山峰', '登山'],
    'snow': <String>['雪山', '冰川', '雪景'],
    'lake': <String>['湖', '湖泊', '湖边'],
    'river': <String>['河', '江', '河畔'],
    'park': <String>['公园', '景区', '园区'],
    'museum': <String>['博物馆', '展馆', '美术馆'],
    'temple': <String>['寺庙', '神社', '古刹'],
    'palace': <String>['宫殿', '皇宫', '王宫'],
    'castle': <String>['城堡', '古堡'],
    'oldtown': <String>['古城', '老城', '古镇'],
    'historic': <String>['历史', '人文', '古迹'],
    'culture': <String>['历史人文', '文化', '人文', '古迹'],
    'food': <String>['美食打卡', '美食', '料理', '小吃', '餐饮'],
    'restaurant': <String>['餐厅', '饭店', '美食'],
    'cafe': <String>['咖啡馆', '咖啡店', '茶馆'],
    'shopping': <String>['城市漫游', '购物', '商场', '逛街'],
    'mall': <String>['商场', '购物中心', '购物'],
    'city': <String>['城市漫游', '城市', '都市'],
    'nature': <String>['自然风光', '自然', '风景', '山水'],
    'adventure': <String>['探险', '冒险', '户外', '运动'],
    'family': <String>['亲子乐园', '亲子', '家庭'],
    'budget': <String>['轻松省钱', '便宜', '平价', '经济'],
    'cheap': <String>['便宜', '平价', '经济'],
    'luxury': <String>['奢华', '高端', '豪华'],
    'hotel': <String>['酒店', '住宿', '民宿'],
    'resort': <String>['度假村', '酒店', '民宿'],
    'travel': <String>['旅行', '旅游', '出行'],
    'itinerary': <String>['行程', '路线', '计划'],
    'map': <String>['地图', '导航', '位置'],
    'review': <String>['评价', '评论', '反馈'],
    'view': <String>['观景', '景观', '风景'],
    'art': <String>['艺术', '美术馆', '展览'],
    'nightlife': <String>['夜生活', '夜景', '酒吧'],
    'shoppingmall': <String>['商场', '购物中心', '购物'],
    'newyork': <String>['纽约', '曼哈顿', 'nyc'],
    'london': <String>['伦敦'],
    'paris': <String>['巴黎'],
    'rome': <String>['罗马'],
    'madrid': <String>['马德里'],
    'barcelona': <String>['巴塞罗那'],
    'tokyo': <String>['东京'],
    'kyoto': <String>['京都'],
    'osaka': <String>['大阪'],
    'seoul': <String>['首尔'],
    'beijing': <String>['北京'],
    'shanghai': <String>['上海'],
    'guangzhou': <String>['广州'],
    'shenzhen': <String>['深圳'],
    'hangzhou': <String>['杭州'],
    'chengdu': <String>['成都'],
    'chongqing': <String>['重庆'],
    'nanjing': <String>['南京'],
    'wuhan': <String>['武汉'],
    'xian': <String>['西安'],
    "xi'an": <String>['西安'],
    'suzhou': <String>['苏州'],
    'xiamen': <String>['厦门'],
    'qingdao': <String>['青岛'],
    'kunming': <String>['昆明'],
    'guilin': <String>['桂林'],
    'sanya': <String>['三亚'],
    'hongkong': <String>['香港'],
    'hong kong': <String>['香港'],
    'macau': <String>['澳门'],
    'macao': <String>['澳门'],
    'taipei': <String>['台北'],
    'lisbon': <String>['里斯本'],
    'bali': <String>['巴厘岛', '巴厘'],
    'maldives': <String>['马尔代夫'],
    'sydney': <String>['悉尼'],
    'reykjavik': <String>['雷克雅未克'],
  };
}