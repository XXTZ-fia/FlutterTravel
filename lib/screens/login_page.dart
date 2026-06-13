import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/main_screen.dart';
import 'package:flutter_travel/services/local_auth_service.dart';
import 'package:flutter_travel/util/const.dart';
import 'package:flutter_travel/util/user_session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _secretController = TextEditingController();
  String? _phoneError;
  String? _secretError;
  bool _isRegisterMode = false;
  bool _submitting = false;

  static final RegExp _phoneRegExp = RegExp(r'^\+?[0-9]{7,15}$');

  @override
  void dispose() {
    _phoneController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String phone = _phoneController.text.trim();
    final String password = _secretController.text.trim();
    if (!_phoneRegExp.hasMatch(phone)) {
      setState(() {
        _phoneError = '请输入正确的手机号（7 到 15 位数字）。';
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _phoneError = null;
        _secretError = '密码至少需要 6 位。';
      });
      return;
    }

    setState(() {
      _phoneError = null;
      _secretError = null;
      _submitting = true;
    });

    final bool success = _isRegisterMode
        ? await LocalAuthService.register(phone: phone, password: password)
        : await LocalAuthService.login(phone: phone, password: password);

    if (!mounted) return;
    if (!success) {
      setState(() {
        _submitting = false;
        _secretError = _isRegisterMode ? '该手机号已经注册。' : '手机号或密码不正确。';
      });
      return;
    }

    await UserSession.save(phone, '本地账号');
    if (!mounted) return;
    setState(() => _submitting = false);
    _navigateToMain();
  }

  void _navigateToMain() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const MainScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFE8F1F8),
              Color(0xFFF9FBFD),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x1A1D3557),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        Icons.travel_explore,
                        size: 44,
                        color: Color(0xFF16324F),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        Constants.appName,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16324F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegisterMode
                            ? '注册一个本地账号后，每个账号的行程、喜欢和偏好都会独立保存。'
                            : '登录本地账号后，就可以继续你的专属旅行计划。',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.blueGrey[700],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: SegmentedButton<bool>(
                              segments: const <ButtonSegment<bool>>[
                                ButtonSegment<bool>(
                                  value: false,
                                  label: Text('登录'),
                                  icon: Icon(Icons.login_outlined),
                                ),
                                ButtonSegment<bool>(
                                  value: true,
                                  label: Text('注册'),
                                  icon: Icon(Icons.person_add_alt_1_outlined),
                                ),
                              ],
                              selected: <bool>{_isRegisterMode},
                              onSelectionChanged: (Set<bool> selection) {
                                FocusScope.of(context).unfocus();
                                setState(() {
                                  _isRegisterMode = selection.first;
                                  _phoneError = null;
                                  _secretError = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) {
                          if (_phoneError != null || _secretError != null) {
                            setState(() {
                              _phoneError = null;
                              _secretError = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: '手机号',
                          hintText: '请输入手机号',
                          errorText: _phoneError,
                          filled: true,
                          fillColor: const Color(0xFFF6F8FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.0),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.0),
                            borderSide: _phoneError != null
                                ? const BorderSide(color: Colors.red)
                                : BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _secretController,
                        obscureText: true,
                        onChanged: (_) {
                          if (_secretError != null) {
                            setState(() => _secretError = null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: '密码',
                          hintText: _isRegisterMode ? '设置一个至少 6 位的密码' : '请输入密码',
                          errorText: _secretError,
                          filled: true,
                          fillColor: const Color(0xFFF6F8FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF16324F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isRegisterMode ? '注册并进入' : '登录'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _isRegisterMode
                            ? '账号密码将只保存在当前设备本地，不会和其他账号互通。'
                            : '没有账号的话，切换到上方“注册”即可创建新账号。',
                        style: TextStyle(
                          color: Colors.blueGrey[600],
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
