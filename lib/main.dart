import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/login_page.dart';
import 'package:flutter_travel/screens/main_screen.dart';
import 'package:flutter_travel/screens/onboarding_page.dart';
import 'package:flutter_travel/util/const.dart';
import 'package:flutter_travel/util/preference_service.dart';
import 'package:flutter_travel/util/user_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool loggedIn = await UserSession.isLoggedIn;
  final bool setupDone =
      loggedIn ? await PreferenceService.isSetupDone : false;
  runApp(MyApp(startLoggedIn: loggedIn, setupDone: setupDone));
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.startLoggedIn,
    required this.setupDone,
  });

  final bool startLoggedIn;
  final bool setupDone;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget get _home {
    if (!widget.startLoggedIn) return const LoginPage();
    if (!widget.setupDone) return const OnboardingPage();
    return const MainScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: Constants.appName,
      theme: Constants.lightTheme,
      darkTheme: Constants.darkTheme,
      home: _home,
    );
  }
}
