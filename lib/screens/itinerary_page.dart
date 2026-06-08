import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/itinerary_detail_page.dart';
import 'package:flutter_travel/services/itinerary_service.dart';
import 'package:flutter_travel/widgets/app_date_picker_sheet.dart';

class ItineraryPage extends StatefulWidget {
  const ItineraryPage({super.key});

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  List<Map<String, dynamic>> _itineraries = <Map<String, dynamic>>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Map<String, dynamic>> list = await ItineraryService.getAll();
    if (!mounted) return;
    setState(() {
      _itineraries = list;
      _loading = false;
    });
  }

  Future<void> _showCreateDialog() async {
    final Map<String, String>? result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateItinerarySheet(),
    );
    if (result == null) return;
    await ItineraryService.create(
      name: result['name']!,
      startDate: result['startDate'],
      endDate: result['endDate'],
    );
    _load();
  }

  Future<void> _delete(String id, String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('删除行程'),
        content: Text('确定删除「$name」吗？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ItineraryService.delete(id);
      _load();
    }
  }

  int get _totalPlaces => _itineraries.fold<int>(
        0,
        (int sum, Map<String, dynamic> itinerary) =>
            sum + (itinerary['places'] as List<dynamic>).length,
      );

  int get _activeDays {
    int total = 0;
    for (final Map<String, dynamic> itinerary in _itineraries) {
      final String? start = itinerary['startDate'] as String?;
      final String? end = itinerary['endDate'] as String?;
      if (start == null || end == null) continue;
      try {
        total += DateTime.parse(end).difference(DateTime.parse(start)).inDays + 1;
      } catch (_) {}
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('新建行程'),
        backgroundColor: const Color(0xFF16324F),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(child: _buildHero()),
                  if (_itineraries.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmpty(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int i) {
                            final Map<String, dynamic> itinerary = _itineraries[i];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: i == _itineraries.length - 1 ? 0 : 16,
                              ),
                              child: _ScheduleCard(
                                itinerary: itinerary,
                                onDelete: () => _delete(
                                  itinerary['id'] as String,
                                  itinerary['name'] as String,
                                ),
                                onTap: () async {
                                  await Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          ItineraryDetailPage(itinerary: itinerary),
                                    ),
                                  );
                                  _load();
                                },
                              ),
                            );
                          },
                          childCount: _itineraries.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF16324F), Color(0xFF2C6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x3316324F),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.event_note, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '行程',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '把想去的地点整理成一条顺手的旅行节奏。',
                      style: TextStyle(color: Color(0xDDEAF3FF), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              Expanded(
                child: _HeroMetric(
                  label: '行程数',
                  value: '${_itineraries.length}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: 'Places',
                  value: '$_totalPlaces',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: 'Days',
                  value: '$_activeDays',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 24,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: const Icon(
              Icons.route_outlined,
              size: 50,
              color: Color(0xFF16324F),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            '还没有行程',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF16324F),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '可以先新建一个行程，或者在地图页点选地点后直接把附近景点加入进来。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blueGrey[500],
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xDDEAF3FF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.itinerary,
    required this.onDelete,
    required this.onTap,
  });

  final Map<String, dynamic> itinerary;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  String _dateRange() {
    final String? start = itinerary['startDate'] as String?;
    final String? end = itinerary['endDate'] as String?;
    if (start != null && end != null) return '$start - $end';
    if (start != null) return '$start 出发';
    return '日期待定';
  }

  int _days() {
    final String? start = itinerary['startDate'] as String?;
    final String? end = itinerary['endDate'] as String?;
    if (start == null || end == null) return 0;
    try {
      return DateTime.parse(end).difference(DateTime.parse(start)).inDays + 1;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> places = itinerary['places'] as List<dynamic>;
    final int days = _days();
    final Map<String, dynamic>? firstPlace =
        places.isNotEmpty ? places.first as Map<String, dynamic> : null;
    final int filledDays = places
        .map((dynamic place) {
          final Map<String, dynamic> item = place as Map<String, dynamic>;
          return item['visitDate'] as String? ?? '${item['day'] ?? 1}';
        })
        .toSet()
        .length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0F16324F),
              blurRadius: 24,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF2F8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: Color(0xFF16324F),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        itinerary['name'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF16324F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateRange(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blueGrey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _ChipTag('${places.length} 个地点'),
                _ChipTag(days > 0 ? '$days 天' : '未设日期'),
                _ChipTag('$filledDays 个出行日'),
              ],
            ),
            if (firstPlace != null) ...<Widget>[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.pin_drop_outlined, color: Color(0xFF2C6E63)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            '下一站灵感',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C6E63),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            firstPlace['name'] as String? ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16324F),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            firstPlace['location'] as String? ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipTag extends StatelessWidget {
  const _ChipTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF2F8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF16324F),
        ),
      ),
    );
  }
}

class _CreateItinerarySheet extends StatefulWidget {
  const _CreateItinerarySheet();

  @override
  State<_CreateItinerarySheet> createState() => _CreateItinerarySheetState();
}

class _CreateItinerarySheetState extends State<_CreateItinerarySheet> {
  final TextEditingController _nameCtrl = TextEditingController();
  DateTime? _start;
  DateTime? _end;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '选择日期';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pick({required bool isStart}) async {
    final DateTime? picked = await showAppDatePickerSheet(
      context,
      title: isStart ? '选择开始日期' : '选择结束日期',
      initialDate: isStart
          ? (_start ?? DateTime.now())
          : (_end ?? _start?.add(const Duration(days: 1)) ?? DateTime.now()),
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) {
          _end = null;
        }
      } else {
        _end = picked;
      }
    });
  }

  void _submit() {
    final String name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入行程名称')),
      );
      return;
    }
    if (_start != null && _end != null && _end!.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('结束日期不能早于开始日期')),
      );
      return;
    }
    Navigator.pop(context, <String, String>{
      'name': name,
      if (_start != null) 'startDate': _fmt(_start),
      if (_end != null) 'endDate': _fmt(_end),
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[200],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '创建行程',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '先定下旅行时间，再慢慢把地点放进来。',
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4F8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _nameCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: '行程名称',
                        hintText: '例如：厦门海边两日游',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _DateBtn(
                            label: '开始日期',
                            value: _fmt(_start),
                            onTap: () => _pick(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateBtn(
                            label: '结束日期',
                            value: _fmt(_end),
                            onTap: () => _pick(isStart: false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16324F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('创建行程'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBtn extends StatelessWidget {
  const _DateBtn({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueGrey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.blueGrey[500]),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
