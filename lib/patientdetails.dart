import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:icu_admin_app/datagrid2.dart';
import 'package:icu_admin_app/heartgraph.dart';
import 'package:path_provider/path_provider.dart';

class Patientdetailspage extends StatefulWidget {
  final String icuDeviceName;
  const Patientdetailspage({super.key, required this.icuDeviceName});

  @override
  State<Patientdetailspage> createState() => PatientdetailspageState();
}

class PatientdetailspageState extends State<Patientdetailspage> {
  List<Map<String, dynamic>> patientList = [];
  List<Map<String, dynamic>> filteredPatientList = [];
  List<Map<String, dynamic>> icuDevicesData = [];
  List<Map<String, dynamic>> filteredICUdataList = [];
  Timer? _timer;
  static String iCUnameSelected = '';
  @override
  void initState() {
    super.initState();
    _loadPatientData();
    loadIcuDataList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void icuDataTimmer() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {});
  }

  Future<void> loadIcuDataList() async {
    // Assuming ICUDataGrid2State.icuDataList is already populated
    setState(() {
      iCUnameSelected = widget.icuDeviceName;
      icuDevicesData = ICUDataGrid2State.icuDataList.map((icuData) {
        return {
          'name': icuData.icuName,
          'BP': icuData.bp,
          'Temperature': icuData.temperature,
          'Drip Level': icuData.dripLevel.toString(),
          'Heart Rate': icuData.heartRate
        };
      }).toList();
    });
    //print(icuDevicesData);
    filteredICUdataList = icuDevicesData.where((icudata) {
      return icudata['name'] == widget.icuDeviceName;
    }).toList();
    //print(filteredICUdataList);
  }

  Future<void> _loadPatientData() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/patient_data.json');

    if (await file.exists()) {
      final contents = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(contents);
      setState(() {
        patientList = jsonData.cast<Map<String, dynamic>>();
        filteredPatientList = patientList.where((patient) {
          return patient['assignedICUDevice'] == widget.icuDeviceName;
        }).toList();
      });
      // print(contents);
    }
  }

  void _onRowTap(item) {
    // Handle row tap
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Heartgraph(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patients Assigned to ${widget.icuDeviceName}'),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 80,
            left: 50,
            child: Center(
              child: Container(
                width: 950,
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
                      columns: const [
                        DataColumn(
                            label: Text('Name',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('Phone',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('Gender',
                                style: TextStyle(color: Colors.white))),
                        DataColumn(
                            label: Text('Bp',
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
                            label: Text('Ward',
                                style: TextStyle(color: Colors.white))),
                      ],
                      rows: filteredPatientList.map((item) {
                        var matchingICUData = filteredICUdataList.firstWhere(
                            (icuData) =>
                                icuData['name'] == widget.icuDeviceName,
                            orElse: () => <String, Object>{
                                  'BP': 'N/A',
                                  'Temperature': 'N/A',
                                  'Drip Level': 'N/A',
                                  'Heart Rate': 'N/A',
                                });
                        print(matchingICUData['Drip Level']);

                        return DataRow(
                          cells: [
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(item['name'] ?? '',
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(item['phone'] ?? '',
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(item['gender'] ?? '',
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(matchingICUData['BP'].toString(),
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(
                                    matchingICUData['Temperature'].toString(),
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(
                                    matchingICUData['Drip Level'].toString(),
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(
                                    matchingICUData['Heart Rate'].toString(),
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                            ),
                            DataCell(
                              GestureDetector(
                                onTap: () => _onRowTap(item),
                                child: Text(item['assignedWard'] ?? '',
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
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
        ],
      ),
    );
  }
}



















/*import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Patientdetailspage extends StatefulWidget {
  final String icuDeviceName;
  const Patientdetailspage({super.key, required this.icuDeviceName});

  @override
  State<Patientdetailspage> createState() => _PatientdetailspageState();
}

class _PatientdetailspageState extends State<Patientdetailspage> {
  List<Map<String, dynamic>> patientList = [];
  List<Map<String, dynamic>> filteredPatientList = [];

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/patient_data.json');

    if (await file.exists()) {
      final contents = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(contents);
      setState(() {
        patientList = jsonData.cast<Map<String, dynamic>>();
        filteredPatientList = patientList.where((patient) {
          return patient['assignedICUDevice'] == widget.icuDeviceName;
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patients Assigned to ${widget.icuDeviceName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: filteredPatientList.isEmpty
            ? const Center(
                child: Text('No patients assigned to this ICU device.'))
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Adjust the number of columns as needed
                  crossAxisSpacing: 1.5,
                  mainAxisSpacing: 1.5,
                ),
                itemCount: filteredPatientList.length,
                itemBuilder: (context, index) {
                  final patient = filteredPatientList[index];

                  return Container(
                    padding: EdgeInsets.all(2.0),
                    constraints: BoxConstraints(
                      maxWidth: 50, // Set the maximum width of the card
                      maxHeight: 60, // Set the maximum height of the card
                    ),
                    child: Card(
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name: ${patient['name']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4.0),
                            Text('Phone: ${patient['phone']}'),
                            const SizedBox(height: 4.0),
                            Text('Gender: ${patient['gender']}'),
                            const SizedBox(height: 4.0),
                            Text('ID: ${patient['idNumber']}'),
                            const SizedBox(height: 4.0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

*/



