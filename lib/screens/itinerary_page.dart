import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/itinerary_detail_page.dart';
import 'package:flutter_travel/services/itinerary_service.dart';

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
    if (mounted) setState(() { _itineraries = list; _loading = false; });
  }

  Future<void> _showCreateDialog() async {
    final Map<String, String>? result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _CreateItineraryDialog(),
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
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) { await ItineraryService.delete(id); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的行程')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _itineraries.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _itineraries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int i) {
                      final Map<String, dynamic> it = _itineraries[i];
                      return _ItineraryCard(
                        itinerary: it,
                        onDelete: () =>
                            _delete(it['id'] as String, it['name'] as String),
                        onTap: () async {
                          await Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ItineraryDetailPage(itinerary: it),
                            ),
                          );
                          _load();
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('新建行程'),
        backgroundColor: const Color(0xFF16324F),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.map_outlined, size: 80, color: Colors.blueGrey[200]),
            const SizedBox(height: 20),
            Text('还没有行程',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey[400])),
            const SizedBox(height: 10),
            Text('点击下方按钮，创建你的第一个旅行计划',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey[300])),
          ],
        ),
      ),
    );
  }
}

// ── 行程卡片 ──────────────────────────────────────────────────────────────────

class _ItineraryCard extends StatelessWidget {
  const _ItineraryCard({
    required this.itinerary,
    required this.onDelete,
    required this.onTap,
  });

  final Map<String, dynamic> itinerary;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  String _dateRange() {
    final String? s = itinerary['startDate'] as String?;
    final String? e = itinerary['endDate'] as String?;
    if (s != null && e != null) return '$s → $e';
    if (s != null) return '$s 出发';
    return '日期未设置';
  }

  int _days() {
    final String? s = itinerary['startDate'] as String?;
    final String? e = itinerary['endDate'] as String?;
    if (s == null || e == null) return 0;
    try {
      return DateTime.parse(e).difference(DateTime.parse(s)).inDays + 1;
    } catch (_) { return 0; }
  }

  @override
  Widget build(BuildContext context) {
    final int places = (itinerary['places'] as List<dynamic>).length;
    final int days = _days();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: Colors.blueGrey.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: const Color(0xFF16324F),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.flight_takeoff,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(itinerary['name'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(_dateRange(),
                      style: TextStyle(
                          fontSize: 13, color: Colors.blueGrey[500])),
                  const SizedBox(height: 6),
                  Row(children: <Widget>[
                    _Tag('$places 个景点'),
                    if (days > 0) ...<Widget>[
                      const SizedBox(width: 6),
                      _Tag('$days 天'),
                    ],
                  ]),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: Colors.blueGrey[50],
            borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style:
                TextStyle(fontSize: 11, color: Colors.blueGrey[600])),
      );
}

// ── 新建行程对话框 ──────────────────────────────────────────────────────────────

class _CreateItineraryDialog extends StatefulWidget {
  const _CreateItineraryDialog();
  @override
  State<_CreateItineraryDialog> createState() =>
      _CreateItineraryDialogState();
}

class _CreateItineraryDialogState extends State<_CreateItineraryDialog> {
  final TextEditingController _nameCtrl = TextEditingController();
  DateTime? _start;
  DateTime? _end;

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  String _fmt(DateTime? dt) {
    if (dt == null) return '选择日期';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pick({required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_start ?? DateTime.now())
          : (_end ?? _start?.add(const Duration(days: 1)) ?? DateTime.now()),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) _end = null;
      } else {
        _end = picked;
      }
    });
  }

  void _submit() {
    final String name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, <String, String>{
      'name': name,
      if (_start != null) 'startDate': _fmt(_start),
      if (_end != null) 'endDate': _fmt(_end),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建行程'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
                labelText: '行程名称', hintText: '如：北京五日游'),
          ),
          const SizedBox(height: 16),
          Row(children: <Widget>[
            Expanded(
                child: _DateBtn(
                    label: '出发', value: _fmt(_start),
                    onTap: () => _pick(isStart: true))),
            const SizedBox(width: 8),
            Expanded(
                child: _DateBtn(
                    label: '返回', value: _fmt(_end),
                    onTap: () => _pick(isStart: false))),
          ]),
        ],
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消')),
        ElevatedButton(onPressed: _submit, child: const Text('创建')),
      ],
    );
  }
}

class _DateBtn extends StatelessWidget {
  const _DateBtn(
      {required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.blueGrey[200]!),
              borderRadius: BorderRadius.circular(8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.blueGrey[500])),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}
