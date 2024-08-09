import 'package:flutter/material.dart';
import 'package:icu_admin_app/datagrid.dart';
import 'package:icu_admin_app/datagrid2.dart';
import 'package:icu_admin_app/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IcuAdminApp extends StatelessWidget {
  const IcuAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'AtlantisUgarSoft',
      home: Scaffold(
        body: AdminLoginWidget(),
      ),
    );
  }
}

class AdminLoginWidget extends StatefulWidget {
  const AdminLoginWidget({super.key});

  @override
  State<AdminLoginWidget> createState() => _AdminLoginWidgetState();
}

class _AdminLoginWidgetState extends State<AdminLoginWidget> {
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  static String? savedPassword;

  @override
  void initState() {
    _loadSavedPassword();
    super.initState();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      final password = _passwordController.text;
      // Add your login logic here
      print('Password entered: $password');
    }
  }

  Future<void> _loadSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedPassword =
          prefs.getString('admin_password') ?? 'admin1'; // Default password
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 320,
              top: 180,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(
                    child: Text(
                      'ICU ADMIN',
                      style: TextStyle(
                        fontSize: 70,
                        color: Colors.blue,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 700,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Enter Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters long';
                        }
                        if (value == savedPassword) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ICUDataGrid2()),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Positioned(
              left: 600, // Adjust the x coordinate as needed
              top: 400, // Adjust the y coordinate as needed
              child: SizedBox(
                width: 170,
                height: 50,
                child: ElevatedButton(
                  onPressed: _login,
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
