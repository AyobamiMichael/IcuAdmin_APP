import 'dart:async';
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
      'selected': false
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

  @override
  void initState() {
    super.initState();
    startTerminalDisplay();
    getWirelessDevices();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTerminalDisplay() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (!mounted) return;
      int index = Random().nextInt(terminalMessages.length);
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
            left: 400.0,
            top: 40.0,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssignPage()),
                );
                getICUDeviceSelected();
              },
              child: const Text('Assign ICU To Staff'),
            ),
          ),
          Positioned(
            left: 100.0,
            top: 40.0,
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LogPage()),
                    );
                  },
                  child: const Text('Log'),
                ),
                const SizedBox(width: 10.0),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Reconnect'),
                ),
                const SizedBox(width: 10.0),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Alert'),
                ),
                const SizedBox(width: 190.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewStaffPage(),
                        ));
                  },
                  child: const Text('New Staff'),
                ),
                const SizedBox(width: 20.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Newpatientpage(),
                        ));
                  },
                  child: const Text('New Patient'),
                ),
                const SizedBox(width: 30.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Assignpatienttoicupage(),
                        ));
                  },
                  child: const Text('Assign Patient To ICU'),
                ),
              ],
            ),
          ),
          Positioned(
            top: 80,
            left: 100,
            child: Center(
              child: Container(
                width: 800,
                height: 300,
                margin: EdgeInsets.all(20.0),
                padding: EdgeInsets.all(10.0),
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
                      columns: const [
                        DataColumn(
                            label: Text('Name',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('BP',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('Temperature (°C)',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('Update Time',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('Status',
                                style: TextStyle(color: Colors.white))),
                      ],
                      rows: data.map((item) {
                        int index = data.indexOf(item);
                        return DataRow(
                          cells: [
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(item['name'] ?? '',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(item['bp'] ?? '',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(
                                    item['temperature'].toStringAsFixed(2) ??
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
                              _buildBlinkingIndicator(item),
                            ),
                          ],
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
      print(wifiGateway);
      final responseBody = response.body;
      final document = htmlparser.parse(responseBody);
      print(document);
      final wirelessSensorValues = document.querySelectorAll('p');
      listOfSensorValues =
          wirelessSensorValues.map((element) => element.text).toList();
      //print(listOfSensorValues);
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














/*import 'dart:async';
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
      'selected': false
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
  @override
  void initState() {
    super.initState();
    startTerminalDisplay();
    getWirelessDevices();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTerminalDisplay() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (!mounted) return;
      int index = Random().nextInt(terminalMessages.length);
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
    return color == Colors.transparent
        ? Container()
        : BlinkingIndicator(color: color);
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
            left: 400.0,
            top: 40.0,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssignPage()),
                );
                getICUDeviceSelected();
              },
              child: const Text('Assign ICU To Staff'),
            ),
          ),
          Positioned(
            left: 100.0,
            top: 40.0,
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LogPage()),
                    );
                  },
                  child: const Text('Log'),
                ),
                const SizedBox(width: 10.0),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Reconnect'),
                ),
                const SizedBox(width: 10.0),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Alert'),
                ),
                const SizedBox(width: 190.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewStaffPage(),
                        ));
                  },
                  child: const Text('New Staff'),
                ),
                const SizedBox(width: 20.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Newpatientpage(),
                        ));
                  },
                  child: const Text('New Patient'),
                ),
                const SizedBox(width: 30.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Assignpatienttoicupage(),
                        ));
                  },
                  child: const Text('Assign Patient To ICU'),
                ),
              ],
            ),
          ),
          Positioned(
            top: 80,
            left: 100,
            child: Center(
              child: Container(
                width: 800,
                height: 300,
                margin: EdgeInsets.all(20.0),
                padding: EdgeInsets.all(10.0),
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
                      columns: const [
                        DataColumn(
                            label: Text('Select',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('Name',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('BP',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('Temperature (°C)',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('Update Time',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('Status',
                                style: TextStyle(color: Colors.white))),
                      ],
                      rows: data.map((item) {
                        int index = data.indexOf(item);
                        return DataRow(
                          cells: [
                            DataCell(
                              Checkbox(
                                value: item['selected'],
                                onChanged: (value) {
                                  _onCheckboxChanged(value, index);
                                },
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(item['name'] ?? '',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(item['bp'] ?? '',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(
                                    item['temperature'].toStringAsFixed(2) ??
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
                              _buildBlinkingIndicator(item),
                            ),
                          ],
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
      print(wifiGateway);
      final responseBody = response.body;
      final document = htmlparser.parse(responseBody);
      print(document);
      final wirelessSensorValues = document.querySelectorAll('p');
      listOfSensorValues =
          wirelessSensorValues.map((element) => element.text).toList();
      //print(listOfSensorValues);
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
*/