import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as htmlparser;
import 'package:icu_admin_app/assignpage.dart';
import 'package:icu_admin_app/assignpatienttoicupage.dart';
import 'package:icu_admin_app/logpage.dart';
import 'package:icu_admin_app/newpatientpage.dart';
import 'package:icu_admin_app/newstaffpage.dart';
import 'package:icu_admin_app/patientdetails.dart';
import 'package:icu_admin_app/settings.dart';
import 'package:intl/intl.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ICUData {
  final String icuName;
  final int bp;
  final double temperature;
  final int dripLevel;
  final int heartRate;

  ICUData({
    required this.icuName,
    required this.bp,
    required this.temperature,
    required this.dripLevel,
    required this.heartRate,
  });

  @override
  String toString() {
    return 'ICUData(icuName: $icuName, BP: $bp, Temperature: $temperature, Drip Level: $dripLevel, Heart Rate: $heartRate)';
  }

  static List<ICUData> parseHTMLResponse(String htmlData) {
    final icuDataList = <ICUData>[];
    final regex = RegExp(
        r'ICU(\d+)\s+BP:\s*(\d+)\s+temperature:\s*([\d.]+)\s+driplevel:\s*(\d+)\s+HeartRate:\s*(\d+)');

    final matches = regex.allMatches(htmlData);

    for (final match in matches) {
      final icuName = 'ICU${match.group(1)}';
      final bp = int.parse(match.group(2)!);
      final temperature = double.parse(match.group(3)!);
      final dripLevel = int.parse(match.group(4)!);
      final heartRate = int.parse(match.group(5)!);

      icuDataList.add(ICUData(
        icuName: icuName,
        bp: bp,
        temperature: temperature,
        dripLevel: dripLevel,
        heartRate: heartRate,
      ));
    }

    return icuDataList;
  }
}

class ICUDataGrid2 extends StatefulWidget {
  const ICUDataGrid2({super.key});

  @override
  ICUDataGrid2State createState() => ICUDataGrid2State();
}

class ICUDataGrid2State extends State<ICUDataGrid2> {
  final List<String> terminalMessages = [
    'Connecting to ICU device 1',
    'Connecting to ICU device 2',
    'Connecting to ICU device 3',
    'Connecting to ICU device 4',
    'Connecting to ICU device 5',
  ];

  String terminalDisplay = '';
  final info = NetworkInfo();
  Timer? _timer;
  static List<ICUData> icuDataList = [];
  ValueNotifier<bool> showDotsNotifier = ValueNotifier<bool>(true);
  bool isAnySelected = false;
  String icuDeviceName = '';
  List<dynamic> patientsJsonData = [];
  List<dynamic> staffsJsonData = [];
  List<dynamic> staffData = [];
  List<Map<String, dynamic>> patientData = [];

  @override
  void initState() {
    super.initState();
    startTerminalDisplay();
    loadPatientData();
    loadStaffLog();
    getWirelessDevices(); // Call to start fetching data
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void loadPatientData() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/patient_data.json');
    final contents = await file.readAsString();
    patientsJsonData = jsonDecode(contents);

    patientData = List<Map<String, dynamic>>.from(jsonDecode(contents));

    for (var patient in patientsJsonData) {
      String patientName = patient['name'];
      String assignedICUDevice = patient['assignedICUDevice'];

      for (var icuData in icuDataList) {
        if (icuData.icuName == assignedICUDevice) {
          // Append patient names, but only show one in the description
          icuDataList = icuDataList.map((data) {
            if (data.icuName == icuData.icuName) {
              return ICUData(
                icuName: data.icuName,
                bp: data.bp,
                temperature: data.temperature,
                dripLevel: data.dripLevel,
                heartRate: data.heartRate,
              );
            }
            return data;
          }).toList();
        }
      }
    }
    // print(contents);
  }

  void loadStaffLog() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/ICU_Admin_Doc/staff_log.json';
    final file = File(path);
    final contents = await file.readAsString();
    staffsJsonData = jsonDecode(contents);
    //print(contents);
    // staffData = jsonDecode(contents);
    // Add staff data handling logic here
    staffData = List<Map<String, dynamic>>.from(jsonDecode(contents));
  }

  void startTerminalDisplay() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (!mounted) return;
      // Dummy terminal messages
      //int index = Random().nextInt(5);
      if (!mounted) return;
      int index = Random().nextInt(icuDataList.length);
      setState(() {
        terminalDisplay = '${icuDataList[index].icuName}    Connecting';
        showDotsNotifier.value = true;
      });
      getWirelessDevices();
      Timer(Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          showDotsNotifier.value = false;
        });
      });
    });
  }

  void _onRowTap(ICUData item) {
    print('Tapped on row: ${item.icuName}');
    setState(() {
      icuDeviceName = item.icuName;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Patientdetailspage(icuDeviceName: icuDeviceName),
      ),
    );
    print(icuDeviceName);

    // Navigate to patient details page or other relevant pages
  }

  Color _getIndicatorColor(ICUData item) {
    if (item.bp > 120 || item.temperature > 37.8) {
      return Colors.red;
    } else if (item.bp < 100 || item.temperature < 30) {
      return Colors.green;
    }
    return Colors.transparent;
  }

  Widget _buildBlinkingIndicator(ICUData item) {
    Color color = _getIndicatorColor(item);
    if (color == Colors.red) {
      return BlinkingIndicator(color: color);
    } else if (color == Colors.green) {
      return Icon(Icons.circle, color: color, size: 25);
    } else {
      return Container();
    }
  }

  Future<void> fetchData(String wifiGateway) async {
    try {
      final response = await http.get(Uri.parse('http://$wifiGateway'));

      if (response.statusCode == 200) {
        final htmlResponse = response.body;
        final parsedICUDataList = ICUData.parseHTMLResponse(htmlResponse);
        setState(() {
          icuDataList = parsedICUDataList;
        });
        // print(icuDataList[1].dripLevel);
      } else {
        print('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch data: $e');
    }
  }

  void getWirelessDevices() async {
    try {
      final wifiName = await info.getWifiName();
      final wifiBSSID = await info.getWifiBSSID();
      final wifiIP = await info.getWifiIP();
      final wifiGateWay = await info.getWifiGatewayIP();

      // print('WiFi Name: $wifiName');
      // print('WiFi BSSID: $wifiBSSID');
      // print('WiFi IP: $wifiIP');
      print('WiFi Gateway IP: $wifiGateWay');

      if (wifiGateWay != null) {
        await fetchData(wifiGateWay);
      } else {
        print('WiFi Gateway IP is null');
      }
    } catch (e) {
      print('Failed to get wireless devices: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ICU DATA'),
      ),
      body: Stack(
        children: [
          Positioned(
            left: 475.0,
            top: 80.0,
            child: Column(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.blue),
                    iconSize: 50.0,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AssignPage()),
                      );
                    },
                  ),
                ),
                const Text('Assign')
              ],
            ),
          ),
          Positioned(
            left: 80.0,
            top: 80.0,
            child: Row(
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: IconButton(
                        icon: Icon(Icons.list_alt, color: Colors.green),
                        iconSize: 50.0,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LogPage()),
                          );
                        },
                      ),
                    ),
                    const Text('Log')
                  ],
                ),
                const SizedBox(width: 70.0),
                Column(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: IconButton(
                        icon: Icon(Icons.wifi, color: Colors.orange),
                        iconSize: 50.0,
                        onPressed: () {},
                      ),
                    ),
                    const Text('WiFi')
                  ],
                ),
                const SizedBox(width: 90.0),
                Column(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: IconButton(
                        icon: const Icon(Icons.notification_important,
                            color: Colors.red),
                        iconSize: 50.0,
                        onPressed: () {},
                      ),
                    ),
                    const Text('Alert')
                  ],
                ),
                const SizedBox(width: 230.0),
                Column(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: IconButton(
                        icon: const Icon(Icons.person_add_alt_1,
                            color: Colors.purple),
                        iconSize: 50.0,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const NewStaffPage()),
                          );
                        },
                      ),
                    ),
                    const Text('Add Staff')
                  ],
                ),
                const SizedBox(width: 85.0),
                Column(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: IconButton(
                        icon: const Icon(Icons.person_add_alt,
                            color: Colors.teal),
                        iconSize: 50.0, // Set the icon size here
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Newpatientpage()),
                          );
                        },
                      ),
                    ),
                    const Text('New Patient')
                  ],
                ),
                const SizedBox(width: 85.0),
                Column(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: IconButton(
                        icon: const Icon(Icons.assignment_ind,
                            color: Colors.brown),
                        iconSize: 50.0, // Set the icon size here
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const Assignpatienttoicupage(),
                              ));
                        },
                      ),
                    ),
                    const Text('Assign ICU')
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 1090.0,
            top: 80.0,
            child: Column(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.blue),
                    iconSize: 50.0, // Set the icon size here
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsPage()),
                      );
                      // getICUDeviceSelected();
                    },
                  ),
                ),
                const Text('Settings')
              ],
            ),
          ),
          Positioned(
            top: 20,
            left: 63,
            //right: 30,
            bottom: 30,
            child: Center(
                child: Container(
              width: 1070,
              height: 300,
              margin: const EdgeInsets.all(20.0),
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateColor.resolveWith(
                        (states) => Colors.black), // Row background
                    columns: const [
                      DataColumn(
                          label: Text('ICU Device',
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          label: Text('BP',
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          label: Text('Temperature',
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          label: Text('Drip Level',
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          label: Text('Heart Rate',
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          label: Text('Status',
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          label: Text('Update Time',
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          label: Text('Description',
                              style: TextStyle(color: Colors.white))),
                    ],
                    rows: icuDataList.map((item) {
                      String description = '';
                      /* for (var patient in patientsJsonData) {
                        if (patient['assignedICUDevice'] == item.icuName) {
                          setState(() {
                            description = patient['name'];
                          });

                          break;
                        }
                      }*/

                      List<String> associatedPatients = [];
                      List<String> associatedStaff = [];

                      for (var patient in patientData) {
                        if (patient['assignedICUDevice'] == item.icuName) {
                          associatedPatients.add(patient['name']);
                        }
                      }

                      // Find staff associated with this ICU device
                      for (var staff in staffData) {
                        if (staff['assignedICUDevices']
                            .contains(item.icuName)) {
                          associatedStaff.add(
                              '${staff['name']} (${staff['designation']})');
                        }
                      }
                      if (associatedPatients.isNotEmpty) {
                        description = associatedPatients.first;
                      }
                      return DataRow(
                        cells: [
                          DataCell(GestureDetector(
                              onTap: () => _onRowTap(item),
                              child: Text(item.icuName,
                                  style: TextStyle(color: Colors.white)))),
                          DataCell(GestureDetector(
                              onTap: () => _onRowTap(item),
                              child: Text(item.bp.toString(),
                                  style: TextStyle(color: Colors.white)))),
                          DataCell(GestureDetector(
                              onTap: () => _onRowTap(item),
                              child: Text(item.temperature.toString(),
                                  style: TextStyle(color: Colors.white)))),
                          DataCell(GestureDetector(
                              onTap: () => _onRowTap(item),
                              child: Text(item.dripLevel.toString(),
                                  style: TextStyle(color: Colors.white)))),
                          DataCell(GestureDetector(
                              onTap: () => _onRowTap(item),
                              child: Text(item.heartRate.toString(),
                                  style: TextStyle(color: Colors.white)))),

                          DataCell(_buildBlinkingIndicator(item)),
                          // DataCell(Text(description,
                          //   style: TextStyle(color: Colors.white))),
                          DataCell(GestureDetector(
                              onTap: () => _onRowTap(item),
                              child: Text(
                                  DateFormat('yyyy-MM-dd – kk:mm')
                                      .format(DateTime.now()),
                                  style: TextStyle(color: Colors.white)))),
                          DataCell(
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              onEnter: (event) {
                                // Show a tooltip with all patient names when mouse hovers
                                if (associatedPatients.isNotEmpty ||
                                    associatedStaff.isNotEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('ICU: ${item.icuName}'),
                                        content: Text(
                                          'Patients: ${associatedPatients.join(', ')}\n'
                                          '--------------------------------\n'
                                          'Staff: ${associatedStaff.join(', ')}',
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('OK'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                              child: GestureDetector(
                                onTap: () {
                                  // Handle tap event if needed
                                },
                                child: Text(
                                  description,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                        onSelectChanged: (selected) {
                          if (selected != null && selected) {
                            _onRowTap(item);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            )),
          ),
          const Positioned(
            left: 20.0,
            bottom: 60.0,
            right: 20.0,
            child: Divider(),
          ),
          Positioned(
            left: 20.0,
            bottom: 30.0,
            right: 20.0,
            child: Container(
              height: 60.0,
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Center(
                child: AnimatedBuilder(
                  animation: showDotsNotifier,
                  builder: (BuildContext context, Widget? child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          terminalDisplay,
                          style: TextStyle(fontSize: 16.0),
                        ),
                        SizedBox(width: 5.0),
                        if (showDotsNotifier.value) ...[
                          const Text(
                            '. . . . . . . . . . ',
                            style: TextStyle(fontSize: 16.0),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BlinkingIndicator extends StatefulWidget {
  final Color color;

  const BlinkingIndicator({required this.color, Key? key}) : super(key: key);

  @override
  _BlinkingIndicatorState createState() => _BlinkingIndicatorState();
}

class _BlinkingIndicatorState extends State<BlinkingIndicator> {
  late Timer _timer;
  bool _isBlinking = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(milliseconds: 500), (Timer timer) {
      setState(() {
        _isBlinking = !_isBlinking;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isBlinking
        ? Icon(Icons.circle, color: widget.color, size: 25)
        : Container();
  }
}
