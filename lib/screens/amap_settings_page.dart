import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/destinations_list_page.dart';
import 'package:flutter_travel/services/amap_fetch_config.dart';
import 'package:flutter_travel/services/amap_key_service.dart';
import 'package:flutter_travel/services/api_key_service.dart';
import 'package:flutter_travel/services/destination_repository.dart';

class AmapSettingsPage extends StatefulWidget {
  const AmapSettingsPage({super.key});

  @override
  State<AmapSettingsPage> createState() => _AmapSettingsPageState();
}

class _AmapSettingsPageState extends State<AmapSettingsPage> {
  final TextEditingController _keyController = TextEditingController();
  bool _obscure = true;
  bool _loading = true;
  bool _saving = false;
  bool _fetching = false;

  String _savedKey = '';
  int _cachedCount = 0;
  DateTime? _cacheDate;

  // Fetch progress state
  int _fetchDone = 0;
  int _fetchTotal = 10;
  String _fetchPhase = 'amap'; // 'amap' | 'ai'

  // Fetch config state
  AmapFetchConfig _config = AmapFetchConfig.defaults;
  bool _deepseekAvailable = false;
  bool _configExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final String key = await AmapKeyService.load();
    final int count = await DestinationRepository.cachedCount;
    final DateTime? date = await DestinationRepository.cacheDate;
    final AmapFetchConfig config = await AmapFetchConfig.load();
    final bool dsOk = (await ApiKeyService.load()).isNotEmpty;
    if (mounted) {
      setState(() {
        _savedKey = key;
        _keyController.text = key;
        _cachedCount = count;
        _cacheDate = date;
        _config = config;
        _deepseekAvailable = dsOk;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final String input = _keyController.text.trim();
    if (input.isEmpty) {
      _snack('请输入高德地图 API Key。', isError: true);
      return;
    }
    setState(() => _saving = true);
    await AmapKeyService.save(input);
    if (mounted) {
      setState(() {
        _savedKey = input;
        _saving = false;
      });
      _snack('API Key 保存成功。');
    }
  }

  Future<void> _fetchDestinations() async {
    final String key =
        _savedKey.isNotEmpty ? _savedKey : _keyController.text.trim();
    if (key.isEmpty) {
      _snack('请先保存 API Key，再获取数据。', isError: true);
      return;
    }
    if (_config.cities.isEmpty) {
      _snack('请至少选择一个城市。', isError: true);
      return;
    }

    await AmapFetchConfig.save(
      _config.copyWith(keywords: '旅游景点'),
    );

    setState(() {
      _fetching = true;
      _fetchDone = 0;
      _fetchTotal = _config.cities.length;
      _fetchPhase = 'amap';
    });

    try {
      final int count = await DestinationRepository.refresh(
        onProgress: (int done, int total, String phase) {
          if (mounted) {
            setState(() {
              _fetchDone = done;
              _fetchTotal = total;
              _fetchPhase = phase;
            });
          }
        },
      );
      final DateTime? date = await DestinationRepository.cacheDate;
      if (mounted) {
        setState(() {
          _cachedCount = count;
          _cacheDate = date;
          _fetching = false;
        });
        _snack('成功获取 $count 个目的地！');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _fetching = false);
        _snack('获取失败，请检查 API Key 是否正确。', isError: true);
      }
    }
  }

  Future<void> _clearKey() async {
    await AmapKeyService.clear();
    await DestinationRepository.clearCache();
    if (mounted) {
      setState(() {
        _savedKey = '';
        _keyController.clear();
        _cachedCount = 0;
        _cacheDate = null;
      });
      _snack('API Key 已移除，将恢复使用本地数据。');
    }
  }

  Future<void> _openDataList() async {
    final Object? result = await Navigator.of(context).push(
      MaterialPageRoute<Object>(
          builder: (_) => const DestinationsListPage()),
    );
    // If user cleared all data from that page, refresh counts
    if (result == true && mounted) {
      final int count = await DestinationRepository.cachedCount;
      setState(() => _cachedCount = count);
    }
  }

  void _toggleCity(String city) {
    final List<String> cities = List<String>.from(_config.cities);
    if (cities.contains(city)) {
      if (cities.length == 1) return; // keep at least 1
      cities.remove(city);
    } else {
      cities.add(city);
    }
    setState(() => _config = _config.copyWith(cities: cities));
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.red[700] : const Color(0xFF16324F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final bool isConfigured = _savedKey.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('高德地图数据'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Status banner ──
            _StatusBanner(
              isConfigured: isConfigured,
              cachedCount: _cachedCount,
              cacheDate: _cacheDate,
            ),
            const SizedBox(height: 24),

            // ── API Key ──
            _SectionTitle('高德 Web 服务 API Key'),
            const SizedBox(height: 4),
            Text(
              'Key 仅存储在本机，不上传至任何服务器。',
              style: TextStyle(
                  fontSize: 13, color: Colors.blueGrey[600], height: 1.5),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _keyController,
              obscureText: _obscure,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                filled: true,
                fillColor: const Color(0xFFF6F8FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.blueGrey[400],
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16324F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('保存 Key'),
                  ),
                ),
                if (isConfigured) ...<Widget>[
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _clearKey,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[300]!),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('移除'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // ── Fetch config (expandable) ──
            GestureDetector(
              onTap: () =>
                  setState(() => _configExpanded = !_configExpanded),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.tune_outlined,
                        color: Color(0xFF16324F), size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        '搜索设置',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF16324F),
                        ),
                      ),
                    ),
                    Text(
                      '${_config.cities.length}城 · ${_config.countPerCity}条/城',
                      style: TextStyle(
                          fontSize: 12, color: Colors.blueGrey[500]),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _configExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Colors.blueGrey[400],
                    ),
                  ],
                ),
              ),
            ),
            if (_configExpanded) ...<Widget>[
              const SizedBox(height: 12),
              _ConfigPanel(
                config: _config,
                deepseekAvailable: _deepseekAvailable,
                onChanged: (AmapFetchConfig c) =>
                    setState(() => _config = c),
                onToggleCity: _toggleCity,
              ),
            ],
            const SizedBox(height: 24),

            // ── Fetch button / progress ──
            _SectionTitle('目的地数据'),
            const SizedBox(height: 8),
            _fetching
                ? _FetchProgress(
                    done: _fetchDone,
                    total: _fetchTotal,
                    phase: _fetchPhase,
                    cities: _config.cities,
                  )
                : SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _fetchDestinations,
                      icon: const Icon(Icons.download_outlined),
                      label: Text(_cachedCount > 0 ? '重新获取目的地' : '获取真实目的地'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16324F),
                        side: const BorderSide(color: Color(0xFF16324F)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
            const SizedBox(height: 16),

            // ── Data management ──
            if (_cachedCount > 0) ...<Widget>[
              OutlinedButton.icon(
                onPressed: _openDataList,
                icon: const Icon(Icons.list_alt_outlined),
                label: Text('管理目的地（$_cachedCount 条）'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueGrey[700],
                  side: BorderSide(color: Colors.blueGrey[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
              const SizedBox(height: 24),
            ],

            _HowToCard(),
          ],
        ),
      ),
    );
  }
}

// ── Config panel ──────────────────────────────────────────────────────────────

class _ConfigPanel extends StatelessWidget {
  const _ConfigPanel({
    required this.config,
    required this.deepseekAvailable,
    required this.onChanged,
    required this.onToggleCity,
  });

  final AmapFetchConfig config;
  final bool deepseekAvailable;
  final ValueChanged<AmapFetchConfig> onChanged;
  final ValueChanged<String> onToggleCity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // City selection
          const Text(
            '选择城市',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF16324F)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AmapFetchConfig.availableCities.map((String city) {
              final bool selected = config.cities.contains(city);
              return GestureDetector(
                onTap: () => onToggleCity(city),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF16324F)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF16324F)
                          : const Color(0xFFCFD8DC),
                    ),
                  ),
                  child: Text(
                    city,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.blueGrey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Count per city
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  '每个城市获取条数',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF16324F)),
                ),
              ),
              Text(
                '${config.countPerCity} 条',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey[700]),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF16324F),
              thumbColor: const Color(0xFF16324F),
              overlayColor: const Color(0x1A16324F),
              inactiveTrackColor: const Color(0xFFCFD8DC),
            ),
            child: Slider(
              value: config.countPerCity.toDouble(),
              min: 5,
              max: 25,
              divisions: 4,
              label: '${config.countPerCity}条',
              onChanged: (double v) =>
                  onChanged(config.copyWith(countPerCity: v.round())),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('5条', style: TextStyle(fontSize: 11, color: Colors.blueGrey[400])),
              Text('10条', style: TextStyle(fontSize: 11, color: Colors.blueGrey[400])),
              Text('15条', style: TextStyle(fontSize: 11, color: Colors.blueGrey[400])),
              Text('20条', style: TextStyle(fontSize: 11, color: Colors.blueGrey[400])),
              Text('25条', style: TextStyle(fontSize: 11, color: Colors.blueGrey[400])),
            ],
          ),
          const SizedBox(height: 16),

          // AI descriptions toggle
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD6E0EA)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.auto_awesome_outlined,
                    size: 20, color: Color(0xFF16324F)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'AI 生成景区介绍',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF16324F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        deepseekAvailable
                            ? '获取后调用 DeepSeek 为每个景区生成详细中文介绍（约需额外 1–2 分钟）'
                            : '需要先在 AI 推荐设置中配置 DeepSeek API Key',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blueGrey[500],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: config.useAiDescriptions && deepseekAvailable,
                  activeColor: const Color(0xFF16324F),
                  onChanged: deepseekAvailable
                      ? (bool v) =>
                          onChanged(config.copyWith(useAiDescriptions: v))
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fetch progress ────────────────────────────────────────────────────────────

class _FetchProgress extends StatelessWidget {
  const _FetchProgress({
    required this.done,
    required this.total,
    required this.phase,
    required this.cities,
  });

  final int done;
  final int total;
  final String phase;
  final List<String> cities;

  @override
  Widget build(BuildContext context) {
    final bool isAi = phase == 'ai';
    final String currentItem = isAi
        ? 'AI 描述生成中'
        : (done < cities.length ? cities[done] : '完成');

    final String phaseLabel = isAi ? '正在生成 AI 介绍' : '正在获取高德数据';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$phaseLabel  $currentItem… ($done/$total)',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? done / total : 0,
              minHeight: 6,
              backgroundColor: const Color(0xFFD6E0EA),
              color: isAi ? Colors.purple[400] : const Color(0xFF16324F),
            ),
          ),
          if (isAi) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              '高德数据已获取完成，正在为每个城市的景区生成 AI 介绍',
              style: TextStyle(fontSize: 11, color: Colors.blueGrey[500]),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.isConfigured,
    required this.cachedCount,
    required this.cacheDate,
  });

  final bool isConfigured;
  final int cachedCount;
  final DateTime? cacheDate;

  @override
  Widget build(BuildContext context) {
    final bool hasData = cachedCount > 0;
    final Color bg = hasData
        ? const Color(0xFFE8F5E9)
        : isConfigured
            ? const Color(0xFFFFF8E1)
            : const Color(0xFFF3F4F6);
    final Color border = hasData
        ? const Color(0xFFA5D6A7)
        : isConfigured
            ? const Color(0xFFFFE082)
            : const Color(0xFFD6E0EA);
    final Color textColor = hasData
        ? Colors.green.shade800
        : isConfigured
            ? Colors.orange.shade800
            : Colors.blueGrey.shade600;
    final IconData icon = hasData
        ? Icons.check_circle_outline
        : isConfigured
            ? Icons.cloud_download_outlined
            : Icons.info_outline;

    String message;
    if (hasData && cacheDate != null) {
      final String dateStr =
          '${cacheDate!.month}/${cacheDate!.day} '
          '${cacheDate!.hour}:${cacheDate!.minute.toString().padLeft(2, '0')}';
      message = '已加载 $cachedCount 个真实目的地（更新于 $dateStr）';
    } else if (isConfigured) {
      message = 'API Key 已保存，点击下方按钮获取目的地数据';
    } else {
      message = '未配置高德 API Key，当前使用内置演示数据（12 条）';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: textColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF16324F)),
    );
  }
}

class _HowToCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '如何获取高德 Web 服务 API Key',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF16324F)),
          ),
          const SizedBox(height: 10),
          _Step(n: '1', text: '访问 lbs.amap.com，注册个人开发者账号'),
          _Step(n: '2', text: '进入控制台 → 创建新应用'),
          _Step(n: '3', text: '添加 Key，服务类型选择「Web 服务」'),
          _Step(n: '4', text: '复制生成的 Key，粘贴到上方输入框'),
          const SizedBox(height: 8),
          Text(
            '个人开发者免费额度：每日 30 万次调用，完全满足课程项目需求。',
            style: TextStyle(
                fontSize: 12, color: Colors.blueGrey[500], height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text});
  final String n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: Color(0xFF16324F), shape: BoxShape.circle),
            child: Text(n,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.blueGrey[700],
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
