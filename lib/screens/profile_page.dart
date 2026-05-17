import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/amap_settings_page.dart';
import 'package:flutter_travel/screens/api_settings_page.dart';
import 'package:flutter_travel/screens/login_page.dart';
import 'package:flutter_travel/screens/onboarding_page.dart';
import 'package:flutter_travel/services/amap_key_service.dart';
import 'package:flutter_travel/services/api_key_service.dart';
import 'package:flutter_travel/util/preference_service.dart';
import 'package:flutter_travel/util/user_session.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _phone = '';
  String _provider = '';
  List<String> _preferredTags = <String>[];
  bool _aiConfigured = false;
  bool _amapConfigured = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final Map<String, String>? session = await UserSession.load();
    final List<String> tags = await PreferenceService.getTags();
    final bool aiOk = await ApiKeyService.isConfigured;
    final bool amapOk = await AmapKeyService.isConfigured;
    if (mounted) {
      setState(() {
        _phone = session?['phone'] ?? '';
        _provider = session?['provider'] ?? 'Phone';
        _preferredTags = tags;
        _aiConfigured = aiOk;
        _amapConfigured = amapOk;
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await UserSession.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  Future<void> _openAiSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ApiSettingsPage()),
    );
    final bool aiOk = await ApiKeyService.isConfigured;
    if (mounted) setState(() => _aiConfigured = aiOk);
  }

  Future<void> _openAmapSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AmapSettingsPage()),
    );
    final bool amapOk = await AmapKeyService.isConfigured;
    if (mounted) setState(() => _amapConfigured = amapOk);
  }

  Future<void> _openPreferences() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OnboardingPage(isEditing: true),
      ),
    );
    final List<String> tags = await PreferenceService.getTags();
    if (mounted) setState(() => _preferredTags = tags);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isSocialLogin = _phone.isEmpty;
    final String displayName =
        isSocialLogin ? '$_provider Account' : _phone;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 52,
              backgroundColor: const Color(0xFF16324F),
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16324F),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1F8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Signed in via $_provider',
                style: const TextStyle(
                  color: Color(0xFF16324F),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Account info
            _SectionCard(
              children: <Widget>[
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: _phone.isEmpty ? 'Not provided' : _phone,
                ),
                const Divider(height: 1),
                _InfoRow(
                  icon: Icons.login_outlined,
                  label: 'Login method',
                  value: _provider,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Travel preferences
            _SectionCard(
              children: <Widget>[
                _TappableRow(
                  icon: Icons.favorite_border,
                  label: 'Travel Interests',
                  onTap: _openPreferences,
                  trailing: _preferredTags.isEmpty
                      ? Text(
                          'Not set',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : null,
                ),
                if (_preferredTags.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _preferredTags
                          .map(
                            (String tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F1F8),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF16324F),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Map data settings
            _SectionCard(
              children: <Widget>[
                _TappableRow(
                  icon: Icons.map_outlined,
                  label: '高德地图数据',
                  onTap: _openAmapSettings,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _amapConfigured
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _amapConfigured ? '已配置' : '未配置',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _amapConfigured
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // AI settings
            _SectionCard(
              children: <Widget>[
                _TappableRow(
                  icon: Icons.auto_awesome_outlined,
                  label: 'AI Recommendations',
                  onTap: _openAiSettings,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _aiConfigured
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _aiConfigured ? 'Active' : 'Not set',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _aiConfigured
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[300]!),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: <Widget>[
          Icon(icon, color: const Color(0xFF16324F), size: 22),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(color: Colors.blueGrey[600], fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF16324F),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _TappableRow extends StatelessWidget {
  const _TappableRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(icon, color: const Color(0xFF16324F), size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(color: Colors.blueGrey[600], fontSize: 14),
            ),
            const Spacer(),
            if (trailing != null) trailing!,
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.blueGrey[300], size: 20),
          ],
        ),
      ),
    );
  }
}
