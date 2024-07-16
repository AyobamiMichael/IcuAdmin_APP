import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AssignPage extends StatefulWidget {
  const AssignPage({super.key});

  @override
  AssignPageState createState() => AssignPageState();
}

class AssignPageState extends State<AssignPage> {
  final List<Map<String, dynamic>> staffData = List.generate(5, (index) {
    return {
      'name': 'Staff ${index + 1}',
      'phone': '08063113997${index}',
      'designation': index % 2 == 0 ? 'Nurse' : 'Doctor',
      'selected': false
    };
  });

  bool isAnySelected = false;
  int _selectedDuration = 1;

  void _onCheckboxChanged(bool? value, int index) {
    setState(() {
      staffData[index]['selected'] = value ?? false;
      isAnySelected = staffData.any((item) => item['selected']);
    });
  }

  void _onSendButtonPressed() {
    // Handle "Send" button press
    List<Map<String, dynamic>> selectedStaff =
        staffData.where((item) => item['selected']).toList();
    print('Selected Staff: $selectedStaff');

    // Example sending SMS
    for (var staff in selectedStaff) {
      _sendSms(staff['phone'], _selectedDuration);
    }
    showDialogBox();
  }

  void _sendSms(String phoneNumber, int duration) {
    // Simulate sending SMS
    print('Sending SMS to $phoneNumber in $duration seconds...');
    // In a real app, you would integrate with an SMS API
  }

  void showDialogBox() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Dialog Box"),
          content: Text("Message not sent"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                // Handle Cancel button click
                Navigator.of(context).pop();
                // Add your logic for the Cancel action here
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
      body: Stack(
        children: [
          if (isAnySelected)
            Positioned(
              left: 20.0,
              top: 10.0,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _onSendButtonPressed,
                    child: Text('Send'),
                  ),
                  const SizedBox(width: 20),
                  DropdownButton<int>(
                    value: _selectedDuration,
                    items: List.generate(10, (index) {
                      return DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text('${index + 1} sec'),
                      );
                    }),
                    onChanged: isAnySelected
                        ? (value) {
                            setState(() {
                              _selectedDuration = value!;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
          Positioned(
            top: isAnySelected ? 50.0 : 20.0,
            left: 20.0,
            right: 20.0,
            child: Container(
              width: 750, // Adjust the width as needed
              height: 400, // Adjust the height as needed
              margin: EdgeInsets.all(20.0), // Adjust the margin as needed
              padding: EdgeInsets.all(10.0), // Adjust the padding as needed
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
                              _onCheckboxChanged(value, index);
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
    );
  }
}
