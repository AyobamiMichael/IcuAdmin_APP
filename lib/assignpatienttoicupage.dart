import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Assignpatienttoicupage extends StatefulWidget {
  const Assignpatienttoicupage({super.key});

  @override
  State<Assignpatienttoicupage> createState() => _AssignpatienttoicupageState();
}

class _AssignpatienttoicupageState extends State<Assignpatienttoicupage> {
  List<Map<String, dynamic>> patientData = [];
  final List<Map<String, dynamic>> icuDevicesData = List.generate(5, (index) {
    return {
      'name': 'ICU device ${index + 1}',
      'selected': false,
    };
  });
  bool isAnySelected = false;

  @override
  void initState() {
    super.initState();
    loadPatientData();
  }

  Future<void> loadPatientData() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/patient_data.json');

    if (await file.exists()) {
      final contents = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(contents);

      setState(() {
        patientData = jsonData
            .map((item) => {
                  'name': item['name'],
                  'phone': item['phone'],
                  'idNumber': item['idNumber'],
                  'gender': item['gender'],
                  'assignedICUDevice': item['assignedICUDevice'] ?? '',
                  'selected': false,
                })
            .toList()
            .cast<Map<String, dynamic>>();
      });
    }
    print(patientData);
  }

  void _onCheckboxChanged(bool? value, int index, bool isPatient) {
    setState(() {
      if (isPatient) {
        patientData[index]['selected'] = value ?? false;
        isAnySelected = patientData.any((item) => item['selected']);
      } else {
        icuDevicesData[index]['selected'] = value ?? false;
      }
    });
  }

  void _onSendButtonPressed() async {
    List<Map<String, dynamic>> selectedPatients =
        patientData.where((item) => item['selected']).toList();
    List<Map<String, dynamic>> selectedICUDevices =
        icuDevicesData.where((item) => item['selected']).toList();

    if (selectedICUDevices.isNotEmpty) {
      String icuDeviceName = selectedICUDevices[0]['name'];

      for (var patient in selectedPatients) {
        patient['assignedICUDevice'] = icuDeviceName;
      }

      await _savePatientData(patientData);

      showDialogBoxForMessage();
    } else {
      // Handle the case where no ICU device is selected
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text("No ICU device selected"),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _savePatientData(
      List<Map<String, dynamic>> updatedPatientData) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/patient_data.json');
    await file.writeAsString(jsonEncode(updatedPatientData));
    print('Patient data saved at ${file.path}');
  }

  void _deletePatient(String idnumber) async {
    setState(() {
      patientData.removeWhere((item) => item['idNumber'] == idnumber);
    });

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/patient_data.json');
    await file.writeAsString(jsonEncode(patientData));
  }

  void showDialogBoxForMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Dialog Box"),
          content: Text("Data saved successfully"),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Patient to ICU'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.all(20.0),
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Select')),
                    DataColumn(label: Text('ICU Device Name')),
                  ],
                  rows: icuDevicesData.map((item) {
                    int index = icuDevicesData.indexOf(item);
                    return DataRow(
                      cells: [
                        DataCell(
                          Checkbox(
                            value: item['selected'],
                            onChanged: (value) {
                              _onCheckboxChanged(value, index, false);
                            },
                          ),
                        ),
                        DataCell(Text(item['name'] ?? '')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.all(20.0),
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Select')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Gender')),
                    DataColumn(label: Text('Delete')),
                  ],
                  rows: patientData.map((item) {
                    int index = patientData.indexOf(item);
                    return DataRow(
                      cells: [
                        DataCell(
                          Checkbox(
                            value: item['selected'],
                            onChanged: (value) {
                              _onCheckboxChanged(value, index, true);
                            },
                          ),
                        ),
                        DataCell(Text(item['name'] ?? '')),
                        DataCell(Text(item['phone'] ?? '')),
                        DataCell(Text(item['gender'] ?? '')),
                        DataCell(
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deletePatient(item['idNumber']);
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isAnySelected
          ? FloatingActionButton(
              onPressed: _onSendButtonPressed,
              child: Icon(Icons.send),
            )
          : null,
    );
  }
}
