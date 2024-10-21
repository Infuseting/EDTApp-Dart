import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'util/cacheManager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:universal_html/js.dart' as js;
import 'SettingsPage.dart';
import 'util/darkMode.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'AgendaPage.dart';
Future<void> checkUpdate(int adeProjectID, int adeResources) async {
  try {
    String key = "$adeProjectID-$adeResources";
    int? lastUpdate = await CacheHelper.getLastUpdate(key);
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    print('$baseUrl/update/?adeBase=$adeProjectID&adeRessources=$adeResources&lastUpdate=$lastUpdate&date=$date');
    final result = await http.get(Uri.parse('$baseUrl/update/?adeBase=$adeProjectID&adeRessources=$adeResources&lastUpdate=$lastUpdate&date=$date'));
    if (result.statusCode == 200) {
      final jsonResponse = json.decode(utf8.decode(result.bodyBytes));
      print(result.body);
      dynamic jsonFile;
      String? save =  await CacheHelper.getSave(key);

      if (save != null) {
        jsonFile = json.decode(save);
        if (!jsonResponse.isEmpty) {
            jsonResponse.forEach((key, value) {
              DateTime dateKey = DateTime.parse(key);
              if (dateKey.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
                jsonFile.remove(key);
              } else {
                jsonFile[key] = value;
              }
            });
        }
        
          
      }
      else {
        jsonFile = jsonResponse;
      }
      await CacheHelper.addSave(key, jsonEncode(jsonFile)); 
      await CacheHelper.setLastUpdate(key, DateTime.now().millisecondsSinceEpoch);

      
      
    }
    else {
      print('Failed to load data $result.statusCode');
    }
    
  } catch (_) {
    print('Failed to load data $_');
  }
}
Future<bool> hasInternetConnection() async {
  try {
    final result = await http.get(Uri.parse('https://edt.infuseting.fr'));
    return result.statusCode == 200;
  } catch (_) {
    return false;
  }
}
String jsonBaseUrl = '$baseUrl/assets/json/';
Future<String> md5calc(String input) async {
  return md5.convert(utf8.encode(await CacheHelper.getEventList(input) ?? '')).toString();
}
Future<Map<String, dynamic>> fetchJsonData(String url) async {
  final getMD5 = await http.get(Uri.parse('$jsonBaseUrl?fileName=$url'));
  if (getMD5.statusCode == 200) {
    String md5Server = json.decode(getMD5.body)['hash'];
    String md5Local = await md5calc(url);
    print("MD5 Comparator for $url : " + md5Server + " " + md5Local); 
    if (md5Server != md5Local) {
      final response = await http.get(Uri.parse('$jsonBaseUrl$url'));
      if (response.statusCode == 200) {
        String local = await CacheHelper.getEventList(url) ?? '';
        print("MD5 Comparator Local for $url : " + local);
        print("MD5 Comparator Server for $url : " + utf8.decode(response.bodyBytes));
        CacheHelper.addEventList(url, utf8.decode(response.bodyBytes));
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to load data');
      }
    }
    String? eventList = await CacheHelper.getEventList(url);
    if (eventList != null) {
      return json.decode(eventList);
    } else {
      throw Exception('Failed to load data');
    }
  }
  else {
    throw Exception('Failed to load data');
  }
  
}

void main() {

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      title: 'Unicaen - EDT',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Unicaen - EDT'),

    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
String baseUrl = "https://edt.infuseting.fr";
class _MyHomePageState extends State<MyHomePage> {
  
  late bool isDarkMode;
  late String searchText = '';
  late Color primaryColor;

  late Color secondaryColor;
  List<dynamic> salleData = [];
  List<dynamic> profData = [];
  List<dynamic> univData = [];

  @override
  void initState() {
    super.initState();
    fetchJsonData('salle.json').then((data) {
      setState(() {
        salleData = data['salle'];
      });
    });
    fetchJsonData('prof.json').then((data) {
      setState(() {
        profData = data['prof'];
      });
    });
    fetchJsonData('univ.json').then((data) {
      setState(() {
        univData = data['univ'];
      });
    });
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await Future.wait([
      CacheHelper.isDarkModeEnabled(),
      ThemeManager().getPrimaryColor(),
      ThemeManager().getSecondaryColor(),
    ]);

    setState(() {
      isDarkMode = settings[0] as bool;
      primaryColor = settings[1] as Color;
      secondaryColor = settings[2] as Color;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: secondaryColor,
        centerTitle: true,
        title: Text(
          widget.title,
          style: TextStyle(color: primaryColor),
        ),
        leading: IconButton(
          icon: const Icon(Icons.settings),
          color: primaryColor,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
            _loadSettings(); // Reload settings when returning from SettingsPage
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.web),
            color: primaryColor,
            onPressed: () {
              launchUrl(Uri.parse('https://infuseting.fr/'), mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: 500,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Recherche',
                          hintStyle: TextStyle(color: secondaryColor),
                          hintMaxLines: 1,
                          prefixIcon: Icon(Icons.search, color: secondaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        style: TextStyle(color: secondaryColor),
                        onChanged: (text) {
                          setState(() {
                            if (text.toLowerCase() == "goat") {
                              agendaOpen(2024, 8920);
                              return;
                            }
                            
                            searchText = text;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(
                      thickness: 1,
                      indent: 100,
                      endIndent: 100,
                    ),
                  ],
                ),
              ),
             
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 500,
                        child: Column(
                          children: [
                            !js.context.callMethod('isStandalone')
                                ? SizedBox(
                                    width: 400,
                                    child: ListTile(
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Center(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.download,
                                                    color: secondaryColor,
                                                  ),
                                                  SizedBox(width: 10), // Add some spacing between the icon and text
                                                  Text(
                                                    'Installer l\'application', // Replace 'name' with a defined string
                                                    style: TextStyle(color: secondaryColor),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        bool isStandalone = js.context.callMethod('isStandalone');
                                        if (!isStandalone) {
                                          js.context.callMethod("launchApp");
                                        }
                                      },
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                      SizedBox(
                        child: favList(),
                      ),
                      SizedBox(
                        child: CustomAgenda(),
                      ),
                      SizedBox(
                        width: 400,
                        child: buildDropdownMenu(
                            'Salle', salleData, 'salle', this),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 400,
                        child: buildDropdownMenu(
                            'Professeur', profData, 'prof', this),
                      ),
                      ...univData.map<Widget>((univ) {
                        return Column(
                          children: [
                            const SizedBox(height: 10),
                            SizedBox(
                              width: 400,
                              child: buildDropdownMenu(univ['nameUniv'],
                                  univ['timetable'], 'univ', this),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              ],
            ),
            
            

            
        ),
      ),
      backgroundColor: primaryColor,
    );
  }

  bool filterItem(String text, String item) {
    if (text.length > 3) {
      List<String> words = text.split(" ");
      for (String word in words) {
        
        if (!item.toLowerCase().contains(word.toLowerCase())) {
          return false;
        }
      }
      return true;
    }
    return true;
  }

  Widget CustomAgenda() {
    return FutureBuilder<List<dynamic>>(
      future: CacheHelper.getAllFromCustom(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading custom agenda'));
        } else {
          List<dynamic> custom = snapshot.data ?? [];

            return Column(
            children: [
                Center(
                child: Container(
                width: 400,
                child: Column(
                children: [
                  
                  ...custom.map<Widget>((item) {
                  
                  
                  String name = item['descTT'];
                  int adeProjectID = item['adeProjectId'];
                  int adeResources = item['adeResources'];
                  String key = '$adeProjectID-$adeResources';
                  return ListTile(
                  title: Row(
                    children: [
                    const SizedBox(width: 10), // Add padding of 10 at left
                    Center(
                      child: FutureBuilder<bool>(
                      future: CacheHelper.existCustom(key),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                        return Icon(Icons.close, color: secondaryColor);
                        } else if (snapshot.hasError) {
                        return Icon(Icons.error, color: secondaryColor);
                        } else {
                        IconData iconData = Icons.close;
                        return IconButton(
                          icon: Icon(iconData),
                          color: Colors.red,
                          onPressed: () {
                          setState(() {
                            CacheHelper.removeFromCustom(adeResources.toString());  
                          });
                          },
                        );
                        }
                      },
                      ),
                    ),
                    Expanded(
                      child: Text(
                      name,
                      style: TextStyle(color: secondaryColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ],
                  ),
                  onTap: () {
                    agendaOpen(adeProjectID, adeResources);
                  },
                  );
                }).toList(),
                SizedBox(
                  width: 400,
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: secondaryColor,
                                ),
                                SizedBox(width: 10), // Add some spacing between the icon and text
                                Text(
                                  'Ajouter votre emploi du temps', // Replace 'name' with a defined string
                                  style: TextStyle(color: secondaryColor),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      showCustomEdtPopup(context);
                    },
                  ),
                )
                ]
                ),
                
              ),
              ),
            ],
            );
        }
      },
    );
  }
  Widget favList() {
    return FutureBuilder<List<dynamic>>(
      future: CacheHelper.getAllFromFav(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading favorites'));
        } else {
          List<dynamic> custom = snapshot.data ?? [];

            return Column(
            children: [
              Center(
              child: Container(
                width: 400,
                child: Column(
                children: custom.map<Widget>((item) {
                  String name = item['descTT'];
                  int adeProjectID = item['adeProjectId'];
                  int adeResources = item['adeResources'];
                  String key = '$adeProjectID-$adeResources';
                  return ListTile(
                  title: Row(
                    children: [
                    const SizedBox(width: 10), // Add padding of 10 at left
                    Center(
                      child: FutureBuilder<bool>(
                      future: CacheHelper.existFav(key),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                        return Icon(Icons.star_border, color: secondaryColor);
                        } else if (snapshot.hasError) {
                        return Icon(Icons.error, color: secondaryColor);
                        } else {
                        bool isFavorite = snapshot.data ?? false;
                        IconData iconData = isFavorite ? Icons.star : Icons.star_border;
                        return IconButton(
                          icon: Icon(iconData),
                          color: isFavorite ? Colors.yellow : secondaryColor,
                          onPressed: () {
                          setState(() {
                            if (isFavorite) {
                            CacheHelper.removeFromFav(key);
                            } else {
                            CacheHelper.addToFav(key, jsonEncode(item));
                            }
                            isFavorite = !isFavorite;
                            iconData = isFavorite ? Icons.star : Icons.star_border;
                          });
                          },
                        );
                        }
                      },
                      ),
                    ),
                    Expanded(
                      child: Text(
                      name,
                      style: TextStyle(color: secondaryColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ],
                  ),
                  onTap: () {
                    agendaOpen(adeProjectID, adeResources);
                  },
                  );
                }).toList(),
                ),
              ),
              ),
            ],
            );
        }
      },
    );
  }

  Widget buildDropdownMenu(
      String title, List<dynamic> items, String itemType, State state) {
    int itemsToShow = 20;
    if (title != 'Professeur' && title != 'Salle') {
      if (!filterItem(searchText, title)) {
        return Container();
      }
    }
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        bool isExpanded = false;
        return ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (bool expanded) {
            setState(() {
              isExpanded = expanded;
            });
          },
          title: Row(
            children: [
              SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(color: secondaryColor),
                  ),
                ),
              ),
            ],
          ),
          iconColor:
              secondaryColor, // Set the down icon color to secondaryColor
          children: [
            SizedBox(
              height: 200, // Set a fixed height for the scrollable area
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scrollInfo) {
                  if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent) {
                    setState(() {
                      if (itemsToShow < items.length) {
                        itemsToShow += 20;
                      }
                    });
                  }
                  return true;
                },
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...items
                          .where((item) {
                            if (title == 'Professeur' || title == 'Salle') {
                              String name = item['descTT'];
                              if (!filterItem(searchText, name)) {
                                return false;
                              }
                            }
                            return true;
                          })
                          .take(itemsToShow)
                          .map<Widget>((item) {
                            String name = item['descTT'];
                            int adeProjectID = item['adeProjectId'];
                            int adeResources = item['adeResources'];
                            String key = '$adeProjectID-$adeResources';
                            return ListTile(
                              title: Row(
                                children: [
                                  FutureBuilder<bool>(
                                    future: CacheHelper.existFav(key),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Icon(Icons.star_border,
                                            color: secondaryColor);
                                      } else if (snapshot.hasError) {
                                        return Icon(Icons.error,
                                            color: secondaryColor);
                                      } else {
                                        bool isFavorite =
                                            snapshot.data ?? false;
                                        IconData iconData = isFavorite
                                            ? Icons.star
                                            : Icons.star_border;
                                        return IconButton(
                                          icon: Icon(iconData),
                                          color: isFavorite
                                              ? Colors.yellow
                                              : secondaryColor,
                                          onPressed: () {
                                            setState(() {
                                              if (isFavorite) {
                                                CacheHelper.removeFromFav(key);
                                              } else {
                                                CacheHelper.addToFav(
                                                    key, jsonEncode(item));
                                              }
                                              isFavorite = !isFavorite;
                                              iconData = isFavorite
                                                  ? Icons.star
                                                  : Icons.star_border;
                                            });
                                          },
                                        );
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: TextStyle(color: secondaryColor),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () { 
                                agendaOpen(adeProjectID, adeResources);
                              },
                            );
                          })
                          .toList(),
                      if (itemsToShow < items.length)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              itemsToShow += 20;
                            });
                          },
                          child: Text('Plus'),
                        ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  void showCustomEdtPopup(BuildContext context) {
      TextEditingController projectNameController = TextEditingController();
      TextEditingController resourcesController = TextEditingController();
      int currentStep = 0;
      showDialog(
        context: context,
        builder: (BuildContext context) {
            return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {

                return SizedBox(
                width: double.infinity,
                height: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  ),
                ),
                Material(
                  child: Stepper(
                    currentStep: currentStep,
                    onStepContinue: () {
                      print(currentStep);
                      if (currentStep < 3) {
                        setState(() {
                          if (currentStep == 1) {
                            if (resourcesController.text.length == 13 && RegExp(r'^\d+$').hasMatch(resourcesController.text)) {
                              currentStep += 1;
                            }
                            else{
                                ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('ID invalide. Veuillez entrer un ID numérique de 13 chiffres.'),
                                  backgroundColor: Colors.red,
                                ),
                                );
                            }
                          }
                          else {
                            currentStep +=1;
                          }
                        
                        });
                      } else {
                        // Handle form submission
                        String leocardID = resourcesController.text;
                        String name = projectNameController.text;
                        int last8Digits = int.parse(leocardID.substring(leocardID.length - 8));
                        Map<String, dynamic> customAgenda = {
                          "numUniv": 1,
                          "descTT": name,
                          "adeUniv": "http://proxyade.unicaen.fr/ZimbraIcs/etudiant/",
                          "adeResources": last8Digits,
                          "adeProjectId": 2023
                        };
                        print(jsonEncode(customAgenda));
                        CacheHelper.addToCustom('$last8Digits', jsonEncode(customAgenda));
                        // Add your logic to handle the input values here
                        Navigator.of(context).pop();
                      }
                    },
                    onStepCancel: () {
                      if (currentStep > 0) {
                        setState(() {
                          currentStep -= 1;
                        });
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    steps: [
                      Step(
                        title: Text('Etape 1'),
                        content: Column(
                          children: [
                          SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                            launchUrl(Uri.parse('https://moncomptenumerique.unicaen.fr/compte/gerer'));
                            },
                            child: Text(
                            'Obtenez votre identifiant leocard (Copiez-le)',
                            style: TextStyle(color: Colors.blue),
                            ),
                          ),
                          SizedBox(height: 16),
                          ],
                        ),
                        isActive: currentStep == 0,
                      ),
                      Step(
                        title: Text('Etape 2'),
                        content: Column(
                          children: [
                          SizedBox(height: 16),
                          TextField(
                            controller: resourcesController,
                            decoration: InputDecoration(labelText: 'Entrez votre identifiant'),
                            
                          ),
                          SizedBox(height: 16),
                          ],
                        ),

                        
                        isActive: currentStep == 1,
                      ),
                      Step(
                        title: Text('Etape 3'),
                        content: Column(
                          children: [
                          SizedBox(height: 16),
                          TextField(
                            controller: projectNameController,
                            decoration: InputDecoration(labelText: 'Entrez le nom de cet agenda personnalisé'),
                          ),
                          SizedBox(height: 16),
                          ],
                        ),
                        isActive: currentStep == 2,
                      ),
                      Step(
                        title: Text('Etape 4'),
                        content: Column(
                          children: [
                          SizedBox(height: 16),
                            Text(
                            'Votre identifiant : ${resourcesController.text}',
                            ),
                            Text(
                            'Nom de l\'agenda : ${projectNameController.text}'
                            ),
                            Text(
                            'Vous devez redémarrer l\'application après avoir confirmé cela',
                            style: TextStyle(color: Colors.red)
                            ),
                            GestureDetector(
                            onTap: () {
                            launchUrl(Uri.parse('https://www.instagram.com/arthur_mimir/'));
                            },
                            child: Text(
                            'En cas de probleme contacté moi sur Instagram (Cliquez-ici)',
                            style: TextStyle(color: Colors.blue),
                            ),
                          ),
                            SizedBox(height: 16),
                            ],
                          ),
                          isActive: currentStep == 3,
                          ),
                        ],
                        ),
                ),
                ],
              ),
              );
            },
            );
          });
        }
  
    
  

  void loadAgenda(int adeProjectID, int adeResources) {
    // Implement your logic to load and display the agenda here.
    // This function should handle the UI and data fetching for the agenda.
    // For example, you might navigate to a new screen that displays the agenda.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgendaPage(adeProjectID: adeProjectID, adeResources: adeResources),
      ),
    );
  }
  Future<void> agendaOpen(int adeProjectID, int adeResources) async {
  //On download 30 cours mais on en affiche que 15 donc on verifie que les 15 derniers cours.
    String key = "$adeProjectID-$adeResources";
    // Show loader page
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
      return Center(
        child: CircularProgressIndicator(),
      );
      },
    );
    if (await CacheHelper.existSave(key)) {    
      if (await hasInternetConnection()) {
        await checkUpdate(adeProjectID, adeResources);
      }
    }
    else {
      if (await hasInternetConnection()) {
        await checkUpdate(adeProjectID, adeResources);
      }
      else {
        return;
      }
    }   
    Navigator.of(context).pop(); // Close the loader dialog
    loadAgenda(adeProjectID, adeResources);
  }
  
}
