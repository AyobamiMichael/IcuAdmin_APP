import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final TextEditingController _defaultPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  static String? savedPassword;
  static String? defaultPassword;

  @override
  void initState() {
    super.initState();
    _loadSavedPassword();
  }

  Future<void> _loadSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultPassword = 'admin1';
      savedPassword = prefs.getString('admin_password') ?? defaultPassword;
      defaultPassword; // Default password
    });
  }

  Future<void> _saveNewPassword() async {
    if (_defaultPasswordController.text == savedPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_password', _newPasswordController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
      _defaultPasswordController.clear();
      _newPasswordController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Default password is incorrect!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _defaultPasswordController,
              decoration: InputDecoration(
                labelText: 'Enter Default Password',
              ),
              obscureText: true,
            ),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'Enter New Password',
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveNewPassword,
              child: Text('Save New Password'),
            ),
          ],
        ),
      ),
    );
  }
}
