import 'dart:convert';

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
    final String? raw = prefs.getString(_key);
    if (raw != null) {
      _responses = (jsonDecode(raw) as List<dynamic>)
          .map((dynamic item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    if (_responses.isEmpty) {
      _responses = _seedResponses();
      await prefs.setString(_key, jsonEncode(_responses));
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _seedResponses() {
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'timestamp': '2026-06-08T09:20:00',
        'q1': 2,
        'q2': 3,
        'q3': 4,
        'q4': 2,
        'q5': <String>['Map 地图', 'Itinerary 行程'],
        'q6': '城市购物',
        'q7': '可能会',
        'q8': '创建行程时点击开始日期和结束日期没有反应，没法选时间。',
        'author': '手机号用户 138****1024',
        'developerReply': '开发者回复：已改为应用内底部日历选择器，解决抽屉里日期弹窗点了无反应的问题。',
        'status': 'resolved',
      },
      <String, dynamic>{
        'timestamp': '2026-06-08T10:15:00',
        'q1': 2,
        'q2': 3,
        'q3': 3,
        'q4': 1,
        'q5': <String>['Map 地图'],
        'q6': '自然风光',
        'q7': '不会',
        'q8': 'Map 首次打开很慢，等很久才看到内容。',
        'author': '谷歌用户',
        'developerReply': '开发者回复：已改成地图页先展示本地/缓存数据，再后台刷新高德数据，首屏速度会明显更快。',
        'status': 'resolved',
      },
      <String, dynamic>{
        'timestamp': '2026-06-08T11:00:00',
        'q1': 3,
        'q2': 4,
        'q3': 4,
        'q4': 3,
        'q5': <String>['反馈', '发现'],
        'q6': '文化历史',
        'q7': '会',
        'q8': '提交反馈后看不到其他用户遇到的问题，也看不到开发者回复。',
        'author': '手机号用户 156****6678',
        'developerReply': '开发者回复：已新增反馈广场和 Developer Inbox，公开反馈与处理结果现在都能看到。',
        'status': 'resolved',
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
    final Map<String, String>? session = await UserSession.load();
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
      'author': _maskUser(session),
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

  String _maskUser(Map<String, String>? session) {
    if (session == null) return '匿名用户';
    final String phone = session['phone'] ?? '';
    final String provider = session['provider'] ?? '游客';
    if (phone.length < 7) return '$provider 用户';
    return '$provider ${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
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
        title: const Text('Feedback'),
        actions: <Widget>[
          PopupMenuButton<int>(
            onSelected: (int value) => setState(() => _page = value),
            itemBuilder: (_) => const <PopupMenuEntry<int>>[
              PopupMenuItem<int>(value: 0, child: Text('填写反馈')),
              PopupMenuItem<int>(value: 1, child: Text('查看统计')),
              PopupMenuItem<int>(value: 2, child: Text('反馈广场')),
              PopupMenuItem<int>(value: 3, child: Text('开发者收件箱')),
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

    double avg(String key) {
      final List<int> vals = _responses
          .map((Map<String, dynamic> r) => r[key] as int? ?? 0)
          .where((int v) => v > 0)
          .toList();
      if (vals.isEmpty) return 0;
      return vals.reduce((int a, int b) => a + b) / vals.length;
    }

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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SummaryCard(total: total),
          const SizedBox(height: 16),
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
