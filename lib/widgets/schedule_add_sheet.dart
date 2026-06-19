import 'package:flutter/material.dart';
import 'package:flutter_travel/services/api_key_service.dart';
import 'package:flutter_travel/services/deepseek_service.dart';
import 'package:flutter_travel/services/itinerary_service.dart';
import 'package:flutter_travel/widgets/app_date_picker_sheet.dart';

Future<bool> showAddToScheduleSheet(
  BuildContext context,
  Map<String, dynamic> place,
) async {
  final bool? result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => _ScheduleAddSheet(place: place),
  );
  return result ?? false;
}

class _ScheduleAddSheet extends StatefulWidget {
  const _ScheduleAddSheet({required this.place});

  final Map<String, dynamic> place;

  @override
  State<_ScheduleAddSheet> createState() => _ScheduleAddSheetState();
}

class _ScheduleAddSheetState extends State<_ScheduleAddSheet> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  List<Map<String, dynamic>> _schedules = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _saving = false;
  bool _enriching = false;
  String? _selectedScheduleId;
  DateTime? _selectedDate;
  DateTime? _newStartDate;
  DateTime? _newEndDate;

  bool get _isCreatingNew => _selectedScheduleId == null;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    final List<Map<String, dynamic>> schedules = await ItineraryService.getAll();
    if (!mounted) return;

    final Map<String, dynamic>? first = schedules.isNotEmpty ? schedules.first : null;
    final DateTime now = DateTime.now();
    setState(() {
      _schedules = schedules;
      _selectedScheduleId = first?['id'] as String?;
      _selectedDate = _resolveInitialDate(first) ?? now;
      _newStartDate = now;
      _newEndDate = now.add(const Duration(days: 1));
      _loading = false;
    });
  }

  Map<String, dynamic>? get _selectedSchedule {
    if (_selectedScheduleId == null) return null;
    for (final Map<String, dynamic> schedule in _schedules) {
      if (schedule['id'] == _selectedScheduleId) {
        return schedule;
      }
    }
    return null;
  }

  DateTime? _resolveInitialDate(Map<String, dynamic>? schedule) {
    if (schedule == null) return null;
    final String? start = schedule['startDate'] as String?;
    final String? end = schedule['endDate'] as String?;
    final DateTime now = DateTime.now();
    final DateTime? startDate = _parseDate(start);
    final DateTime? endDate = _parseDate(end);
    if (startDate == null || endDate == null) return startDate ?? endDate;
    if (now.isBefore(startDate)) return startDate;
    if (now.isAfter(endDate)) return endDate;
    return now;
  }

  List<DateTime> _dateOptionsFor(Map<String, dynamic>? schedule) {
    if (schedule == null) return <DateTime>[];
    final DateTime? start = _parseDate(schedule['startDate'] as String?);
    final DateTime? end = _parseDate(schedule['endDate'] as String?);
    if (start == null || end == null) return <DateTime>[];

    final List<DateTime> dates = <DateTime>[];
    DateTime cursor = start;
    while (!cursor.isAfter(end)) {
      dates.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return dates;
  }

  Future<void> _pickDate({
    required bool forStart,
    required bool forNewSchedule,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = forNewSchedule
        ? (forStart ? (_newStartDate ?? now) : (_newEndDate ?? _newStartDate ?? now))
        : (_selectedDate ?? now);
    final DateTime? picked = await showAppDatePickerSheet(
      context,
      title: forNewSchedule ? '选择行程日期' : '选择出行日期',
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (forNewSchedule) {
        if (forStart) {
          _newStartDate = picked;
          if (_newEndDate != null && _newEndDate!.isBefore(picked)) {
            _newEndDate = picked;
          }
          _selectedDate = picked;
        } else {
          _newEndDate = picked;
          if (_newStartDate != null && picked.isBefore(_newStartDate!)) {
            _newStartDate = picked;
          }
          _selectedDate ??= picked;
        }
      } else {
        _selectedDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_saving || _enriching) return;

    String? scheduleId = _selectedScheduleId;
    final String name = _nameCtrl.text.trim();
    final DateTime? visitDate = _selectedDate;
    if (visitDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择具体的出行日期')),
      );
      return;
    }

    if (_isCreatingNew) {
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入新的行程名称')),
        );
        return;
      }
      if (_newStartDate == null || _newEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先设置新行程的开始和结束日期')),
        );
        return;
      }
      if (_newEndDate!.isBefore(_newStartDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('结束日期不能早于开始日期')),
        );
        return;
      }
    }

    setState(() {
      _saving = true;
      _enriching = false;
    });
    try {
      if (scheduleId == null) {
        scheduleId = await ItineraryService.create(
          name: name,
          startDate: _fmt(_newStartDate),
          endDate: _fmt(_newEndDate),
        );
      }

      final Map<String, dynamic> preparedPlace = await _preparePlaceForSchedule(
        Map<String, dynamic>.from(widget.place),
      );

      await ItineraryService.addPlace(
        scheduleId,
        preparedPlace,
        note: _noteCtrl.text.trim(),
        visitDate: _fmt(visitDate),
        day: 1,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _enriching = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _preparePlaceForSchedule(
    Map<String, dynamic> place,
  ) async {
    final String details = place['details'] as String? ?? '';
    if (details.length >= 80) {
      return place;
    }
    final String apiKey = await ApiKeyService.load();
    if (apiKey.isEmpty) {
      return place;
    }
    try {
      final String? desc = await DeepSeekService.generatePlaceDescription(
        apiKey: apiKey,
        place: place,
      );
      if (desc != null && desc.isNotEmpty) {
        place['details'] = desc;
      }
    } catch (_) {}
    return place;
  }

  String _fmt(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _fmtShort(DateTime date) {
    const List<String> week = <String>['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${date.month}/${date.day} ${week[date.weekday - 1]}';
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final Map<String, dynamic>? selectedSchedule = _selectedSchedule;
    final List<DateTime> dateOptions = _dateOptionsFor(selectedSchedule);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
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
                '加入行程',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.place['name'] as String? ?? '',
                style: TextStyle(
                  color: Colors.blueGrey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...<Widget>[
                const Text(
                  '选择一个行程',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 118,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      for (final Map<String, dynamic> schedule in _schedules)
                        _ScheduleChoiceCard(
                          title: schedule['name'] as String,
                          subtitle: _scheduleSubtitle(schedule),
                          selected: _selectedScheduleId == schedule['id'],
                          onTap: () {
                            setState(() {
                              _selectedScheduleId = schedule['id'] as String;
                              _selectedDate = _resolveInitialDate(schedule) ?? DateTime.now();
                            });
                          },
                        ),
                      _ScheduleChoiceCard(
                        title: '新建',
                        subtitle: '新建行程',
                        selected: _isCreatingNew,
                        accentColor: const Color(0xFF2C6E63),
                        icon: Icons.add_rounded,
                        onTap: () {
                          setState(() {
                            _selectedScheduleId = null;
                            _selectedDate = _newStartDate ?? DateTime.now();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_isCreatingNew) ...<Widget>[
                  _SectionCard(
                    title: '新建行程',
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: '行程名称',
                          hintText: '例如：上海夏夜漫游',
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
                              child: _DateCard(
                                label: '开始日期',
                                value: _newStartDate == null ? '选择日期' : _fmt(_newStartDate),
                                icon: Icons.play_circle_outline,
                                onTap: () => _pickDate(forStart: true, forNewSchedule: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DateCard(
                                label: '结束日期',
                                value: _newEndDate == null ? '选择日期' : _fmt(_newEndDate),
                                icon: Icons.flag_outlined,
                                onTap: () => _pickDate(forStart: false, forNewSchedule: true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ] else if (selectedSchedule != null) ...<Widget>[
                  _SectionCard(
                    title: selectedSchedule['name'] as String,
                    subtitle: _scheduleSubtitle(selectedSchedule),
                    child: dateOptions.isEmpty
                        ? _DateCard(
                            label: '出行日期',
                            value: _selectedDate == null ? '选择日期' : _fmt(_selectedDate),
                            icon: Icons.calendar_month_outlined,
                            onTap: () => _pickDate(
                              forStart: true,
                              forNewSchedule: false,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                '选择加入哪一天',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF16324F),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 46,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: dateOptions.length + 1,
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (BuildContext context, int index) {
                                    if (index == dateOptions.length) {
                                      return ActionChip(
                                        avatar: const Icon(
                                          Icons.edit_calendar_outlined,
                                          size: 18,
                                        ),
                                        label: const Text('其他日期'),
                                        onPressed: () => _pickDate(
                                          forStart: true,
                                          forNewSchedule: false,
                                        ),
                                      );
                                    }
                                    final DateTime date = dateOptions[index];
                                    final bool selected = _selectedDate != null &&
                                        _fmt(_selectedDate) == _fmt(date);
                                    return ChoiceChip(
                                      label: Text(_fmtShort(date)),
                                      selected: selected,
                                      onSelected: (_) => setState(() => _selectedDate = date),
                                      selectedColor: const Color(0xFF16324F),
                                      labelStyle: TextStyle(
                                        color: selected ? Colors.white : const Color(0xFF16324F),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      side: const BorderSide(color: Color(0xFFD6E0EA)),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),
                ],
                _SectionCard(
                  title: '添加细节',
                  child: Column(
                    children: <Widget>[
                      _DateCard(
                        label: '最终加入日期',
                        value: _selectedDate == null ? '选择日期' : _fmt(_selectedDate),
                        icon: Icons.event_available_outlined,
                        onTap: () => _pickDate(
                          forStart: true,
                          forNewSchedule: _isCreatingNew,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _noteCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: '备注',
                          hintText: '例如：晚上亮灯后去更好看',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.event_available_outlined),
                    label: Text(
                      _saving ? '保存中...' : '加入行程',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16324F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _scheduleSubtitle(Map<String, dynamic> schedule) {
    final String? start = schedule['startDate'] as String?;
    final String? end = schedule['endDate'] as String?;
    if (start != null && end != null) return '$start - $end';
    if (start != null) return '$start 出发';
    return '${(schedule['places'] as List<dynamic>).length} 个地点';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4F8),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF16324F),
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0D16324F),
              blurRadius: 12,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF16324F)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF16324F),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF16324F)),
          ],
        ),
      ),
    );
  }
}

class _ScheduleChoiceCard extends StatelessWidget {
  const _ScheduleChoiceCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.accentColor = const Color(0xFF16324F),
    this.icon = Icons.route_outlined,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 170,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? accentColor : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? accentColor : const Color(0xFFD8E1EA),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: selected
                    ? accentColor.withOpacity(0.18)
                    : Colors.blueGrey.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Icon(icon, color: selected ? Colors.white : accentColor),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : const Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  color: selected ? Colors.white70 : Colors.blueGrey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
