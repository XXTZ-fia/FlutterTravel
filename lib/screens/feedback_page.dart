import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  static const String _key = 'feedback_responses';

  // 答题状态
  int _q1 = 0; // 整体满意度
  int _q2 = 0; // 界面易用性
  int _q3 = 0; // AI 推荐有用性
  int _q4 = 0; // 地图功能
  final Set<String> _q5 = <String>{}; // 最常用功能（多选）
  String _q6 = ''; // 旅行者类型
  String _q7 = ''; // 是否推荐
  final TextEditingController _q8Ctrl = TextEditingController();

  List<Map<String, dynamic>> _responses = <Map<String, dynamic>>[];
  bool _showStats = false;
  bool _submitted = false;
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadResponses(); }

  @override
  void dispose() { _q8Ctrl.dispose(); super.dispose(); }

  Future<void> _loadResponses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw != null) {
      _responses = (jsonDecode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (_q1 == 0 || _q2 == 0 || _q3 == 0 || _q4 == 0 ||
        _q5.isEmpty || _q6.isEmpty || _q7.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请完成所有必填问题（Q1–Q7）')));
      return;
    }
    final Map<String, dynamic> response = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'q1': _q1, 'q2': _q2, 'q3': _q3, 'q4': _q4,
      'q5': _q5.toList(),
      'q6': _q6, 'q7': _q7,
      'q8': _q8Ctrl.text.trim(),
    };
    _responses.add(response);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_responses));
    if (mounted) setState(() { _submitted = true; _showStats = true; });
  }

  void _resetForm() {
    _q8Ctrl.clear();
    setState(() {
      _q1 = 0; _q2 = 0; _q3 = 0; _q4 = 0;
      _q5.clear(); _q6 = ''; _q7 = '';
      _submitted = false; _showStats = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户反馈'),
        actions: <Widget>[
          if (_responses.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _showStats = !_showStats),
              child: Text(_showStats ? '填写问卷' : '查看统计',
                  style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _showStats ? _buildStats() : _buildSurvey(),
    );
  }

  // ── 问卷 ──────────────────────────────────────────────────────────────────

  Widget _buildSurvey() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Header(responseCount: _responses.length),
          const SizedBox(height: 24),
          _StarQuestion(
              number: 1, question: '你对应用的整体满意度如何？',
              value: _q1,
              onChanged: (int v) => setState(() => _q1 = v)),
          _StarQuestion(
              number: 2, question: '界面是否直观易用？',
              value: _q2,
              onChanged: (int v) => setState(() => _q2 = v)),
          _StarQuestion(
              number: 3, question: 'AI 个性化推荐是否有帮助？',
              value: _q3,
              onChanged: (int v) => setState(() => _q3 = v)),
          _StarQuestion(
              number: 4, question: '地图功能体验如何？',
              value: _q4,
              onChanged: (int v) => setState(() => _q4 = v)),
          _SectionTitle(number: 5, text: '你最常用的功能是？（可多选）'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children:
                <String>['Discover 发现', 'Map 地图', 'Itinerary 行程', 'Feedback 反馈']
                    .map((String opt) => FilterChip(
                          label: Text(opt),
                          selected: _q5.contains(opt),
                          onSelected: (bool v) => setState(() {
                            if (v) _q5.add(opt); else _q5.remove(opt);
                          }),
                          selectedColor:
                              const Color(0xFF16324F).withOpacity(0.15),
                          checkmarkColor: const Color(0xFF16324F),
                        ))
                    .toList(),
          ),
          const SizedBox(height: 20),
          _SectionTitle(number: 6, text: '你是哪类旅行者？'),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: <String>[
              '文化历史', '自然风光', '美食探索', '海滩度假', '城市购物', '探险运动'
            ]
                .map((String opt) => ChoiceChip(
                      label: Text(opt),
                      selected: _q6 == opt,
                      onSelected: (bool v) =>
                          setState(() => _q6 = v ? opt : ''),
                      selectedColor:
                          const Color(0xFF16324F).withOpacity(0.15),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          _SectionTitle(number: 7, text: '是否会向朋友推荐此应用？'),
          Row(
            children: <String>['会', '可能会', '不会']
                .map((String opt) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(opt),
                        selected: _q7 == opt,
                        onSelected: (bool v) =>
                            setState(() => _q7 = v ? opt : ''),
                        selectedColor:
                            const Color(0xFF16324F).withOpacity(0.15),
                      ),
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
                  borderSide: BorderSide.none),
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
                disabledBackgroundColor: Colors.blueGrey[200],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_submitted ? '已提交，感谢反馈！' : '提交反馈',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 统计 ──────────────────────────────────────────────────────────────────

  Widget _buildStats() {
    final int total = _responses.length;
    if (total == 0) {
      return const Center(child: Text('暂无反馈数据'));
    }

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
            child: Column(children: <Widget>[
              _RatingBar(label: '整体满意度', value: avg('q1')),
              _RatingBar(label: '界面易用性', value: avg('q2')),
              _RatingBar(label: 'AI推荐有用性', value: avg('q3')),
              _RatingBar(label: '地图功能', value: avg('q4')),
            ]),
          ),
          const SizedBox(height: 12),
          _StatsCard(
            title: '最常用功能',
            child: _DistBars(data: count('q5'), total: total),
          ),
          const SizedBox(height: 12),
          _StatsCard(
            title: '旅行者类型',
            child: _DistBars(data: count('q6'), total: total),
          ),
          const SizedBox(height: 12),
          _StatsCard(
            title: '推荐意愿',
            child: _DistBars(data: count('q7'), total: total),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _resetForm,
              icon: const Icon(Icons.edit_note),
              label: const Text('再次填写问卷'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 小组件 ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.responseCount});
  final int responseCount;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF16324F),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          const Text('用户体验调查问卷',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('已收集 $responseCount 份反馈',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 13)),
          const SizedBox(height: 8),
          Text('本问卷结果仅供课程项目分析，匿名收集。',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 12)),
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Container(
            width: 22, height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: const Color(0xFF16324F),
                borderRadius: BorderRadius.circular(6)),
            child: Text('$number',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ]),
      );
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
    '', '非常不满意', '不满意', '一般', '满意', '非常满意'
  ];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          _SectionTitle(number: number, text: question),
          Row(
            children: List<Widget>.generate(5, (int i) {
              final int star = i + 1;
              return GestureDetector(
                onTap: () => onChanged(star),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    star <= value
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
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
              child: Text(_labels[value],
                  style: TextStyle(
                      color: Colors.blueGrey[500], fontSize: 12)),
            ),
        ]),
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF16324F),
            borderRadius: BorderRadius.circular(16)),
        child: Row(children: <Widget>[
          const Icon(Icons.people_outline, color: Colors.white, size: 36),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Text('$total 份反馈',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            Text('数据分析报告',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 13)),
          ]),
        ]),
      );
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: Colors.blueGrey.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 14),
          child,
        ]),
      );
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: <Widget>[
          SizedBox(
              width: 88,
              child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 5,
                minHeight: 10,
                backgroundColor: Colors.blueGrey[100],
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF16324F)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(value > 0 ? value.toStringAsFixed(1) : '-',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13)),
          const Text(' / 5',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      );
}

class _DistBars extends StatelessWidget {
  const _DistBars({required this.data, required this.total});
  final Map<String, int> data;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return Text('暂无数据', style: TextStyle(color: Colors.blueGrey[400]));
    final List<MapEntry<String, int>> sorted = data.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
          b.value.compareTo(a.value));
    return Column(
      children: sorted.map((MapEntry<String, int> e) {
        final double pct = total > 0 ? e.value / total : 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: <Widget>[
            SizedBox(
              width: 80,
              child: Text(e.key,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 10,
                  backgroundColor: Colors.blueGrey[100],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF16324F)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              child: Text('${(pct * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
        );
      }).toList(),
    );
  }
}
