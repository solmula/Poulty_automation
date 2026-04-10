import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';
import '../utils/firebase_paths.dart';

class LiveDataProvider extends ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  SensorData? _data;
  bool _isLoading = true;
  bool _isStale = false;
  String? _error;

  SensorData? get data => _data;
  bool get isLoading => _isLoading;
  bool get isStale => _isStale;
  String? get error => _error;

  int get activeAlertCount => 0;

  LiveDataProvider() {
    _startListening();
  }

  void _startListening() {
    _db.ref(FirebasePaths.live).onValue.listen((event) {
      try {
        if (event.snapshot.value != null) {
          final json = Map<dynamic, dynamic>.from(
              event.snapshot.value as Map);
          _data = SensorData.fromJson(json);
          _checkStale();
        }
        _isLoading = false;
        _error = null;
      } catch (e) {
        _error = 'Failed to parse data';
        _isLoading = false;
      }
      notifyListeners();
    }, onError: (error) {
      _error = 'Connection error';
      _isLoading = false;
      notifyListeners();
    });

    // Timeout fallback — stop loading after 8 seconds no matter what
    Future.delayed(const Duration(seconds: 8), () {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _checkStale() {
    if (_data == null) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _isStale = (now - _data!.timestamp) > 300;
  }

  String get lastUpdateText {
    if (_data == null) return 'Never';
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = now - _data!.timestamp;
    if (diff < 60) return '${diff}s ago';
    if (diff < 3600) return '${diff ~/ 60}m ago';
    return '${diff ~/ 3600}h ago';
  }
}