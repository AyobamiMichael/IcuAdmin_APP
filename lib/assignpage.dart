import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:icu_admin_app/datagrid2.dart';
import 'package:icu_admin_app/patientdetails.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AssignPage extends StatefulWidget {
  const AssignPage({super.key});

  @override
  AssignPageState createState() => AssignPageState();
}

class AssignPageState extends State<AssignPage> {
  List<Map<String, dynamic>> staffData = [];
  List<Map<String, dynamic>> icuDevicesData = [];
  /*final List<Map<String, dynamic>> icuDevicesData = List.generate(5, (index) {
    return {
      'name': 'ICU device ${index + 1}',
      'selected': false,
    };
  });*/

  bool isAnySelected = false;
  int _selectedDuration = 1;
  String icuDeviceName = '';

  @override
  void initState() {
    super.initState();
    loadStaffData();
    loadIcuDataList();
  }

  Future<void> loadIcuDataList() async {
    // Assuming ICUDataGrid2State.icuDataList is already populated
    setState(() {
      icuDevicesData = ICUDataGrid2State.icuDataList.map((icuData) {
        return {
          'name': icuData.icuName,
          'selected': false,
        };
      }).toList();
    });
  }

  Future<void> loadStaffData() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/staff_data.json');

    if (await file.exists()) {
      final contents = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(contents);

      setState(() {
        staffData = jsonData
            .map((item) {
              return {
                'name': item['name'],
                'phone': item['phone'],
                'designation': item['designation'],
                'selected': false,
                'assignedICUDevices': [],
              };
            })
            .toList()
            .cast<Map<String, dynamic>>();
      });
    }
  }

  void _onCheckboxChanged(bool? value, int index, bool isStaff) {
    setState(() {
      if (isStaff) {
        staffData[index]['selected'] = value ?? false;
        isAnySelected = staffData.any((item) => item['selected']);
      } else {
        icuDevicesData[index]['selected'] = value ?? false;
      }
    });
  }

  void _onSendButtonPressed() async {
    List<Map<String, dynamic>> selectedStaff =
        staffData.where((item) => item['selected']).toList();
    List<Map<String, dynamic>> selectedICUDevices =
        icuDevicesData.where((item) => item['selected']).toList();

    // Read the current assignments from the log file
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/ICU_Admin_Doc/staff_log.json';
    final file = File(path);

    List<Map<String, dynamic>> existingAssignments = [];

    if (await file.exists()) {
      final contents = await file.readAsString();
      existingAssignments = jsonDecode(contents).cast<Map<String, dynamic>>();
    }

    // Track if any duplicates are found
    bool hasDuplicates = false;

    // Assign selected ICU devices to selected staff members
    for (var staff in selectedStaff) {
      for (var device in selectedICUDevices) {
        // Check if the ICU device is already assigned to this staff member
        if (staff['assignedICUDevices'].contains(device['name'])) {
          hasDuplicates = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Staff ${staff['name']} is already assigned to ${device['name']}'),
            ),
          );
        } else {
          staff['assignedICUDevices'].add(device['name']);
        }
      }
    }

    // If there were duplicates, do not save the data
    if (hasDuplicates) {
      print(hasDuplicates);
      return;
    }

    // Merge the new data with the existing data without duplicating staff entries
    for (var newStaff in selectedStaff) {
      // Find if the staff member already exists in the existing assignments
      var existingStaff = existingAssignments.firstWhere(
          (existing) => existing['name'] == newStaff['name'],
          orElse: () =>
              <String, dynamic>{}); // Return an empty map if not found

      if (existingStaff.isNotEmpty) {
        // Merge ICU device assignments
        for (var device in newStaff['assignedICUDevices']) {
          if (!existingStaff['assignedICUDevices'].contains(device)) {
            existingStaff['assignedICUDevices'].add(device);
          }
        }
      } else {
        // Add new staff entry to existing assignments
        existingAssignments.add(newStaff);
      }
    }

    // Save the updated data back to the log file
    await file.writeAsString(jsonEncode(existingAssignments));
    print('Log file saved at $path');

    showDialogBoxForMessage();
  }

  Future<void> _saveLogFile(List<Map<String, dynamic>> updatedStaffData) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/ICU_Admin_Doc/staff_log.json';
    final file = File(path);

    // Read the current contents of the log file
    List<Map<String, dynamic>> currentData = [];

    if (await file.exists()) {
      final contents = await file.readAsString();
      currentData = jsonDecode(contents).cast<Map<String, dynamic>>();
    }

    // Merge the new data with the existing data
    currentData.addAll(updatedStaffData);

    // Save the updated data back to the log file
    await file.writeAsString(jsonEncode(currentData));
    print('Log file saved at $path');
  }

  void _sendSms(String phoneNumber, int duration) async {
    print('Sending SMS to $phoneNumber in $duration seconds...');
    // Simulate SMS sending here
  }

  void showDialogBoxForMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Dialog Box"),
          content: const Text("Assigned successfully"),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                setState(() {
                  for (var staff in staffData) {
                    staff['selected'] = false;
                  }
                  for (var device in icuDevicesData) {
                    device['selected'] = false;
                  }
                  isAnySelected = false;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteStaff(int index) async {
    setState(() {
      staffData.removeAt(index);
    });

    // Save updated staff data to the file
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/staff_data.json');
    await file.writeAsString(jsonEncode(staffData));

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Staff deleted successfully')),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Staff'),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(20.0),
              padding: const EdgeInsets.all(10.0),
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
                        DataCell(GestureDetector(
                            onTap: () => _onRowTap(item),
                            child: Text(item['name'] ?? ''))),
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
              margin: const EdgeInsets.all(20.0),
              padding: const EdgeInsets.all(10.0),
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
                    DataColumn(label: Text('Designation')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: staffData.map((item) {
                    int index = staffData.indexOf(item);
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
                        DataCell(Text(item['designation'] ?? '')),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteStaff(index),
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
              child: const Icon(Icons.send),
            )
          : null,
    );
  }
}




































/*import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AssignPage extends StatefulWidget {
  const AssignPage({super.key});

  @override
  AssignPageState createState() => AssignPageState();
}

class AssignPageState extends State<AssignPage> {
  List<Map<String, dynamic>> staffData = [];
  final List<Map<String, dynamic>> icuDevicesData = List.generate(5, (index) {
    return {
      'name': 'ICU device ${index + 1}',
      'selected': false,
    };
  });

  bool isAnySelected = false;
  int _selectedDuration = 1;

  @override
  void initState() {
    super.initState();
    loadStaffData();
  }

  Future<void> loadStaffData() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/staff_data.json');

    if (await file.exists()) {
      final contents = await file.readAsString();
      final List<dynamic> jsonData = jsonDecode(contents);

      setState(() {
        staffData = jsonData
            .map((item) {
              return {
                'name': item['name'],
                'phone': item['phone'],
                'designation': item['designation'],
                'selected': false,
                'assignedICUDevices': [
                  'assignedICUDevices'
                ], // Add this field to store assigned ICU devices
              };
            })
            .toList()
            .cast<Map<String, dynamic>>();
      });
    }
  }

  void _onCheckboxChanged(bool? value, int index, bool isStaff) {
    setState(() {
      if (isStaff) {
        staffData[index]['selected'] = value ?? false;
        isAnySelected = staffData.any((item) => item['selected']);
      } else {
        icuDevicesData[index]['selected'] = value ?? false;
      }
    });
  }

  void _onSendButtonPressed() async {
    List<Map<String, dynamic>> selectedStaff =
        staffData.where((item) => item['selected']).toList();
    List<Map<String, dynamic>> selectedICUDevices =
        icuDevicesData.where((item) => item['selected']).toList();

    // Assign selected ICU devices to selected staff members
    for (var staff in selectedStaff) {
      staff['assignedICUDevices'] =
          selectedICUDevices.map((device) => device['name']).toList();
    }

    // Save updated staff data to the log file
    await _saveLogFile(selectedStaff);

    showDialogBoxForMessage();
  }

  Future<void> _saveLogFile(List<Map<String, dynamic>> updatedStaffData) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/ICU_Admin_Doc/staff_log.json';
    final file = File(path);
    await file.writeAsString(jsonEncode(updatedStaffData));
    print('Log file saved at $path');
  }

  void _sendSms(String phoneNumber, int duration) async {
    print('Sending SMS to $phoneNumber in $duration seconds...');
    // Simulate SMS sending here
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
        title: const Text('Assign Staff'),
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
                    DataColumn(label: Text('Designation')),
                  ],
                  rows: staffData.map((item) {
                    int index = staffData.indexOf(item);
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
                        DataCell(Text(item['designation'] ?? '')),
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

*/




































