import 'package:flutter/material.dart';
import 'package:universal_html/js.dart' as js;
import 'package:url_launcher/url_launcher.dart';
import 'util/cacheManager.dart';
import 'util/darkMode.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool isDarkMode;
  late int notificationDelay;
  late int startTime;
  late int endTime;
  late int requestPerMinute;
  late Color primaryColor;
  late Color secondaryColor;
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await Future.wait([
      CacheHelper.isDarkModeEnabled(),
      CacheHelper.getNotificationDelay(),
      CacheHelper.getStartTime(),
      CacheHelper.getEndTime(),
      CacheHelper.getRequestPerMinute(),
      ThemeManager().getPrimaryColor(),
      ThemeManager().getSecondaryColor(),
    ]);

    setState(() {
      isDarkMode = settings[0] as bool;
      notificationDelay = settings[1] as int;
      startTime = settings[2] as int;
      endTime = settings[3] as int;
      requestPerMinute = settings[4] as int;
      primaryColor = settings[5] as Color;
      secondaryColor = settings[6] as Color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings | Version : ' + js.context.callMethod('getVersion'),
          style: TextStyle(color: primaryColor),
        ),
        backgroundColor: secondaryColor,
        iconTheme: IconThemeData(
          color: primaryColor, // Change the back button color here
        ),
      ),
      body: Container(
        color: primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isDarkMode == null ||
                  notificationDelay == null ||
                  startTime == null ||
                  endTime == null ||
                  requestPerMinute == null
              ? Center(child: CircularProgressIndicator())
              : Column(
                  children: <Widget>[
                    Expanded(
                      child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                          Text('Dark Mode',
                            style: TextStyle(color: secondaryColor)),
                          Switch(
                            value: isDarkMode,
                            onChanged: (bool value) {
                            setState(() {
                              isDarkMode = value;
                            });
                            CacheHelper.setDarkModeEnabled(value);
                            // Reload the page to apply the dark mode change
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsPage()),
                            );
                            },
                          ),
                          ],
                        ),
                        SizedBox(height: 8.0),
                        Divider(color: secondaryColor),
                        SizedBox(height: 8.0),
                        Text('Notification Delay (days)',
                          style: TextStyle(color: secondaryColor)),
                        Container(
                          child: Slider(
                          value: notificationDelay.toDouble(),
                          inactiveColor: secondaryColor,
                          onChanged: (double value) {
                            setState(() {
                            notificationDelay = value.toInt();
                            });

                            CacheHelper.setNotificationDelay(value.toInt());
                          },
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '${notificationDelay} days',
                          ),
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          'Maximum: ${notificationDelay} day(s)\nThis parameter corresponds to the maximum number of days you can receive a notification in case of a course change.',
                          style: TextStyle(color: secondaryColor),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.0),
                        Divider(color: secondaryColor),
                        SizedBox(height: 8.0),
                        Text(
                          'Define Start and End time for notifications',
                          style: TextStyle(color: secondaryColor),
                        ),
                        Text(
                          'Average data consumption per month : ${(31.0 * ((endTime - startTime) / (requestPerMinute / 60.0))).toInt()}KB',
                          style: TextStyle(color: secondaryColor),
                        ),
                        Text(
                          'Information will be based on you\'re parameter and can be different from the real data consumption (it\'s an minimum estimation)',
                          style: TextStyle(color: secondaryColor),
                        ),
                        Container(
                          child: RangeSlider(
                          values: RangeValues(
                            startTime.toDouble(),
                            endTime.toDouble(),
                          ),
                          onChanged: (RangeValues values) {
                            setState(() {
                            startTime = values.start.toInt();
                            endTime = values.end.toInt();
                            });
                            CacheHelper.setStartTime(values.start.toInt());
                            CacheHelper.setEndTime(values.end.toInt());
                          },
                          min: 0,
                          max: 24,
                          divisions: 24,
                          labels: RangeLabels(
                            '${startTime} h',
                            '${endTime} h',
                          ),
                          inactiveColor:
                            secondaryColor, // Change the inactive color of the slider
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Divider(color: secondaryColor),
                        SizedBox(height: 8.0),
                        Text('Time between two requests in minutes',
                          style: TextStyle(color: secondaryColor)),
                        
                        Container(
                          child: Slider(
                          value: requestPerMinute.toDouble(),
                          onChanged: (double value) {
                            setState(() {
                            requestPerMinute = value.toInt();
                            });
                            CacheHelper.setRequestPerMinute(value.toInt());
                          },
                          min: 1,
                          max: 240,
                          divisions: 16,
                          label: '${requestPerMinute} minutes',
                          inactiveColor: secondaryColor,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Divider(color: secondaryColor),
                        SizedBox(height: 8.0),
                        GestureDetector(
                          onTap: () {
                          launch('https://infuseting.fr');
                          },
                          child: Text(
                          'Visit infuseting.fr',
                          style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        SizedBox(height: 8.0),
                        GestureDetector(
                          onTap: () {
                          launch('https://antoninhuaut.fr/');
                          },
                          child: Text(
                          'Thanks to Antonin Huaut for their help',
                          style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        SizedBox(height: 8.0),
                        GestureDetector(
                          onTap: ()  {
                            js.context.callMethod("launchApp");
                          },
                          child: Text(
                          'Install Shortcut',
                          style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        SizedBox(height: 8.0),
                  
                        ],
                      ),
                      ),
                    ),
                  ],

      ),
    ),
    ));

  }
}
