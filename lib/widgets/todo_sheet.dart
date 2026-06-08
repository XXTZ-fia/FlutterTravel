import 'package:flutter/material.dart';
import 'package:flutter_travel/services/itinerary_service.dart';

Future<void> showTodoSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TodoSheet(),
  );
}

class _TodoSheet extends StatefulWidget {
  const _TodoSheet();

  @override
  State<_TodoSheet> createState() => _TodoSheetState();
}

class _TodoSheetState extends State<_TodoSheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Map<String, dynamic>> schedules = await ItineraryService.getAll();
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> schedule in schedules) {
      final List<dynamic> places = schedule['places'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic rawPlace in places) {
        final Map<String, dynamic> place = Map<String, dynamic>.from(rawPlace as Map);
        items.add(<String, dynamic>{
          'scheduleName': schedule['name'],
          'visitDate': place['visitDate'],
          'name': place['name'],
          'location': place['location'],
          'note': place['note'],
        });
      }
    }
    items.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      return '${a['visitDate'] ?? ''}'.compareTo('${b['visitDate'] ?? ''}');
    });
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              '待办事项',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF16324F),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '这里会列出已经加入行程的待出行地点。',
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? Center(
                          child: Text(
                            '还没有待办事项',
                            style: TextStyle(color: Colors.blueGrey[500]),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, int index) {
                            final Map<String, dynamic> item = _items[index];
                            final String note = item['note'] as String? ?? '';
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          item['name'] as String? ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF16324F),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEAF1F7),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          item['visitDate'] as String? ?? '待定',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF16324F),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${item['scheduleName']} · ${item['location']}',
                                    style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
                                  ),
                                  if (note.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 8),
                                    Text(
                                      note,
                                      style: TextStyle(
                                        color: Colors.blueGrey[700],
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
