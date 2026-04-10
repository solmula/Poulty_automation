import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/firebase_paths.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  bool _isLoading = true;
  bool _saving = false;

  // Threshold controllers
  late TextEditingController _tempFanLow;
  late TextEditingController _tempFanHigh;
  late TextEditingController _tempHeatOn;
  late TextEditingController _nh3Warn;
  late TextEditingController _nh3High;
  late TextEditingController _nh3Critical;
  late TextEditingController _co2High;
  late TextEditingController _rhHigh;
  late TextEditingController _waterPumpOn;

  @override
  void initState() {
    super.initState();
    _tempFanLow = TextEditingController();
    _tempFanHigh = TextEditingController();
    _tempHeatOn = TextEditingController();
    _nh3Warn = TextEditingController();
    _nh3High = TextEditingController();
    _nh3Critical = TextEditingController();
    _co2High = TextEditingController();
    _rhHigh = TextEditingController();
    _waterPumpOn = TextEditingController();
    _loadThresholds();
  }

  @override
  void dispose() {
    _tempFanLow.dispose();
    _tempFanHigh.dispose();
    _tempHeatOn.dispose();
    _nh3Warn.dispose();
    _nh3High.dispose();
    _nh3Critical.dispose();
    _co2High.dispose();
    _rhHigh.dispose();
    _waterPumpOn.dispose();
    super.dispose();
  }

  Future<void> _loadThresholds() async {
    _db.ref(FirebasePaths.thresholds).onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        final json =
            Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _tempFanLow.text = (json['temp_fan_low'] ?? 25.0).toString();
          _tempFanHigh.text = (json['temp_fan_high'] ?? 27.0).toString();
          _tempHeatOn.text = (json['temp_heat_on'] ?? 16.0).toString();
          _nh3Warn.text = (json['nh3_warn'] ?? 10.0).toString();
          _nh3High.text = (json['nh3_high'] ?? 20.0).toString();
          _nh3Critical.text = (json['nh3_critical'] ?? 35.0).toString();
          _co2High.text = (json['co2_high'] ?? 3000.0).toString();
          _rhHigh.text = (json['rh_high'] ?? 72.0).toString();
          _waterPumpOn.text = (json['water_pump_on'] ?? 30.0).toString();
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    });

    Future.delayed(const Duration(seconds: 8), () {
      if (_isLoading && mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _saveThresholds() async {
    setState(() => _saving = true);
    try {
      await _db.ref(FirebasePaths.thresholds).update({
        'temp_fan_low': double.tryParse(_tempFanLow.text) ?? 25.0,
        'temp_fan_high': double.tryParse(_tempFanHigh.text) ?? 27.0,
        'temp_heat_on': double.tryParse(_tempHeatOn.text) ?? 16.0,
        'nh3_warn': double.tryParse(_nh3Warn.text) ?? 10.0,
        'nh3_high': double.tryParse(_nh3High.text) ?? 20.0,
        'nh3_critical': double.tryParse(_nh3Critical.text) ?? 35.0,
        'co2_high': double.tryParse(_co2High.text) ?? 3000.0,
        'rh_high': double.tryParse(_rhHigh.text) ?? 72.0,
        'water_pump_on': double.tryParse(_waterPumpOn.text) ?? 30.0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thresholds saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save thresholds'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Account section
                _SectionHeader(
                    title: 'Account', icon: Icons.person),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primaryContainer,
                      child: Icon(Icons.person,
                          color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user?.email ?? 'Unknown',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          FirebaseAuth.instance.signOut(),
                      child: const Text('Sign Out',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ]),
                ),

                const SizedBox(height: 24),

                // Thresholds section
                _SectionHeader(
                    title: 'Alert Thresholds',
                    icon: Icons.tune),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(children: [
                    _ThresholdField(
                      label: 'Fan ON temp (°C)',
                      controller: _tempFanLow,
                      hint: '25.0',
                    ),
                    _ThresholdField(
                      label: 'Fan HIGH temp (°C)',
                      controller: _tempFanHigh,
                      hint: '27.0',
                    ),
                    _ThresholdField(
                      label: 'Heater ON temp (°C)',
                      controller: _tempHeatOn,
                      hint: '16.0',
                    ),
                    _ThresholdField(
                      label: 'NH₃ Warning (ppm)',
                      controller: _nh3Warn,
                      hint: '10.0',
                    ),
                    _ThresholdField(
                      label: 'NH₃ High (ppm)',
                      controller: _nh3High,
                      hint: '20.0',
                    ),
                    _ThresholdField(
                      label: 'NH₃ Critical (ppm)',
                      controller: _nh3Critical,
                      hint: '35.0',
                    ),
                    _ThresholdField(
                      label: 'CO₂ High (ppm)',
                      controller: _co2High,
                      hint: '3000.0',
                    ),
                    _ThresholdField(
                      label: 'Humidity High (%)',
                      controller: _rhHigh,
                      hint: '72.0',
                    ),
                    _ThresholdField(
                      label: 'Water pump ON (%)',
                      controller: _waterPumpOn,
                      hint: '30.0',
                      isLast: true,
                    ),
                  ]),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _saveThresholds,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Saving...' : 'Save Thresholds'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Icon(icon, size: 18, color: theme.colorScheme.primary),
      const SizedBox(width: 8),
      Text(title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
    ]);
  }
}

class _ThresholdField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool isLast;

  const _ThresholdField({
    required this.label,
    required this.controller,
    required this.hint,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Text(label,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 8),
            ),
          ),
        ),
      ]),
    );
  }
}