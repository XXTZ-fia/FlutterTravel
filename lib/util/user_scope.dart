import 'package:flutter_travel/util/user_session.dart';

class UserScope {
  static Future<String> key(String base) async {
    final String userId = await UserSession.currentUserId();
    return '$base::$userId';
  }
}
