import 'package:flutter/material.dart';
import 'package:flutter_travel/services/api_key_service.dart';

class ApiSettingsPage extends StatefulWidget {
  const ApiSettingsPage({super.key});

  @override
  State<ApiSettingsPage> createState() => _ApiSettingsPageState();
}

class _ApiSettingsPageState extends State<ApiSettingsPage> {
  final TextEditingController _keyController = TextEditingController();
  bool _obscure = true;
  bool _loading = true;
  bool _saving = false;
  String _savedKey = '';

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadKey() async {
    final String key = await ApiKeyService.load();
    if (mounted) {
      setState(() {
        _savedKey = key;
        _keyController.text = key;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final String input = _keyController.text.trim();
    if (input.isEmpty) {
      _showSnack('Please enter your API key.', isError: true);
      return;
    }
    setState(() => _saving = true);
    await ApiKeyService.save(input);
    if (mounted) {
      setState(() {
        _savedKey = input;
        _saving = false;
      });
      _showSnack('API key saved successfully.');
    }
  }

  Future<void> _clear() async {
    await ApiKeyService.clear();
    if (mounted) {
      setState(() {
        _savedKey = '';
        _keyController.clear();
      });
      _showSnack('API key removed.');
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : const Color(0xFF16324F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isConfigured = _savedKey.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _StatusBanner(isConfigured: isConfigured),
            const SizedBox(height: 32),
            const Text(
              'DeepSeek API Key',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16324F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Used to generate personalized travel recommendations. '
              'Your key is stored on this device only and never shared.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blueGrey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _keyController,
              obscureText: _obscure,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'sk-xxxxxxxxxxxxxxxxxxxxxxxx',
                filled: true,
                fillColor: const Color(0xFFF6F8FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.blueGrey[400],
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16324F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
                if (isConfigured) ...<Widget>[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _clear,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[300]!),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Remove'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
            _HowToCard(),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isConfigured});

  final bool isConfigured;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConfigured
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConfigured
              ? const Color(0xFFA5D6A7)
              : const Color(0xFFFFE082),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isConfigured ? Icons.check_circle_outline : Icons.info_outline,
            color: isConfigured ? Colors.green[700] : Colors.orange[700],
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isConfigured
                  ? 'AI recommendations are active.'
                  : 'Enter your DeepSeek API key to enable AI recommendations.',
              style: TextStyle(
                color: isConfigured ? Colors.green[800] : Colors.orange[800],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
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
            'How to get your API key',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF16324F),
            ),
          ),
          const SizedBox(height: 10),
          _Step(number: '1', text: 'Visit platform.deepseek.com'),
          _Step(number: '2', text: 'Sign in and go to API Keys'),
          _Step(number: '3', text: 'Create a new key and copy it here'),
          const SizedBox(height: 8),
          Text(
            'New accounts receive free credits. No payment required to get started.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blueGrey[500],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
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
              color: Color(0xFF16324F),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blueGrey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
