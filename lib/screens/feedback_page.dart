import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_travel/util/user_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key, this.initialPage = 0});

  final int initialPage;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  static const String _key = 'feedback_responses';
  static const String _seedVersionKey = 'feedback_seed_version';
  static const int _seedVersion = 3;
  static const String _developerPhone = '15959212273';

  int _page = 0;
  int _q1 = 0;
  int _q2 = 0;
  int _q3 = 0;
  int _q4 = 0;
  final Set<String> _q5 = <String>{};
  String _q6 = '';
  String _q7 = '';
  final TextEditingController _q8Ctrl = TextEditingController();

  List<Map<String, dynamic>> _responses = <Map<String, dynamic>>[];
  bool _submitted = false;
  bool _loading = true;
  bool _canViewInbox = false;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;
    _loadResponses();
  }

  @override
  void dispose() {
    _q8Ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadResponses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, String>? session = await UserSession.load();
    _canViewInbox = (session?['phone'] ?? '') == _developerPhone;
    if (widget.initialPage == 3 && !_canViewInbox) {
      _page = 2;
    }
    final int savedVersion = prefs.getInt(_seedVersionKey) ?? 0;
    if (savedVersion != _seedVersion) {
      _responses = _seedResponses();
      await prefs.setString(_key, jsonEncode(_responses));
      await prefs.setInt(_seedVersionKey, _seedVersion);
    } else {
      final String? raw = prefs.getString(_key);
      if (raw != null) {
        _responses = (jsonDecode(raw) as List<dynamic>)
            .map((dynamic item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _seedResponses() {
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'timestamp': '2026-06-08T09:12:00',
        'q1': 2,
        'q2': 3,
        'q3': 4,
        'q4': 2,
        'q5': <String>['地图', '行程'],
        'q6': '城市购物',
        'q7': '可能会',
        'q8': '创建行程的时候开始日期和结束日期点了很多次都没有反应，当时完全没法继续往下做。',
        'author': '匿名用户',
        'developerReply': '开发者回复：已经把系统日期弹窗改成应用内底部日历选择器，抽屉里点击无响应的问题已修复。',
        'status': 'resolved',
      },
      <String, dynamic>{
        'timestamp': '2026-06-08T09:46:00',
        'q1': 2,
        'q2': 3,
        'q3': 3,
        'q4': 1,
        'q5': <String>['地图'],
        'q6': '自然风光',
        'q7': '不会',
        'q8': '地图第一次打开特别慢，白屏了好几秒，我一开始以为是卡住了。',
        'author': '匿名用户',
        'developerReply': '开发者回复：地图页现在会先展示本地或缓存数据，再后台刷新高德结果，首屏等待已经压缩很多。',
        'status': 'resolved',
      },
      <String, dynamic>{
        'timestamp': '2026-06-08T10:08:00',
        'q1': 3,
        'q2': 4,
        'q3': 4,
        'q4': 3,
        'q5': <String>['反馈', '发现'],
        'q6': '文化历史',
        'q7': '会',
        'q8': '反馈提交完以后看不到别人提过什么问题，也不知道开发者有没有处理。',
        'author': '匿名用户',
        'developerReply': '开发者回复：已经新增反馈广场和开发者收件箱，现在可以直接看到公开反馈和对应处理结果。',
        'status': 'resolved',
      },
      <String, dynamic>{
        'timestamp': '2026-06-08T10:34:00',
        'q1': 3,
        'q2': 3,
        'q3': 4,
        'q4': 2,
        'q5': <String>['地图', '反馈'],
        'q6': '自然风光',
        'q7': '可能会',
        'q8': '地图上点一个位置以后，下面附近地点卡片有一次直接提示 bottom overflow，看着像是内容装不下。',
        'author': '匿名用户',
        'developerReply': '开发者回复：已经调整附近地点卡片高度和文字行数限制，并给内容留出更稳定的按钮区，溢出问题已处理。',
        'status': 'resolved',
      },
      <String, dynamic>{
        'timestamp': '2026-06-08T11:02:00',
        'q1': 4,
        'q2': 4,
        'q3': 2,
        'q4': 4,
        'q5': <String>['行程', '发现'],
        'q6': '美食探索',
        'q7': '可能会',
        'q8': '有些景点详情一开始内容比较少，尤其是地址和可玩点介绍，看着有点空。',
        'author': '匿名用户',
        'developerReply': '开发者回复：加入行程前现在会优先尝试补 AI 说明，详情页也增加了“AI 分析地址和可玩点”按钮。',
        'status': 'resolved',
      },
      <String, dynamic>{
        'timestamp': '2026-06-08T11:25:00',
        'q1': 3,
        'q2': 3,
        'q3': 2,
        'q4': 4,
        'q5': <String>['发现', '地图'],
        'q6': '城市购物',
        'q7': '可能会',
        'q8': 'AI 分析有时候会出现奇怪的乱码，像是编码没处理好，内容反而更难看。',
        'author': '匿名用户',
        'developerReply': '开发者回复：已经在 AI 服务层增加返回文本清洗和乱码过滤，异常内容会被丢弃而不是直接展示。',
        'status': 'resolved',
      },
      <String, dynamic>{
        'timestamp': '2026-06-08T11:47:00',
        'q1': 4,
        'q2': 4,
        'q3': 4,
        'q4': 3,
        'q5': <String>['喜欢', '发现'],
        'q6': '文化历史',
        'q7': '会',
        'q8': '喜欢页面当时没有刷新入口，我点完收藏再回来有时候看不到最新状态。',
        'author': '匿名用户',
        'developerReply': '开发者回复：喜欢页已经增加右上角刷新按钮和下拉刷新，收藏状态会更容易同步。',
        'status': 'resolved',
      },
      <String, dynamic>{
        'timestamp': '2026-06-08T12:18:00',
        'q1': 3,
        'q2': 2,
        'q3': 3,
        'q4': 4,
        'q5': <String>['发现', '行程'],
        'q6': '探险运动',
        'q7': '不会',
        'q8': '有些地方还是中英混着显示，比如按钮、标题、分类这些，整体风格不太统一。',
        'author': '匿名用户',
        'developerReply': '开发者回复：正在逐步把高频界面统一成中文，这一版已经优先覆盖首页、详情、地图、喜欢和行程主流程。',
        'status': 'reviewed',
      },
      <String, dynamic>{
        'timestamp': '2026-06-08T13:05:00',
        'q1': 4,
        'q2': 4,
        'q3': 3,
        'q4': 4,
        'q5': <String>['地图', '行程'],
        'q6': '海滩度假',
        'q7': '会',
        'q8': '详情页如果能直接跳到地图对应位置会更顺，我当时还得自己再去地图里找。',
        'author': '匿名用户',
        'developerReply': '开发者回复：详情页已经补了地图位置标签，点击后会直接打开地图并定位到对应地点。',
        'status': 'resolved',
      },
      <String, dynamic>{
        'timestamp': '2026-06-08T13:36:00',
        'q1': 3,
        'q2': 3,
        'q3': 4,
        'q4': 3,
        'q5': <String>['发现', '反馈'],
        'q6': '文化历史',
        'q7': '可能会',
        'q8': '待办事项之前找不到入口，后来才知道铃铛是空的，建议做成点开就能看到安排。',
        'author': '匿名用户',
        'developerReply': '开发者回复：首页铃铛已经接入待办事项面板，现在能直接看到已加入行程的待出行地点。',
        'status': 'resolved',
      },
      <String, dynamic>{
        'timestamp': '2026-06-08T14:02:00',
        'q1': 4,
        'q2': 5,
        'q3': 4,
        'q4': 4,
        'q5': <String>['行程', '地图', '喜欢'],
        'q6': '自然风光',
        'q7': '会',
        'q8': '整体已经挺顺了，尤其是地图和行程串起来以后更像真正能用的旅行规划工具。',
        'author': '匿名用户',
        'developerReply': '开发者回复：感谢认可，我们会继续把分类、地图交互和 AI 内容质量再往前打磨。',
        'status': 'reviewed',
      },
    ];
  }

  Future<void> _submit() async {
    if (_q1 == 0 ||
        _q2 == 0 ||
        _q3 == 0 ||
        _q4 == 0 ||
        _q5.isEmpty ||
        _q6.isEmpty ||
        _q7.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请完成所有必填问题（Q1–Q7）')),
      );
      return;
    }
    final Map<String, dynamic> response = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'q1': _q1,
      'q2': _q2,
      'q3': _q3,
      'q4': _q4,
      'q5': _q5.toList(),
      'q6': _q6,
      'q7': _q7,
      'q8': _q8Ctrl.text.trim(),
      'author': '匿名用户',
      'developerReply': _buildDeveloperReply(),
      'status': _issueLevel() ? 'pending' : 'reviewed',
    };
    _responses.add(response);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_responses));
    if (mounted) {
      setState(() {
        _submitted = true;
        _page = 2;
      });
    }
  }

  bool _issueLevel() {
    return _q1 <= 3 || _q4 <= 3 || _q8Ctrl.text.trim().isNotEmpty;
  }

  String _buildDeveloperReply() {
    if (_q1 <= 2 || _q4 <= 2) {
      return '开发者回复：这条问题已经进入待排查列表，我们会优先关注稳定性和地图体验。';
    }
    if (_q8Ctrl.text.trim().isNotEmpty) {
      return '开发者回复：感谢你的详细建议，我们已经收到并会在后续版本中跟进。';
    }
    return '开发者回复：感谢支持，我们会继续迭代功能体验。';
  }

  void _resetForm() {
    _q8Ctrl.clear();
    setState(() {
      _q1 = 0;
      _q2 = 0;
      _q3 = 0;
      _q4 = 0;
      _q5.clear();
      _q6 = '';
      _q7 = '';
      _submitted = false;
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('反馈中心'),
        actions: <Widget>[
          PopupMenuButton<int>(
            onSelected: (int value) => setState(() => _page = value),
            itemBuilder: (_) => <PopupMenuEntry<int>>[
              const PopupMenuItem<int>(value: 0, child: Text('填写反馈')),
              const PopupMenuItem<int>(value: 1, child: Text('查看统计')),
              const PopupMenuItem<int>(value: 2, child: Text('反馈广场')),
              if (_canViewInbox)
                const PopupMenuItem<int>(value: 3, child: Text('开发者收件箱')),
            ],
          ),
        ],
      ),
      body: switch (_page) {
        1 => _buildStats(),
        2 => _buildCommunity(),
        3 => _buildDeveloperInbox(),
        _ => _buildSurvey(),
      },
    );
  }

  Widget _buildSurvey() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Header(responseCount: _responses.length),
          const SizedBox(height: 24),
          _StarQuestion(number: 1, question: '你对应用的整体满意度如何？', value: _q1, onChanged: (int v) => setState(() => _q1 = v)),
          _StarQuestion(number: 2, question: '界面是否直观易用？', value: _q2, onChanged: (int v) => setState(() => _q2 = v)),
          _StarQuestion(number: 3, question: 'AI 个性化推荐是否有帮助？', value: _q3, onChanged: (int v) => setState(() => _q3 = v)),
          _StarQuestion(number: 4, question: '地图功能体验如何？', value: _q4, onChanged: (int v) => setState(() => _q4 = v)),
          _SectionTitle(number: 5, text: '你最常用的功能是？（可多选）'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <String>['发现', '地图', '行程', '反馈']
                .map((String opt) => FilterChip(
                      label: Text(opt),
                      selected: _q5.contains(opt),
                      onSelected: (bool v) => setState(() {
                        if (v) {
                          _q5.add(opt);
                        } else {
                          _q5.remove(opt);
                        }
                      }),
                      selectedColor: const Color(0xFF16324F).withOpacity(0.15),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          _SectionTitle(number: 6, text: '你是哪类旅行者？'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <String>['文化历史', '自然风光', '美食探索', '海滩度假', '城市购物', '探险运动']
                .map((String opt) => ChoiceChip(
                      label: Text(opt),
                      selected: _q6 == opt,
                      onSelected: (bool v) => setState(() => _q6 = v ? opt : ''),
                      selectedColor: const Color(0xFF16324F).withOpacity(0.15),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          _SectionTitle(number: 7, text: '是否会向朋友推荐此应用？'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <String>['会', '可能会', '不会']
                .map((String opt) => ChoiceChip(
                      label: Text(opt),
                      selected: _q7 == opt,
                      onSelected: (bool v) => setState(() => _q7 = v ? opt : ''),
                      selectedColor: const Color(0xFF16324F).withOpacity(0.15),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          _SectionTitle(number: 8, text: '有什么建议或意见？（选填）'),
          TextField(
            controller: _q8Ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '请输入你的建议…',
              filled: true,
              fillColor: const Color(0xFFF6F8FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitted ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16324F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _submitted ? '已提交，感谢反馈！' : '提交反馈',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final int total = _responses.length;
    if (total == 0) return const Center(child: Text('暂无反馈数据'));

    List<int> values(String key) {
      return _responses
          .map((Map<String, dynamic> r) => r[key] as int? ?? 0)
          .where((int v) => v > 0)
          .toList();
    }

    double avg(String key) => _mean(values(key));

    Map<String, int> count(String key) {
      final Map<String, int> map = <String, int>{};
      for (final Map<String, dynamic> r in _responses) {
        final dynamic val = r[key];
        if (val is List) {
          for (final dynamic v in val) {
            map[v.toString()] = (map[v.toString()] ?? 0) + 1;
          }
        } else if (val is String && val.isNotEmpty) {
          map[val] = (map[val] ?? 0) + 1;
        }
      }
      return map;
    }

    final List<int> satisfaction = values('q1');
    final List<int> mapScores = values('q4');
    final double issueRate = _responses.where((Map<String, dynamic> item) {
          final int q1 = item['q1'] as int? ?? 5;
          final int q4 = item['q4'] as int? ?? 5;
          final String q8 = item['q8'] as String? ?? '';
          return q1 <= 3 || q4 <= 3 || q8.isNotEmpty;
        }).length /
        total;
    final int promoters =
        _responses.where((Map<String, dynamic> item) => (item['q7'] as String? ?? '') == '会').length;
    final int detractors =
        _responses.where((Map<String, dynamic> item) => (item['q7'] as String? ?? '') == '不会').length;
    final double nps = ((promoters - detractors) / total) * 100;
    final Map<String, int> issueTopics = _topIssues();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SummaryCard(total: total),
          const SizedBox(height: 16),
          _StatsCard(
            title: '统计归纳',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _MetricChip(label: '满意度均值', value: avg('q1').toStringAsFixed(2)),
                _MetricChip(label: '满意度中位数', value: _median(satisfaction).toStringAsFixed(1)),
                _MetricChip(label: '地图波动', value: _stdDev(mapScores).toStringAsFixed(2)),
                _MetricChip(label: '问题反馈率', value: '${(issueRate * 100).toStringAsFixed(0)}%'),
                _MetricChip(label: '推荐净值', value: nps.toStringAsFixed(0)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StatsCard(
            title: '评分统计（均分 / 5）',
            child: Column(
              children: <Widget>[
                _RatingBar(label: '整体满意度', value: avg('q1')),
                _RatingBar(label: '界面易用性', value: avg('q2')),
                _RatingBar(label: 'AI推荐有用性', value: avg('q3')),
                _RatingBar(label: '地图功能', value: avg('q4')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _StatsCard(
            title: '高频问题主题',
            child: _DistBars(data: issueTopics, total: total),
          ),
          const SizedBox(height: 12),
          _StatsCard(title: '最常用功能', child: _DistBars(data: count('q5'), total: total)),
          const SizedBox(height: 12),
          _StatsCard(title: '旅行者类型', child: _DistBars(data: count('q6'), total: total)),
          const SizedBox(height: 12),
          _StatsCard(title: '推荐意愿', child: _DistBars(data: count('q7'), total: total)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resetForm,
              icon: const Icon(Icons.edit_note),
              label: const Text('再次填写问卷'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunity() {
    final List<Map<String, dynamic>> sorted = List<Map<String, dynamic>>.from(_responses)
      ..sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
          (b['timestamp'] as String? ?? '').compareTo(a['timestamp'] as String? ?? ''));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, int index) => _FeedbackFeedCard(response: sorted[index]),
    );
  }

  Widget _buildDeveloperInbox() {
    if (!_canViewInbox) {
      return const Center(
        child: Text('当前账号无权查看开发者收件箱'),
      );
    }

    final List<Map<String, dynamic>> issues = _responses.where((Map<String, dynamic> item) {
      final int q1 = item['q1'] as int? ?? 5;
      final int q4 = item['q4'] as int? ?? 5;
      final String q8 = item['q8'] as String? ?? '';
      return q1 <= 3 || q4 <= 3 || q8.isNotEmpty;
    }).toList()
      ..sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
          (b['timestamp'] as String? ?? '').compareTo(a['timestamp'] as String? ?? ''));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF16324F),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                '开发者收件箱',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '优先展示有问题的反馈。已经预置了几条你这次遇到的问题和解决方式作为模拟数据。',
                style: TextStyle(color: Colors.white.withOpacity(0.76)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...issues.map((Map<String, dynamic> item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DeveloperIssueCard(response: item),
            )),
      ],
    );
  }

  double _mean(List<int> values) {
    if (values.isEmpty) return 0;
    return values.reduce((int a, int b) => a + b) / values.length;
  }

  double _median(List<int> values) {
    if (values.isEmpty) return 0;
    final List<int> sorted = List<int>.from(values)..sort();
    final int middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle].toDouble();
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  double _stdDev(List<int> values) {
    if (values.length < 2) return 0;
    final double mean = _mean(values);
    final double variance = values
            .map((int value) => (value - mean) * (value - mean))
            .reduce((double a, double b) => a + b) /
        values.length;
    return math.sqrt(variance);
  }

  Map<String, int> _topIssues() {
    final Map<String, int> topics = <String, int>{
      '日期选择': 0,
      '地图性能': 0,
      '地图布局': 0,
      'AI内容质量': 0,
      '中文化与一致性': 0,
      '行程联动': 0,
    };
    for (final Map<String, dynamic> item in _responses) {
      final String text = (item['q8'] as String? ?? '').toLowerCase();
      if (text.contains('日期') || text.contains('开始') || text.contains('结束')) {
        topics['日期选择'] = (topics['日期选择'] ?? 0) + 1;
      }
      if (text.contains('慢') || text.contains('白屏') || text.contains('加载')) {
        topics['地图性能'] = (topics['地图性能'] ?? 0) + 1;
      }
      if (text.contains('overflow') || text.contains('装不下')) {
        topics['地图布局'] = (topics['地图布局'] ?? 0) + 1;
      }
      if (text.contains('ai') || text.contains('乱码') || text.contains('介绍')) {
        topics['AI内容质量'] = (topics['AI内容质量'] ?? 0) + 1;
      }
      if (text.contains('中英') || text.contains('统一')) {
        topics['中文化与一致性'] = (topics['中文化与一致性'] ?? 0) + 1;
      }
      if (text.contains('地图') || text.contains('行程') || text.contains('跳到')) {
        topics['行程联动'] = (topics['行程联动'] ?? 0) + 1;
      }
    }
    topics.removeWhere((String _, int value) => value == 0);
    return topics;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.responseCount});

  final int responseCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16324F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '用户体验调查问卷',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '已收集 $responseCount 份反馈',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF16324F),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$number',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _StarQuestion extends StatelessWidget {
  const _StarQuestion({
    required this.number,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final int number;
  final String question;
  final int value;
  final ValueChanged<int> onChanged;

  static const List<String> _labels = <String>[
    '',
    '非常不满意',
    '不满意',
    '一般',
    '满意',
    '非常满意',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionTitle(number: number, text: question),
          Row(
            children: List<Widget>.generate(5, (int i) {
              final int star = i + 1;
              return GestureDetector(
                onTap: () => onChanged(star),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: star <= value ? Colors.amber : Colors.blueGrey[300],
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          if (value > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(_labels[value], style: TextStyle(color: Colors.blueGrey[500], fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16324F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.people_outline, color: Colors.white, size: 36),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$total 份反馈',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
              Text('数据分析报告', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.blueGrey[600]),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF16324F),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          SizedBox(width: 88, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 5,
                minHeight: 10,
                backgroundColor: Colors.blueGrey[100],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16324F)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value > 0 ? value.toStringAsFixed(1) : '-',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _DistBars extends StatelessWidget {
  const _DistBars({required this.data, required this.total});

  final Map<String, int> data;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return Text('暂无数据', style: TextStyle(color: Colors.blueGrey[400]));
    final List<MapEntry<String, int>> sorted = data.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) => b.value.compareTo(a.value));
    return Column(
      children: sorted.map((MapEntry<String, int> e) {
        final double pct = total > 0 ? e.value / total : 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 80,
                child: Text(e.key, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: Colors.blueGrey[100],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16324F)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text('${(pct * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _FeedbackFeedCard extends StatelessWidget {
  const _FeedbackFeedCard({required this.response});

  final Map<String, dynamic> response;

  String _timeLabel() {
    final String raw = response['timestamp'] as String? ?? '';
    if (raw.isEmpty) return '刚刚';
    try {
      final DateTime time = DateTime.parse(raw).toLocal();
      return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String author = response['author'] as String? ?? '匿名用户';
    final String suggestion = response['q8'] as String? ?? '';
    final String reply = response['developerReply'] as String? ?? '';
    final List<dynamic> used = response['q5'] as List<dynamic>? ?? <dynamic>[];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.blueGrey.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: const Color(0xFF16324F).withOpacity(0.12),
                foregroundColor: const Color(0xFF16324F),
                child: Text(author.substring(0, 1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(author, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(_timeLabel(), style: TextStyle(fontSize: 12, color: Colors.blueGrey[500])),
                  ],
                ),
              ),
            ],
          ),
          if (used.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: used.map((dynamic item) => Chip(label: Text('$item'))).toList(),
            ),
          ],
          if (suggestion.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(suggestion, style: const TextStyle(fontSize: 14, height: 1.45)),
          ],
          if (reply.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF7F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(reply, style: const TextStyle(color: Color(0xFF204B43), height: 1.4)),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeveloperIssueCard extends StatelessWidget {
  const _DeveloperIssueCard({required this.response});

  final Map<String, dynamic> response;

  @override
  Widget build(BuildContext context) {
    final String status = response['status'] as String? ?? 'pending';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.blueGrey.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  response['author'] as String? ?? '匿名用户',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF16324F)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: status == 'resolved' ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status == 'resolved' ? '已解决' : '待跟进',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: status == 'resolved' ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            response['q8'] as String? ?? '无附加说明',
            style: const TextStyle(fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              response['developerReply'] as String? ?? '',
              style: TextStyle(color: Colors.blueGrey[700], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
