import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:icu_admin_app/assignpage.dart';
import 'package:icu_admin_app/assignpatienttoicupage.dart';
import 'package:icu_admin_app/logpage.dart';
import 'package:icu_admin_app/newpatientpage.dart';
import 'package:icu_admin_app/newstaffpage.dart';
import 'package:icu_admin_app/patientdetails.dart';
import 'package:intl/intl.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wifi_scan_windows/available_network.dart';
import 'package:wifi_scan_windows/wifi_scan_windows.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlparser;

class ICUDataGrid extends StatefulWidget {
  const ICUDataGrid({super.key});

  @override
  ICUDataGridState createState() => ICUDataGridState();
}

class ICUDataGridState extends State<ICUDataGrid> {
  final info = NetworkInfo();
  Timer? _timer;
  List<AvailableNetwork> availableNetworks = [];
  final WifiScanWindows _wifiScanWindowsPlugin = WifiScanWindows();
  static late List<String> listOfSensorValues;

  List<Map<String, dynamic>> data = List.generate(5, (index) {
    double temperatureFahrenheit = 69.6 + (index * 0.1);
    double temperatureCelsius = (temperatureFahrenheit - 32) * 5 / 9;
    return {
      'name': 'ICU device ${index + 1}',
      'bp': '${120 + index}/80',
      'temperature': temperatureCelsius,
      'updateTime': DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now()),
      'selected': false,
      'description': '',
      'allPatients': []
    };
  });

  final List<String> terminalMessages = [
    'Connecting to ICU device 1',
    'Connecting to ICU device 2',
    'Connecting to ICU device 3',
    'Connecting to ICU device 4',
    'Connecting to ICU device 5',
  ];

  String terminalDisplay = '';
  ValueNotifier<bool> showDotsNotifier = ValueNotifier<bool>(true);
  bool isAnySelected = false;
  String icuDeviceName = '';
  static List<ICUData> icuDataList = [];

  @override
  void initState() {
    super.initState();
    startTerminalDisplay();
    //getWirelessDevices();
    loadPatientData();
    loadStaffLog();
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
    final List<dynamic> jsonData = jsonDecode(contents);

    for (var patient in jsonData) {
      String patientName = patient['name'];
      String assignedICUDevice = patient['assignedICUDevice'];

      for (var device in data) {
        if (device['name'] == assignedICUDevice) {
          // Append patient names, but only show one in the description
          if (device['description'].isEmpty) {
            setState(() {
              device['description'] = patientName;
            });
          }

          // Add all patient names to a new list for tooltips
          if (device['allPatients'] == null) {
            device['allPatients'] = [];
          }
          device['allPatients'].add(patientName);
        }
      }
    }
  }

  void loadStaffLog() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/ICU_Admin_Doc/staff_log.json';
    final file = File(path);
    final contents = await file.readAsString();

    // print(contents);
    final List<dynamic> jsonData = jsonDecode(contents);

    for (var staff in jsonData) {
      String staffName = staff['name'];
      String designation = staff['designation'];
      List<dynamic> assignedICUDevices = staff['assignedICUDevices'];
      // print(assignedICUDevices);
      for (var device in data) {
        if (assignedICUDevices.contains(device['name'])) {
          if (device['allStaff'] == null) {
            device['allStaff'] = [];
          }
          device['allStaff'].add('$designation - $staffName');

          //print(device['allStaff']);
        }
      }
    }
  }

  void startTerminalDisplay() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (!mounted) return;
      int index = Random().nextInt(terminalMessages.length);
      getWirelessDevices();
      setState(() {
        terminalDisplay = terminalMessages[index];
        showDotsNotifier.value = true;
      });

      Timer(Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          showDotsNotifier.value = false;
        });
      });
    });
  }

  void _onCheckboxChanged(bool? value, int index) {
    setState(() {
      data[index]['selected'] = value ?? false;
      isAnySelected = data.any((item) => item['selected']);
    });
  }

  void getICUDeviceSelected() {
    try {
      List<Map<String, dynamic>> selectedICUDevices =
          data.where((item) => item['selected']).toList();
      print('Selected ICUDevices: $selectedICUDevices');
      print(selectedICUDevices[0]['name']);
    } catch (e) {
      print(e);
    }
  }

  void _onRowTap(Map<String, dynamic> item) {
    print('Tapped on row: ${item['name']}');
    setState(() {
      icuDeviceName = item['name'];
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Patientdetailspage(icuDeviceName: icuDeviceName),
      ),
    );
    print(icuDeviceName);
  }

  Color _getIndicatorColor(Map<String, dynamic> item) {
    String bp = item['bp'];
    List<String> bpValues = bp.split('/');
    int systolic = int.parse(bpValues[0]);
    double temperature = item['temperature'];

    if (systolic > 120 || temperature > 37.8) {
      return Colors.red;
    } else if (systolic < 100 || temperature < 30) {
      return Colors.green;
    }
    return Colors.transparent;
  }

  Widget _buildBlinkingIndicator(Map<String, dynamic> item) {
    Color color = _getIndicatorColor(item);
    if (color == Colors.red) {
      return BlinkingIndicator(color: color);
    } else if (color == Colors.green) {
      return Icon(Icons.circle, color: color, size: 25);
    } else {
      return Container();
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
            left: 450.0,
            top: 30.0,
            child: Column(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.blue),
                    iconSize: 50.0, // Set the icon size here
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AssignPage()),
                      );
                      getICUDeviceSelected();
                    },
                  ),
                ),
                const Text('Assign')
              ],
            ),
          ),
          Positioned(
            left: 180.0,
            top: 30.0,
            child: Row(
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: IconButton(
                        icon: Icon(Icons.list_alt, color: Colors.green),
                        iconSize: 50.0, // Set the icon size here
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
                const SizedBox(width: 40.0),
                Column(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: IconButton(
                        icon: Icon(Icons.wifi, color: Colors.orange),
                        iconSize: 50.0, // Set the icon size here
                        onPressed: () {},
                      ),
                    ),
                    const Text('WiFi')
                  ],
                ),
                const SizedBox(width: 40.0),
                Column(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: IconButton(
                        icon: const Icon(Icons.notification_important,
                            color: Colors.red),
                        iconSize: 50.0, // Set the icon size here
                        onPressed: () {},
                      ),
                    ),
                    const Text('Alert')
                  ],
                ),
                const SizedBox(width: 150.0),
                Column(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: IconButton(
                        icon: const Icon(Icons.person_add_alt_1,
                            color: Colors.purple),
                        iconSize: 50.0, // Set the icon size here
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const NewStaffPage()),
                          );
                        },
                      ),
                    ),
                    const Text('New Staff')
                  ],
                ),
                const SizedBox(width: 55.0),
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
                const SizedBox(width: 45.0),
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
            left: 930.0,
            top: 30.0,
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
                            builder: (context) => const AssignPage()),
                      );
                      getICUDeviceSelected();
                    },
                  ),
                ),
                const Text('Settings')
              ],
            ),
          ),
          Positioned(
            top: 100,
            left: 170,
            child: Center(
              child: Container(
                width: 850,
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
                          (states) => Colors.black),
                      columns: const [
                        DataColumn(
                            label: Text('Device Name',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('BP',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('Temperature',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('Update Time',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('Alert',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('Description',
                                style: TextStyle(color: Colors.white))),
                      ],
                      rows: data.map((item) {
                        int index = data.indexOf(item);
                        return DataRow(
                          cells: [
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(item['name'],
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(item['bp'],
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(
                                    item['temperature']?.toStringAsFixed(2) ??
                                        '',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(item['updateTime'] ?? '',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: _buildBlinkingIndicator(item),
                              ),
                            ),
                            DataCell(
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                onEnter: (event) {
                                  // Show a tooltip with all patient names when mouse hovers
                                  if (item['allPatients'] != null &&
                                      item['allPatients'].isNotEmpty) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(item['name']),
                                          content: Text(item['allPatients']
                                                  .join(', ') +
                                              '\n' +
                                              '--------------------------------'
                                                  '\n' +
                                              item['allStaff'].join(', ')),
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
                                  onTap: () => _onRowTap(item),
                                  child: Text(
                                    item['description'], // Show only one name
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          selected: item['selected'] ?? false,
                          onSelectChanged: (bool? value) {
                            _onCheckboxChanged(value, index);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
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

  Future<void> fetchData(String wifiGateway) async {
    try {
      final response = await http.get(Uri.parse('http://$wifiGateway'));
      // print(response);
      final responseBody = response.body;
      final document = htmlparser.parse(responseBody);

      icuDataList = parseICUData(responseBody);
      print(icuDataList);
    } catch (e) {
      print('Error: $e');
    }
  }

  void getWirelessDevices() async {
    final wifiName = await info.getWifiName();
    final wifiBSSID = await info.getWifiBSSID();
    final wifiIP = await info.getWifiIP();
    final wifiGateWay = await info.getWifiGatewayIP();
    print(wifiName);
    fetchData(wifiGateWay!);
  }
}

class BlinkingIndicator extends StatefulWidget {
  final Color color;

  const BlinkingIndicator({Key? key, required this.color}) : super(key: key);

  @override
  _BlinkingIndicatorState createState() => _BlinkingIndicatorState();
}

class _BlinkingIndicatorState extends State<BlinkingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Icon(Icons.circle, color: widget.color, size: 25),
        );
      },
    );
  }
}

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
}

List<ICUData> parseICUData(String htmlData) {
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
