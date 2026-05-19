import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/details.dart';
import 'package:flutter_travel/services/destination_repository.dart';
import 'package:flutter_travel/services/itinerary_service.dart';
import 'package:flutter_travel/widgets/app_image.dart';

class ItineraryDetailPage extends StatefulWidget {
  const ItineraryDetailPage({super.key, required this.itinerary});
  final Map<String, dynamic> itinerary;

  @override
  State<ItineraryDetailPage> createState() =>
      _ItineraryDetailPageState();
}

class _ItineraryDetailPageState extends State<ItineraryDetailPage> {
  late Map<String, dynamic> _it;

  @override
  void initState() {
    super.initState();
    _it = Map<String, dynamic>.from(widget.itinerary);
    _it['places'] = List<dynamic>.from(_it['places'] as List<dynamic>);
  }

  List<Map<String, dynamic>> get _places =>
      (_it['places'] as List<dynamic>).cast<Map<String, dynamic>>();

  int get _maxDay => _places.isEmpty
      ? 0
      : _places.fold<int>(
          0,
          (int m, Map<String, dynamic> p) =>
              ((p['day'] as int?) ?? 1) > m ? (p['day'] as int? ?? 1) : m);

  Future<void> _reload() async {
    final List<Map<String, dynamic>> all = await ItineraryService.getAll();
    final Map<String, dynamic>? updated = all.cast<Map<String, dynamic>?>().firstWhere(
          (Map<String, dynamic>? m) => m != null && m['id'] == _it['id'],
          orElse: () => null,
        );
    if (updated != null && mounted) setState(() => _it = updated);
  }

  Future<void> _addPlace() async {
    final Map<String, dynamic>? picked =
        await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PlacePickerSheet(),
    );
    if (picked == null || !mounted) return;

    final Map<String, dynamic>? config =
        await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _DayNoteDialog(maxDay: _maxDay),
    );
    if (config == null) return;

    await ItineraryService.addPlace(
      _it['id'] as String,
      picked,
      day: config['day'] as int,
      note: config['note'] as String,
    );
    _reload();
  }

  Future<void> _removePlace(String pid) async {
    await ItineraryService.removePlace(_it['id'] as String, pid);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_it['name'] as String)),
      body: _places.isEmpty ? _buildEmpty() : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPlace,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('添加景点'),
        backgroundColor: const Color(0xFF16324F),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.location_off_outlined,
                size: 72, color: Colors.blueGrey[200]),
            const SizedBox(height: 16),
            Text('行程还没有景点',
                style: TextStyle(
                    fontSize: 18, color: Colors.blueGrey[400])),
            const SizedBox(height: 8),
            Text('点击右下角按钮，为行程添加目的地',
                style: TextStyle(color: Colors.blueGrey[300])),
          ],
        ),
      );

  Widget _buildBody() {
    final int max = _maxDay;
    final List<Widget> sections = <Widget>[];
    for (int day = 1; day <= max; day++) {
      final List<Map<String, dynamic>> dayPlaces = _places
          .where((Map<String, dynamic> p) => (p['day'] as int?) == day)
          .toList();
      if (dayPlaces.isEmpty) continue;
      sections.add(_DaySection(
        day: day,
        places: dayPlaces,
        onDelete: (String pid) => _removePlace(pid),
        onTap: (Map<String, dynamic> p) => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
              builder: (_) => Details(place: Map<String, dynamic>.from(p))),
        ),
      ));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: sections,
    );
  }
}

// ── 按天分组区块 ──────────────────────────────────────────────────────────────

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.places,
    required this.onDelete,
    required this.onTap,
  });

  final int day;
  final List<Map<String, dynamic>> places;
  final void Function(String pid) onDelete;
  final void Function(Map<String, dynamic> place) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFF16324F),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('Day $day',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: Colors.blueGrey[100], thickness: 1)),
          ]),
        ),
        ...places.map((Map<String, dynamic> p) => _PlaceTile(
              place: p,
              onDelete: () => onDelete(p['pid'] as String? ?? ''),
              onTap: () => onTap(p),
            )),
      ],
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({
    required this.place,
    required this.onDelete,
    required this.onTap,
  });

  final Map<String, dynamic> place;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String? note = place['note'] as String?;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: Colors.blueGrey.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: <Widget>[
            AppImage(
              src: place['img'] as String? ?? '',
              height: 68,
              width: 80,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(place['name'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: <Widget>[
                    Icon(Icons.location_on,
                        size: 12, color: Colors.blueGrey[400]),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(place['location'] as String? ?? '',
                          style: TextStyle(
                              fontSize: 12, color: Colors.blueGrey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  if (note != null && note.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(note,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey[600],
                            fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 添加景点时选择天数 + 备注 ─────────────────────────────────────────────────

class _DayNoteDialog extends StatefulWidget {
  const _DayNoteDialog({required this.maxDay});
  final int maxDay;
  @override
  State<_DayNoteDialog> createState() => _DayNoteDialogState();
}

class _DayNoteDialogState extends State<_DayNoteDialog> {
  late int _day;
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _day = widget.maxDay + 1;
  }

  @override
  void dispose() { _noteCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('加入行程'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(children: <Widget>[
            const Text('第', style: TextStyle(fontSize: 15)),
            Expanded(
              child: Slider(
                value: _day.toDouble(),
                min: 1,
                max: 14,
                divisions: 13,
                label: '$_day 天',
                activeColor: const Color(0xFF16324F),
                onChanged: (double v) =>
                    setState(() => _day = v.round()),
              ),
            ),
            Text('$_day 天',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '如：上午参观，记得带水'),
            maxLines: 2,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, <String, dynamic>{
            'day': _day,
            'note': _noteCtrl.text.trim(),
          }),
          child: const Text('添加'),
        ),
      ],
    );
  }
}

// ── 景点选择底部弹出层 ────────────────────────────────────────────────────────

class _PlacePickerSheet extends StatefulWidget {
  const _PlacePickerSheet();
  @override
  State<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<_PlacePickerSheet> {
  List<Map<String, dynamic>> _all = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _filtered = <Map<String, dynamic>>[];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final List<Map<String, dynamic>> places =
        await DestinationRepository.getDestinations();
    if (mounted) {
      setState(() {
        _all = places;
        _filtered = places;
        _loading = false;
      });
    }
  }

  void _filter(String q) {
    final String lq = q.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((Map<String, dynamic> p) =>
              '${p["name"]}'.toLowerCase().contains(lq) ||
              '${p["location"]}'.toLowerCase().contains(lq)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: <Widget>[
        const SizedBox(height: 8),
        Container(
          height: 4, width: 40,
          decoration: BoxDecoration(
              color: Colors.blueGrey[200],
              borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _filter,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '搜索景点…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF6F8FB),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        _all.isEmpty ? '请先在设置中获取景点数据' : '没有匹配的景点',
                        style: TextStyle(color: Colors.blueGrey[400]),
                      ))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (BuildContext ctx, int i) {
                        final Map<String, dynamic> p = _filtered[i];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AppImage(
                                src: p['img'] as String? ?? '',
                                height: 44,
                                width: 56),
                          ),
                          title: Text(p['name'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(p['location'] as String? ?? ''),
                          onTap: () => Navigator.pop(context, p),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
