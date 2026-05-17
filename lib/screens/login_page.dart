import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/main_screen.dart';
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

  static final RegExp _phoneRegExp = RegExp(r'^\+?[0-9]{7,15}$');

  @override
  void dispose() {
    _phoneController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  Future<void> _loginWithPhone() async {
    final String phone = _phoneController.text.trim();
    if (!_phoneRegExp.hasMatch(phone)) {
      setState(() {
        _phoneError = 'Please enter a valid phone number (7–15 digits).';
      });
      return;
    }
    setState(() => _phoneError = null);
    await UserSession.save(phone, 'Phone');
    _navigateToMain();
  }

  Future<void> _loginWithSocial(String provider) async {
    await UserSession.save('', provider);
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
                        'Sign in to start planning your next trip offline.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.blueGrey[700],
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) {
                          if (_phoneError != null) {
                            setState(() => _phoneError = null);
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter your phone number',
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
                        decoration: InputDecoration(
                          labelText: 'Password or Verification Code',
                          hintText: 'Enter your password or code',
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
                          onPressed: _loginWithPhone,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF16324F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                          child: const Text('Login'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Divider(color: Colors.blueGrey[100]),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              'Or continue with',
                              style: TextStyle(
                                color: Colors.blueGrey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: Colors.blueGrey[100]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SocialLoginButton(
                        label: 'Continue with Google',
                        icon: Icons.g_mobiledata,
                        onPressed: () => _loginWithSocial('Google'),
                      ),
                      const SizedBox(height: 12),
                      _SocialLoginButton(
                        label: 'Continue with Facebook',
                        icon: Icons.facebook,
                        onPressed: () => _loginWithSocial('Facebook'),
                      ),
                      const SizedBox(height: 12),
                      _SocialLoginButton(
                        label: 'Continue with Apple',
                        icon: Icons.apple,
                        onPressed: () => _loginWithSocial('Apple'),
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

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF16324F),
          side: const BorderSide(color: Color(0xFFD6E0EA)),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
        ),
      ),
    );
  }
}
