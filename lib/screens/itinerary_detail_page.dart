import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/details.dart';
import 'package:flutter_travel/services/destination_repository.dart';
import 'package:flutter_travel/services/itinerary_service.dart';
import 'package:flutter_travel/widgets/app_image.dart';
import 'package:flutter_travel/widgets/app_date_picker_sheet.dart';

class ItineraryDetailPage extends StatefulWidget {
  const ItineraryDetailPage({super.key, required this.itinerary});

  final Map<String, dynamic> itinerary;

  @override
  State<ItineraryDetailPage> createState() => _ItineraryDetailPageState();
}

class _ItineraryDetailPageState extends State<ItineraryDetailPage> {
  late Map<String, dynamic> _itinerary;

  @override
  void initState() {
    super.initState();
    _itinerary = Map<String, dynamic>.from(widget.itinerary);
    _itinerary['places'] =
        List<dynamic>.from(_itinerary['places'] as List<dynamic>? ?? <dynamic>[]);
  }

  List<Map<String, dynamic>> get _places =>
      (_itinerary['places'] as List<dynamic>).cast<Map<String, dynamic>>();

  Future<void> _reload() async {
    final List<Map<String, dynamic>> all = await ItineraryService.getAll();
    for (final Map<String, dynamic> item in all) {
      if (item['id'] == _itinerary['id']) {
        if (!mounted) return;
        setState(() => _itinerary = item);
        return;
      }
    }
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

    final Map<String, dynamic>? config = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _VisitDateNoteDialog(
        startDate: _itinerary['startDate'] as String?,
        endDate: _itinerary['endDate'] as String?,
      ),
    );
    if (config == null) return;

    await ItineraryService.addPlace(
      _itinerary['id'] as String,
      picked,
      note: config['note'] as String,
      visitDate: config['visitDate'] as String,
    );
    _reload();
  }

  Future<void> _removePlace(String pid) async {
    await ItineraryService.removePlace(_itinerary['id'] as String, pid);
    _reload();
  }

  List<_DateSectionData> get _sections {
    final Map<String, List<Map<String, dynamic>>> grouped =
        <String, List<Map<String, dynamic>>>{};
    for (final Map<String, dynamic> place in _places) {
      final String key = place['visitDate'] as String? ?? '未指定日期';
      grouped.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(place);
    }

    final List<_DateSectionData> sections = grouped.entries.map((MapEntry<String, List<Map<String, dynamic>>> entry) {
      final List<Map<String, dynamic>> places = List<Map<String, dynamic>>.from(entry.value);
      places.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
        final String aTime = a['addedAt'] as String? ?? '';
        final String bTime = b['addedAt'] as String? ?? '';
        return aTime.compareTo(bTime);
      });
      return _DateSectionData(label: entry.key, places: places);
    }).toList();

    sections.sort((_DateSectionData a, _DateSectionData b) {
      if (a.label == '未指定日期') return 1;
      if (b.label == '未指定日期') return -1;
      return a.label.compareTo(b.label);
    });
    return sections;
  }

  int get _scheduledDays => _sections.where((_DateSectionData section) => section.label != '未指定日期').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(title: Text(_itinerary['name'] as String)),
      body: _places.isEmpty ? _buildEmpty() : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPlace,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('添加地点'),
        backgroundColor: const Color(0xFF16324F),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.location_off_outlined, size: 72, color: Colors.blueGrey[200]),
            const SizedBox(height: 16),
            const Text(
              '行程里还没有地点',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF16324F)),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右下角按钮，按具体日期把地点安排进来。',
              style: TextStyle(color: Colors.blueGrey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: <Widget>[
        _SummaryCard(
          startDate: _itinerary['startDate'] as String?,
          endDate: _itinerary['endDate'] as String?,
          placeCount: _places.length,
          dayCount: _scheduledDays,
        ),
        const SizedBox(height: 16),
        ..._sections.map(
          (_DateSectionData section) => _DateSection(
            label: section.label,
            places: section.places,
            onDelete: _removePlace,
            onTap: (Map<String, dynamic> place) => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => Details(place: Map<String, dynamic>.from(place)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateSectionData {
  const _DateSectionData({required this.label, required this.places});

  final String label;
  final List<Map<String, dynamic>> places;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.startDate,
    required this.endDate,
    required this.placeCount,
    required this.dayCount,
  });

  final String? startDate;
  final String? endDate;
  final int placeCount;
  final int dayCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF16324F), Color(0xFF2C6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            startDate != null && endDate != null ? '$startDate - $endDate' : '日期待定',
            style: const TextStyle(color: Color(0xDDEAF3FF), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(child: _MetricPill(label: 'Places', value: '$placeCount')),
              const SizedBox(width: 12),
              Expanded(child: _MetricPill(label: 'Days', value: '$dayCount')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Color(0xDDEAF3FF), fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  const _DateSection({
    required this.label,
    required this.places,
    required this.onDelete,
    required this.onTap,
  });

  final String label;
  final List<Map<String, dynamic>> places;
  final void Function(String pid) onDelete;
  final void Function(Map<String, dynamic> place) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16324F),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${places.length} 个地点',
                style: TextStyle(color: Colors.blueGrey[500], fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...places.map(
            (Map<String, dynamic> place) => _PlaceTile(
              place: place,
              onDelete: () => onDelete(place['pid'] as String? ?? ''),
              onTap: () => onTap(place),
            ),
          ),
        ],
      ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0E16324F),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            AppImage(
              src: place['img'] as String? ?? '',
              height: 74,
              width: 86,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    place['name'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF16324F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place['location'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey[500]),
                  ),
                  if (note != null && note.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
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

class _VisitDateNoteDialog extends StatefulWidget {
  const _VisitDateNoteDialog({
    required this.startDate,
    required this.endDate,
  });

  final String? startDate;
  final String? endDate;

  @override
  State<_VisitDateNoteDialog> createState() => _VisitDateNoteDialogState();
}

class _VisitDateNoteDialogState extends State<_VisitDateNoteDialog> {
  final TextEditingController _noteCtrl = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _parseDate(widget.startDate) ?? DateTime.now();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  String _fmt(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  List<DateTime> get _options {
    final DateTime? start = _parseDate(widget.startDate);
    final DateTime? end = _parseDate(widget.endDate);
    if (start == null || end == null) return <DateTime>[];
    final List<DateTime> dates = <DateTime>[];
    DateTime cursor = start;
    while (!cursor.isAfter(end)) {
      dates.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return dates;
  }

  Future<void> _pickCustomDate() async {
    final DateTime? picked = await showAppDatePickerSheet(
      context,
      title: '选择出行日期',
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('安排到哪一天'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_options.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ..._options.map((DateTime date) {
                  final bool selected =
                      _selectedDate != null && _fmt(_selectedDate!) == _fmt(date);
                  return ChoiceChip(
                    label: Text(_fmt(date)),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedDate = date),
                  );
                }),
                ActionChip(
                  avatar: const Icon(Icons.edit_calendar_outlined, size: 18),
                  label: const Text('其他日期'),
                  onPressed: _pickCustomDate,
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: _pickCustomDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(_selectedDate == null ? '选择日期' : _fmt(_selectedDate!)),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: '备注（可选）',
              hintText: '如：晚饭后去，顺路看看夜景',
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _selectedDate == null
              ? null
              : () => Navigator.pop(context, <String, dynamic>{
                    'visitDate': _fmt(_selectedDate!),
                    'note': _noteCtrl.text.trim(),
                  }),
          child: const Text('添加'),
        ),
      ],
    );
  }
}

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
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final List<Map<String, dynamic>> places = await DestinationRepository.getDestinations();
    if (!mounted) return;
    setState(() {
      _all = places;
      _filtered = places;
      _loading = false;
    });
  }

  void _filter(String query) {
    final String lower = query.toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? _all
          : _all.where((Map<String, dynamic> place) {
              return '${place['name']}'.toLowerCase().contains(lower) ||
                  '${place['location']}'.toLowerCase().contains(lower);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.blueGrey[200],
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: '搜索想加入的地点',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> place = _filtered[index];
                      return InkWell(
                        onTap: () => Navigator.pop(context, place),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: <Widget>[
                              AppImage(
                                src: place['img'] as String? ?? '',
                                height: 62,
                                width: 72,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      place['name'] as String? ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF16324F),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      place['location'] as String? ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.blueGrey[500], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
