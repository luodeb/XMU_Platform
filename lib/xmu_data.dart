import 'package:shared_preferences/shared_preferences.dart';

class MySetting {
  static Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  static String username="";
  static String password="";
}
