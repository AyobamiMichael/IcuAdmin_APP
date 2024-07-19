import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class NewStaffPage extends StatefulWidget {
  const NewStaffPage({Key? key}) : super(key: key);

  @override
  _NewStaffPageState createState() => _NewStaffPageState();
}

class _NewStaffPageState extends State<NewStaffPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  String _selectedGender = 'Male'; // Default gender
  String _selectedDesignation = 'Nurse'; // Default designation

  List<Map<String, dynamic>> staffList = [];

  // Function to generate a random alphanumeric string of length `length`
  String generateRandomId({int length = 6}) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
          length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  void _saveStaff() async {
    if (_formKey.currentState!.validate()) {
      // Validate phone number length
      if (_phoneController.text.length != 11) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phone number must be 11 digits')),
        );
        return;
      }

      // Validate name (only alphabets)
      RegExp nameRegExp = RegExp(r'^[a-zA-Z ]+$');
      if (!nameRegExp.hasMatch(_nameController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid name')),
        );
        return;
      }

      // Generate ID number
      String idNumber = generateRandomId(length: 8); // Adjust length as needed

      // Form is validated, save staff details
      Map<String, dynamic> staffData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'gender': _selectedGender,
        'designation': _selectedDesignation,
        'idNumber': idNumber,
      };

      staffList.add(staffData);

      // Convert list to JSON
      String jsonData = jsonEncode(staffList);

      // Save JSON data to a file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/staff_data.json');
      await file.writeAsString(jsonData);

      // Show confirmation or navigate to another page
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Staff details saved successfully')),
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
        title: Text('New Staff Entry'),
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
                decoration: InputDecoration(labelText: 'Name'),
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
                decoration: InputDecoration(labelText: 'Phone'),
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
                decoration: InputDecoration(labelText: 'Gender'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedDesignation,
                onChanged: (newValue) {
                  setState(() {
                    _selectedDesignation = newValue!;
                  });
                },
                items: ['Nurse', 'Doctor', 'Other']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Designation'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _saveStaff,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
