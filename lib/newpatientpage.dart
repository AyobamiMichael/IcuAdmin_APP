import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Newpatientpage extends StatefulWidget {
  const Newpatientpage({super.key});

  @override
  State<Newpatientpage> createState() => _NewpatientpageState();
}

class _NewpatientpageState extends State<Newpatientpage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedGender = 'Male'; // Default gender
  String idNumber = '';
  List<Map<String, dynamic>> patientList = [];

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
      });
    }
  }

  String generateRandomId({int length = 6}) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
          length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  void _savePatient() async {
    if (_formKey.currentState!.validate()) {
      // Validate phone number length
      if (_phoneController.text.length != 11) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number must be 11 digits')),
        );
        return;
      }

      // Validate name (only alphabets)
      RegExp nameRegExp = RegExp(r'^[a-zA-Z ]+$');
      if (!nameRegExp.hasMatch(_nameController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid name')),
        );
        return;
      }

      // Generate ID number
      setState(() {
        idNumber = generateRandomId(length: 8); // Adjust length as needed
        //print(idNumber);
      });

      // Form is validated, save patient details
      Map<String, dynamic> patientData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'gender': _selectedGender,
        'idNumber': idNumber,
      };

      setState(() {
        print(idNumber);
        patientList.add(patientData);
      });

      // Convert list to JSON
      String jsonData = jsonEncode(patientList);

      // Save JSON data to a file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/patient_data.json');
      await file.writeAsString(jsonData);

      // Show confirmation or navigate to another page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient details saved successfully')),
      );

      // Clear form fields after saving
      _nameController.clear();
      _phoneController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Patient Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter name';
                  }
                  // Validate name (only alphabets)
                  RegExp nameRegExp = RegExp(r'^[a-zA-Z ]+$');
                  if (!nameRegExp.hasMatch(value)) {
                    return 'Please enter a valid name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  // Validate phone number length
                  if (value.length != 11) {
                    return 'Phone number must be 11 digits';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                onChanged: (newValue) {
                  setState(() {
                    _selectedGender = newValue!;
                  });
                },
                items: ['Male', 'Female']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _savePatient,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
