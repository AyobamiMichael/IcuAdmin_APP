import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icu_admin_app/datagrid2.dart';
import 'package:icu_admin_app/patientdetails.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Heartgraph extends StatelessWidget {
  const Heartgraph({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atlantis-UgarSoft')),
      body: const HeartGraph(),
    );
  }
}

class HeartGraph extends StatefulWidget {
  const HeartGraph({super.key});

  @override
  State<HeartGraph> createState() => _HeartGraphState();
}

class _HeartGraphState extends State<HeartGraph> {
  final List<SensorData> _chartData = <SensorData>[];
  Timer? _timer;
  String heartBeat2 = '';
  List<Map<String, dynamic>> icuDevicesData = [];
  List<Map<String, dynamic>> filteredICUdataList = [];

  @override
  void initState() {
    _startTimer();
    super.initState();

    print(PatientdetailspageState.iCUnameSelected);
    loadIcuDataList();
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        loadIcuDataList();
      });
    });
  }

  Future<void> loadIcuDataList() async {
    // Assuming ICUDataGrid2State.icuDataList is already populated
    setState(() {
      icuDevicesData = ICUDataGrid2State.icuDataList.map((icuData) {
        return {
          'name': icuData.icuName,
          'BP': icuData.bp,
          'Temperature': icuData.temperature,
          'Drip Level': icuData.dripLevel.toString(),
          'Heart Rate': icuData.heartRate.toString()
        };
      }).toList();
    });
    // print(ICUDataGrid2State.icuDataList[1].dripLevel);
    filteredICUdataList = icuDevicesData.where((icudata) {
      return icudata['name'] == PatientdetailspageState.iCUnameSelected;
    }).toList();

    print(filteredICUdataList[0]['Drip Level']);
    // print(filteredICUdataList);

    double? pulse = double.tryParse(filteredICUdataList[0]['Heart Rate']);
    if (pulse != null) {
      // Add new data point to the chart
      _chartData.add(SensorData(DateTime.now(), pulse));
      if (_chartData.length > 30) {
        _chartData.removeAt(0);
      }
    }
  }

  void getDataFromArduino() {
    // Assuming `WirelessClassState.listOfSensorValues[2]` contains sensor data
    // heartBeat2 = WirelessClassState.listOfSensorValues[2].substring(22);
    double? pulse = double.tryParse(heartBeat2);
    if (pulse != null) {
      // Add new data point to the chart
      _chartData.add(SensorData(DateTime.now(), pulse));
      if (_chartData.length > 30) {
        _chartData.removeAt(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return Scaffold(
      body: Center(
        child: SizedBox(
          height: 300,
          child: SfCartesianChart(
            backgroundColor: Colors.black,
            primaryXAxis:
                const DateTimeAxis(majorGridLines: MajorGridLines(width: 0)),
            primaryYAxis: const NumericAxis(
              minimum: 0,
              maximum: 120,
              interval: 10,
              majorGridLines: MajorGridLines(width: 0),
            ),
            series: <SplineSeries<SensorData, DateTime>>[
              SplineSeries<SensorData, DateTime>(
                dataSource: _chartData,
                xValueMapper: (SensorData data, _) => data.time,
                yValueMapper: (SensorData data, _) => data.pulse,
                color: Colors.red,
                width: 2,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SensorData {
  final DateTime time;
  final double pulse;

  SensorData(this.time, this.pulse);
}
