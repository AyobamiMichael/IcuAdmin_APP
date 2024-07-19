import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  Future<List<Map<String, dynamic>>> _loadLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/ICU_Admin_Doc/staff_log.json';
    //print(path);
    final file = File(path);
    if (await file.exists()) {
      final contents = await file.readAsString();
      return List<Map<String, dynamic>>.from(jsonDecode(contents));
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Page'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadLogFile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No logs found.'));
          }
          final logs = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3,
            ),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${log['name']}'),
                      Text('Phone: ${log['phone']}'),
                      Text('Designation: ${log['designation']}'),
                      Text('ICU Device: ${log['assignedICUDevices'] ?? 'N/A'}'),
                      Text('Time: ${log['time']}')
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
