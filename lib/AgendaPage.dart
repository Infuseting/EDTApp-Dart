import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'util/cacheManager.dart';
import 'util/darkMode.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
class Pair<T, U> {
  final T first;
  final U second;

  Pair(this.first, this.second);
}

class AgendaPage extends StatefulWidget {
  final int adeProjectID;
  final int adeResources;

  const AgendaPage({
    Key? key,
    required this.adeProjectID,
    required this.adeResources,
  }) : super(key: key);

  @override
  @override
  _AgendaPageState createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  late bool isDarkMode;
  late dynamic save;
  late int lastUpdate;
  late Color primaryColor;
  late Color secondaryColor;
  late String key = '${widget.adeProjectID}-${widget.adeResources}';
  @override
  void initState() {
    _loadSettings();
  }
  
  
  Future<void> _loadSettings() async {
    final settings = await Future.wait([
      CacheHelper.isDarkModeEnabled(),
      CacheHelper.getSave(key),
      CacheHelper.getLastUpdate(key),
      ThemeManager().getPrimaryColor(),
      ThemeManager().getSecondaryColor(),
    ]);

    setState(() {
      isDarkMode = settings[0] as bool;
      save = json.decode(settings[1] as String) as dynamic;
      lastUpdate = settings[2] as int;
      primaryColor = settings[3] as Color;
      secondaryColor = settings[4] as Color;
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String lastUpdateString = formatDateFromTimeStamp(lastUpdate);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondaryColor,
        title: Text(
          
          'Agenda | ${lastUpdateString}',
          style: TextStyle(color: primaryColor),
          maxLines: 2,
        ),
        iconTheme: IconThemeData(
          color: primaryColor, // Change the back button color here
        ),
        actions: [
          if (widget.adeProjectID == 2023 || widget.adeProjectID == 2024) 
            IconButton(
              icon: const Icon(Icons.link),
              color: primaryColor,
              onPressed: () {
            String edtLink;
            edtLink = "https://edt.infuseting.fr/update/myEDT.php?adeBase=${widget.adeProjectID}&adeRessources=${widget.adeResources}";
            
          Clipboard.setData(ClipboardData(text: edtLink));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fichier Agenda copié')),
          );
              },
            ),
        ],
      ),
      body: Container(
        color: primaryColor,
        child: Row(children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(30, (i) {
                  final currentDay = now.add(Duration(days: i));
                  String format = DateFormat('yyyy-MM-dd').format(currentDay);
                  var dayEvents = save[format];
                  if (dayEvents != null && dayEvents.isNotEmpty && dayEvents['content'].isNotEmpty) {
                    // compute Paris offset (UTC -> Europe/Paris), taking DST into account
                    int lastSundayOfMonth(int year, int month) {
                      DateTime firstDayNextMonth = DateTime(year, month + 1, 1);
                      DateTime lastDay = firstDayNextMonth.subtract(Duration(days: 1));
                      int weekday = lastDay.weekday; // Mon=1 .. Sun=7
                      int daysToSunday = weekday % 7;
                      return lastDay.day - daysToSunday;
                    }

                    int parisUtcOffsetHours(DateTime date) {
                      final int year = date.year;
                      final DateTime dstStart = DateTime(year, 3, lastSundayOfMonth(year, 3)); // last Sunday of March
                      final DateTime dstEnd = DateTime(year, 10, lastSundayOfMonth(year, 10)); // last Sunday of October
                      // DST is active from the last Sunday of March (inclusive) to the last Sunday of October (exclusive)
                      if (!date.isBefore(dstStart) && date.isBefore(dstEnd)) {
                        return 2; // CEST (UTC+2)
                      }
                      return 1; // CET (UTC+1)
                    }

                    final int parisOffset = parisUtcOffsetHours(currentDay);
                    // timeLast = midnight at UTC then shifted to Paris local midnight
                    DateTime timeLast = DateTime.utc(currentDay.year, currentDay.month, currentDay.day, 6, 0, 0)
                        .add(Duration(hours: parisOffset));
                    String dayName = DateFormat('EEEE').format(currentDay);
                    const dayNames = {
                      'Monday': 'Lundi',
                      'Tuesday': 'Mardi',
                      'Wednesday': 'Mercredi',
                      'Thursday': 'Jeudi',
                      'Friday': 'Vendredi',
                      'Saturday': 'Samedi',
                      'Sunday': 'Dimanche'
                    };
                    dayName = dayNames[dayName] ?? dayName;
                    String formattedDate = DateFormat('d/M/yyyy').format(currentDay);
                    return Container( 
                      constraints: BoxConstraints(
                        minWidth: 1920 / 5,
                      ),
                      width: MediaQuery.of(context).size.width / 5,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: secondaryColor,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                      children: [
                        Container(
                          color: Colors.amber,
                          height: 71,
                          padding: EdgeInsets.all(8.0),
                          width: double.infinity,
                          child: Column(
                            children: [
                              Text(
                                i == 0 ? "Aujourd'hui" : dayName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formattedDate,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Container(
                          color: primaryColor,
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 73,
                          ),
                          child: Column(
                          children: dayEvents['content'].map<Widget>((event) {
                            Pair<Color, Color> colorPair = colorChooser(event, widget.adeProjectID);
                            Color colorFirst = colorPair.first;
                            Color colorScnd = colorPair.second;
                            double calculatedHeight = heightCalc(event, widget.adeProjectID);

                            var results = topCalc(widget.adeProjectID, event, timeLast);
                            timeLast = results[1];
                            double topPadding = results[0];
                            return Padding(
                            padding: EdgeInsets.only(top: topPadding > 0 ? topPadding : 0),
                            child: GestureDetector(
                              onTap: () {
                              setState(() {
                                if (event['expanded'] == null) {
                                event['expanded'] = false;
                                }
                                event['expanded'] = !event['expanded'];
                              });
                              },
                                child: Container(
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                  color: colorFirst,
                                  border: Border.all(
                                    color: secondaryColor,
                                    width: 1.0,
                                  ),  
                                ),
                                
                                height: event['expanded'] == true ? 200 : calculatedHeight,
                                child: Column(
                                  children: [
                                  Text(
                                    event["SUMMARY"] ?? "",
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                    color: colorScnd,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    event["LOCATION"] ?? "",
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                    color: colorScnd,
                                    fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "${parseTimeToString(event["DTSTART"] ?? "", widget.adeProjectID)} - ${parseTimeToString(event["DTEND"] ?? "", widget.adeProjectID)}",
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                    color: colorScnd,
                                    fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    event["DESCRIPTION"]?.replaceAll("\\n", "") ?? "",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                    color: colorScnd,
                                    fontSize: 14,
                                    ),
                                    overflow: TextOverflow.clip,
                                  ),
                                  ],
                                ),
                        
                                ),
                          
                              ),
                            );
                            
                          }).toList(),
                          ),
                        ),
                        
                      ],
                    ));
                  }
                  return Container(
                    width: 0,
                    height: 0,
                    color: Colors.transparent,
                  );
                }),
              ),
            ),
            ),
          )
      ],) 
                
        ,
        )
      );
    
  }

  String formatDateFromTimeStamp(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

    DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    String formattedDate = dateFormat.format(dateTime);

    return formattedDate;
  }

  Pair<Color, Color> colorChooser(dynamic element, int adeId) {
    int currentTimeStamp = getCurrentTimestamp();
    String endClass = element["DTEND"];
    if (compareTimestamps(currentTimeStamp, endClass, adeId) > 0) {
      return Pair(Color(0xFFA9A9A9), Colors.black);
    }
    if (element["SUMMARY"].toString().contains("SAÉ")) {
      return Pair(Color(0xFFE9169B), Colors.white);
    } else if (element["SUMMARY"].toString().contains(" CC") ||
           element["SUMMARY"].toString().contains(" CTP") ||
           element["SUMMARY"].toString().contains(" CTD")) {
      return Pair(Color(0xFFFF6347), Colors.white);
    } else if (element["SUMMARY"].toString().contains(" TP")) {
      return Pair(Color(0xFF32CD32), Colors.white);
    } else if (element["SUMMARY"].toString().contains(" TD")) {
      return Pair(Color(0xFF1E90FF), Colors.white);
    } else if (element["SUMMARY"].toString().contains(" CM")) {
      return Pair(Color(0xFFFFD700), Colors.black);
    } else if (element["DESCRIPTION"].toString().contains("SAÉ")) {
      return Pair(Color(0xFFE9169B), Colors.white);
    } else if (element["DESCRIPTION"].toString().contains(" CC") ||
           element["DESCRIPTION"].toString().contains(" CTP") ||
           element["DESCRIPTION"].toString().contains(" CTD")) {
      return Pair(Color(0xFFFF6347), Colors.white);
    } else if (element["DESCRIPTION"].toString().contains(" TP")) {
      return Pair(Color(0xFF32CD32), Colors.white);
    } else if (element["DESCRIPTION"].toString().contains(" TD")) {
      return Pair(Color(0xFF1E90FF), Colors.white);
    } else if (element["DESCRIPTION"].toString().contains(" CM")) {
      return Pair(Color(0xFFFFD700), Colors.black);
    } else {
      return Pair(Color(0xFF00CED1), Colors.black);
    }
  }

  int getCurrentTimestamp() {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    return timestamp;
  }
  DateTime parseTimestampRQST(String timestamp, int adeId) {
    // Remove the 'Z' at the end to avoid issues with the format parser.
    timestamp = timestamp.replaceAll('Z', '').replaceAll('T', '');
    final formatter = DateFormat("yyyy-MM-dd HH:mm:ss");
    String year = timestamp.substring(0, 4);
    String month = timestamp.substring(4, 6);
    String day = timestamp.substring(6, 8);
    String hour = (int.parse(timestamp.substring(8, 10))).toString();
    String minute = timestamp.substring(10, 12);
    String second = timestamp.substring(12, 14);
    return formatter.parse("$year-$month-$day $hour:$minute:$second");
  }



  DateTime parseTimestampISO(String timestamp) {
    return DateFormat("yyyy-MM-dd HH:mm:ss").parse(timestamp);
  }
  
  int compareTimestamps(int timestamp1, String timestamp2, int adeId) {
    DateTime time1 = DateTime.fromMillisecondsSinceEpoch(timestamp1);
    DateTime time2 = parseTimestampRQST(timestamp2, adeId);
    return time1.compareTo(time2);
  }

  double heightCalc(dynamic event, int adeId) {
    DateTime startTime = DateFormat("HH:mm").parse(parseTime(event["DTSTART"]!, adeId));
    DateTime endTime = DateFormat("HH:mm").parse(parseTime(event["DTEND"]!, adeId));
    int duration = endTime.difference(startTime).inMinutes;
    return duration.toDouble();
  }

  List<dynamic> topCalc(int adeId, dynamic event, DateTime lastEndTime) {
    //print("Calculating top padding for event: $event with last end time: $lastEndTime");
    DateTime startTime = DateFormat("HH:mm").parse(parseTime(event["DTSTART"]!, adeId));
    print("Start time: $startTime");
    DateTime endTime = DateFormat("HH:mm").parse(parseTime(event["DTEND"]!, adeId));
    print("End time: $endTime");
    
    DateTime adjustedStartTime = startTime.subtract(
      Duration(hours: 8),
    );
    print("Adjusted Start time : $adjustedStartTime");
    print("lastEndTime : $lastEndTime");
    DateTime adjustedLastEndTime = lastEndTime.subtract(
      Duration(hours: 8),
    );
    print("Adjusted End Time : $adjustedLastEndTime");
    
    int startMinutes = adjustedStartTime.hour * 60 + adjustedStartTime.minute;
    int lastEndMinutes = adjustedLastEndTime.hour * 60 + adjustedLastEndTime.minute;
    print("Start Minutes: $startMinutes, Last End Minutes: $lastEndMinutes");

    
    double topPadding = startMinutes.toDouble();
    double diffEndStart = lastEndMinutes.toDouble();
    print("Top Padding: $topPadding, Diff End Start: $diffEndStart");
    print("Calculated Top Padding: ${topPadding - diffEndStart}");
    
    DateTime newLastEndTime = parseTimestampRQST(event["DTEND"]!, adeId);
    
    return [topPadding - diffEndStart, newLastEndTime];
  }

  String parseTime(String times, int adeId) {
    final parsedTime = parseTimestampRQST(times, adeId);
    final outputFormatter = DateFormat("HH:mm");
    var adjustedTime = parsedTime;

    return outputFormatter.format(adjustedTime);
  }
  String parseTimeToString(String times, int adeId) {
    final parsedTime = parseTimestampRQST(times, adeId);
    final outputFormatter = DateFormat("HH:mm");

    var adjustedTime = parsedTime;
    

    return outputFormatter.format(adjustedTime);
  }
}