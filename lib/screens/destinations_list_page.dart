import 'package:flutter/material.dart';
import 'package:flutter_travel/services/destination_repository.dart';
import 'package:flutter_travel/util/multilingual_search.dart';
import 'package:flutter_travel/widgets/app_image.dart';

class DestinationsListPage extends StatefulWidget {
  const DestinationsListPage({super.key});

  @override
  State<DestinationsListPage> createState() => _DestinationsListPageState();
}

class _DestinationsListPageState extends State<DestinationsListPage> {
  List<Map<String, dynamic>> _all = <Map<String, dynamic>>[];
  String _query = '';
  String _selectedTag = 'All';
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  static const List<String> _tags = <String>[
    'All', 'Beach', 'Adventure', 'Culture', 'Food', 'Shopping', 'Budget',
  ];

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
    final List<Map<String, dynamic>> data =
        await DestinationRepository.getDestinations();
    if (mounted) {
      setState(() {
        _all = data;
        _loading = false;
      });
    }
  }

  Future<void> _delete(String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除目的地'),
        content: Text('确认删除「$name」？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await DestinationRepository.deleteDestination(name);
    setState(() => _all.removeWhere((Map<String, dynamic> p) => p['name'] == name));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除 $name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearAll() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('清空全部数据'),
        content: const Text('将删除所有缓存目的地，退出后将回退到本地演示数据。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('清空', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    await DestinationRepository.clearCache();
    if (mounted) {
      Navigator.pop(context, true); // signal caller to refresh
    }
  }

  List<Map<String, dynamic>> get _displayed {
    return _all.where((Map<String, dynamic> p) {
      final bool tagMatch = _selectedTag == 'All' ||
          (p['tags'] as List<dynamic>).contains(_selectedTag);
      if (!tagMatch) return false;
      if (_query.isEmpty) return true;
        return MultilingualSearch.matchesPlace(p, _query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_loading ? '目的地管理' : '目的地管理（${_all.length}条）'),
        actions: <Widget>[
          if (_all.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: '清空全部',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _all.isEmpty
              ? const Center(
                  child: Text('暂无缓存数据',
                      style: TextStyle(color: Colors.blueGrey)),
                )
              : Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (String v) =>
                            setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: '搜索名称或地点…',
                          prefixIcon: const Icon(Icons.search,
                              color: Colors.blueGrey),
                          filled: true,
                          fillColor: const Color(0xFFF6F8FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: _tags.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 6),
                        itemBuilder: (BuildContext context, int i) {
                          final String tag = _tags[i];
                          final bool sel = _selectedTag == tag;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedTag = tag),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: sel
                                    ? const Color(0xFF16324F)
                                    : const Color(0xFFF6F8FB),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel
                                      ? const Color(0xFF16324F)
                                      : const Color(0xFFD6E0EA),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : Colors.blueGrey[700],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: _displayed.length,
                        itemBuilder: (BuildContext context, int i) {
                          final Map<String, dynamic> p = _displayed[i];
                          return _DestinationTile(
                            place: p,
                            onDelete: () =>
                                _delete(p['name'] as String),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.place,
    required this.onDelete,
  });

  final Map<String, dynamic> place;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final List<String> tags =
        List<String>.from(place['tags'] as List<dynamic>);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: AppImage(
                src: place['img'] as String,
                height: 90,
                width: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      place['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: <Widget>[
                        Icon(Icons.location_on,
                            size: 12, color: Colors.blueGrey[400]),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            place['location'] as String,
                            style: TextStyle(
                                fontSize: 12, color: Colors.blueGrey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: tags
                          .take(3)
                          .map(
                            (String t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F1F8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF16324F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.star_rounded,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '${place['rating']}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red[400], size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
