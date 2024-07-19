import 'dart:convert';
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
        padding: const EdgeInsets.all(16.0),
        child: filteredPatientList.isEmpty
            ? const Center(
                child: Text('No patients assigned to this ICU device.'))
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Adjust the number of columns as needed
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: filteredPatientList.length,
                itemBuilder: (context, index) {
                  final patient = filteredPatientList[index];

                  return Card(
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name: ${patient['name']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                  );
                },
              ),
      ),
    );
  }
}
