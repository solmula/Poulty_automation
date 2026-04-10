import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../utils/firebase_paths.dart';

class ThresholdProvider extends ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  double tempFanLow = 25.0;
  double tempFanHigh = 27.0;
  double tempHeatOn = 16.0;
  double nh3Warn = 10.0;
  double nh3High = 20.0;
  double nh3Critical = 35.0;
  double co2High = 3000.0;
  double rhHigh = 72.0;
  double waterPumpOn = 30.0;

  ThresholdProvider() {
    _startListening();
  }

  void _startListening() {
    _db.ref(FirebasePaths.thresholds).onValue.listen((event) {
      if (event.snapshot.value != null) {
        final json = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        tempFanLow = (json['temp_fan_low'] ?? 25.0).toDouble();
        tempFanHigh = (json['temp_fan_high'] ?? 27.0).toDouble();
        tempHeatOn = (json['temp_heat_on'] ?? 16.0).toDouble();
        nh3Warn = (json['nh3_warn'] ?? 10.0).toDouble();
        nh3High = (json['nh3_high'] ?? 20.0).toDouble();
        nh3Critical = (json['nh3_critical'] ?? 35.0).toDouble();
        co2High = (json['co2_high'] ?? 3000.0).toDouble();
        rhHigh = (json['rh_high'] ?? 72.0).toDouble();
        waterPumpOn = (json['water_pump_on'] ?? 30.0).toDouble();
        notifyListeners();
      }
    });
  }

  Color tempColor(double value) {
    if (value >= tempFanHigh) return Colors.red;
    if (value >= tempFanLow) return Colors.orange;
    if (value <= tempHeatOn) return Colors.blue;
    return Colors.green;
  }

  Color nh3Color(double value) {
    if (value >= nh3Critical) return Colors.red;
    if (value >= nh3High) return Colors.orange;
    if (value >= nh3Warn) return Colors.yellow.shade700;
    return Colors.green;
  }

  Color co2Color(double value) {
    if (value >= co2High) return Colors.red;
    if (value >= co2High * 0.8) return Colors.orange;
    return Colors.green;
  }

  Color rhColor(double value) {
    if (value >= rhHigh) return Colors.red;
    if (value >= rhHigh * 0.9) return Colors.orange;
    return Colors.green;
  }

  Color waterColor(double value) {
    if (value < 20) return Colors.red;
    if (value < 30) return Colors.orange;
    return Colors.green;
  }
}