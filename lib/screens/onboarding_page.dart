import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/main_screen.dart';
import 'package:flutter_travel/services/deepseek_service.dart';
import 'package:flutter_travel/util/preference_service.dart';
import 'package:flutter_travel/util/travel_tags.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.isEditing = false});

  final bool isEditing;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final Set<String> _selectedTags = <String>{};
  String _budget = 'mid';
  bool _saving = false;

  static const Map<String, IconData> _tagIcons = <String, IconData>{
    TravelTags.nature: Icons.landscape_outlined,
    TravelTags.culture: Icons.museum_outlined,
    TravelTags.food: Icons.restaurant_outlined,
    TravelTags.city: Icons.location_city_outlined,
    TravelTags.family: Icons.park_outlined,
    TravelTags.budget: Icons.savings_outlined,
  };

  static const Map<String, String> _budgetLabels = <String, String>{
    'low': '省钱出行',
    'mid': '舒适均衡',
    'high': '品质享受',
  };

  static const Map<String, String> _budgetSubs = <String, String>{
    'low': '偏向高性价比路线',
    'mid': '兼顾体验与预算',
    'high': '更在意品质和服务',
  };

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadCurrentPrefs();
  }

  Future<void> _loadCurrentPrefs() async {
    final List<String> tags = await PreferenceService.getTags();
    final String budget = await PreferenceService.getBudget();
    if (mounted) {
      setState(() {
        _selectedTags.addAll(tags);
        _budget = budget;
      });
    }
  }

  Future<void> _save() async {
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少选择一个旅行偏好。'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    await PreferenceService.save(
      tags: _selectedTags.toList(),
      budget: _budget,
    );
    if (widget.isEditing) {
      await DeepSeekService.clearCache();
    }
    if (mounted) {
      if (widget.isEditing) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      appBar: widget.isEditing
          ? AppBar(
              title: const Text('编辑偏好'),
              elevation: 0,
              backgroundColor: const Color(0xFFF9FBFD),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!widget.isEditing) ...<Widget>[
                const Icon(
                  Icons.travel_explore,
                  size: 48,
                  color: Color(0xFF16324F),
                ),
                const SizedBox(height: 20),
                const Text(
                  '你更偏向哪种\n旅行风格？',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16324F),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose your interests so we can personalise your recommendations.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.blueGrey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
              ] else
                const SizedBox(height: 8),
              const Text(
                'Your Interests',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: PreferenceService.allTags.map((String tag) {
                  final bool selected = _selectedTags.contains(tag);
                  return _TagCard(
                    tag: tag,
                    icon: _tagIcons[tag] ?? Icons.label_outline,
                    isSelected: selected,
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),
              const Text(
                'Budget Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16324F),
                ),
              ),
              const SizedBox(height: 14),
              ..._budgetLabels.entries.map((MapEntry<String, String> entry) {
                final bool selected = _budget == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BudgetOption(
                    label: entry.value,
                    subtitle: _budgetSubs[entry.key]!,
                    isSelected: selected,
                    onTap: () => setState(() => _budget = entry.key),
                  ),
                );
              }),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16324F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.isEditing ? 'Save Preferences' : 'Get Started',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (!widget.isEditing) ...<Widget>[
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await PreferenceService.save(tags: <String>[], budget: 'mid');
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const MainScreen(),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Skip for now',
                      style: TextStyle(color: Colors.blueGrey[400]),
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
}

class _TagCard extends StatelessWidget {
  const _TagCard({
    required this.tag,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String tag;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: (MediaQuery.of(context).size.width - 60) / 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF16324F) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF16324F)
                : const Color(0xFFD6E0EA),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? <BoxShadow>[
                  const BoxShadow(
                    color: Color(0x3316324F),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: 22,
              color: isSelected ? Colors.white : const Color(0xFF16324F),
            ),
            const SizedBox(width: 10),
            Text(
              tag,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected ? Colors.white : const Color(0xFF16324F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetOption extends StatelessWidget {
  const _BudgetOption({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F1F8) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF16324F)
                : const Color(0xFFD6E0EA),
            width: 1.5,
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected
                          ? const Color(0xFF16324F)
                          : Colors.blueGrey[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF16324F),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
