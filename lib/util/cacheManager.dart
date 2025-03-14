import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
class CacheHelper {
  static Future<void> addEventList(String key, String eventList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$key-eventList', eventList);
  }

  static Future<String?> getEventList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('$key-eventList');
    return encodedData;
  }
  


  static Future<void> addSave(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    //print('adding to fav $key');
    await prefs.setString('$key-save', value);
  }
  static Future<String?> getSave(String key) async {
    final prefs = await SharedPreferences.getInstance();
    print('get fav $key');
    return prefs.getString('$key-save');
  }

  static Future<void> removeSave(String key) async {
    final prefs = await SharedPreferences.getInstance();
    //print('remove from fav $key');
    await prefs.remove('$key-save');
  }
  static Future<bool> existSave(String key) async {
    final prefs = await SharedPreferences.getInstance();
    //print('exist fav $key');
    return prefs.containsKey('$key-save');
  }

  static Future<void> setLastUpdate(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    //print('adding to fav $key');
    await prefs.setInt('$key-lastUpdate', value);
  }
  static Future<int?> getLastUpdate(String key) async {
    final prefs = await SharedPreferences.getInstance();
    //print('get fav $key');
    return prefs.getInt('$key-lastUpdate') ?? 0 ;
  }

  static Future<void> removeLastUpdate(String key) async {
    final prefs = await SharedPreferences.getInstance();
    //print('remove from fav $key');
    await prefs.remove('$key-lastUpdate');
  }
  static Future<bool> existLastUpdate(String key) async {
    final prefs = await SharedPreferences.getInstance();
    //print('exist fav $key');
    return prefs.containsKey('$key-lastUpdate');
  }
  static Future<void> addToCustom(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$key-custom', value);
  }

  static Future<String?> getFromCustom(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$key-custom');
  }

  static Future<void> removeFromCustom(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$key-custom');
  }

  static Future<bool> existCustom(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$key-custom');
  }

  static Future<List<Map<String, dynamic>>> getAllFromCustom() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final List<Map<String, dynamic>> allCustoms = [];

    for (String key in keys) {
      if (key.endsWith('-custom')) {
        final value = prefs.getString(key);
        if (value != null) {
          try {
            // Ensure the value is a valid JSON string
            if (value.startsWith('{') && value.endsWith('}')) {
              value.replaceAll("\n", "");
              final Map<String, dynamic> customMap = Map<String, dynamic>.from(jsonDecode(value));
              allCustoms.add(customMap);
            } else {
              print('Invalid JSON format for key $key');
            }
          } catch (e) {
            // Handle the error if the value is not a valid JSON string
            print('Error decoding JSON for key $key: $e');
          }
        }
      }
    }
    return allCustoms;
  }
  static Future<void> addToFav(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    //print('adding to fav $key');
    await prefs.setString('$key-fav', value);
  }
  static Future<String?> getFromFav(String key) async {
    final prefs = await SharedPreferences.getInstance();
    //print('get fav $key');
    return prefs.getString('$key-fav');
  }

  static Future<void> removeFromFav(String key) async {
    final prefs = await SharedPreferences.getInstance();
    //print('remove from fav $key');
    await prefs.remove('$key-fav');
  }
  static Future<bool> existFav(String key) async {
    final prefs = await SharedPreferences.getInstance();
    //print('exist fav $key');
    return prefs.containsKey('$key-fav');
  }
  static Future<List<Map<String, dynamic>>> getAllFromFav() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final List<Map<String, dynamic>> allFavs = [];

    for (String key in keys) {
      if (key.endsWith('-fav')) {
        final value = prefs.getString(key);
        if (value != null) {
          try {
              print((value));
            // Ensure the value is a valid JSON string
            if (value.startsWith('{') && value.endsWith('}')) {
              value.replaceAll("\n", "");
              final Map<String, dynamic> favMap = Map<String, dynamic>.from(jsonDecode(value));
              allFavs.add(favMap);
            } else {
              print('Invalid JSON format for key $key');
            }
          } catch (e) {
            // Handle the error if the value is not a valid JSON string
            print('Error decoding JSON for key $key: $e');
          }
        }
      }
    }
    return allFavs;
  }
  static Future<void> setDarkModeEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  static Future<bool?> isDarkModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('darkMode') ?? false;
  }

  static Future<void> setNotificationDelay(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notificationDelay', value);
  }

  static Future<int?> getNotificationDelay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('notificationDelay') ?? 7;
  }

  static Future<void> setStartTime(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('startTime', value);
  }

  static Future<int?> getStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('startTime') ?? 7;
  }

  static Future<void> setEndTime(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('endTime', value);
  }

  static Future<int?> getEndTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('endTime') ?? 23;
  }

  static Future<void> setRequestPerMinute(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('requestPerMinute', value);
  }

  static Future<int?> getRequestPerMinute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('requestPerMinute') ?? 15;
  }
  

  static Future<int?> getWebLaunchCount() async {

    // Implement the logic to get the web launch count from cache

    // For example, using SharedPreferences:

    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt('webLaunchCount');

  }




  static Future<void> setWebLaunchCount(int count) async {

    // Implement the logic to set the web launch count in cache

    // For example, using SharedPreferences:

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('webLaunchCount', count);

  }

}
