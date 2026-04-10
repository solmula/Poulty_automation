import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/firebase_paths.dart';

class OverrideScreen extends StatefulWidget {
  const OverrideScreen({super.key});

  @override
  State<OverrideScreen> createState() => _OverrideScreenState();
}

class _OverrideScreenState extends State<OverrideScreen> {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Current command state
  String _fanOverride = 'AUTO';
  bool _heaterOverride = false;
  String _lightsOverride = 'AUTO';
  bool _pending = false;
  bool _isLoading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _db.ref(FirebasePaths.commands).onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        final json =
            Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _fanOverride = json['fan_override'] ?? 'AUTO';
          _heaterOverride = json['heater_override'] ?? false;
          _lightsOverride = json['lights_override'] ?? 'AUTO';
          _pending = json['pending'] ?? false;
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

  Future<void> _sendCommand(Map<String, dynamic> updates) async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() => _sending = true);
    try {
      await _db.ref(FirebasePaths.commands).update({
        ...updates,
        'pending': true,
        'issued_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'expires_at':
            (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 300,
        'issued_by': user?.email ?? 'unknown',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Command sent — waiting for ESP32'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send command'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _triggerAction(String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text('Are you sure you want to trigger $action?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed == true) {
      await _sendCommand({action: true});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Manual Override'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Pending banner
                if (_pending)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.orange),
                      ),
                      SizedBox(width: 10),
                      Text('Command pending — waiting for ESP32',
                          style: TextStyle(color: Colors.orange)),
                    ]),
                  ),

                // Fan Override
                _SectionHeader(
                    title: 'Fan Speed', icon: Icons.wind_power),
                const SizedBox(height: 8),
                _SegmentCard(
                  options: const ['AUTO', 'LOW', 'MEDIUM', 'HIGH', 'OFF'],
                  selected: _fanOverride,
                  onChanged: _sending
                      ? null
                      : (val) {
                          setState(() => _fanOverride = val);
                          _sendCommand({'fan_override': val});
                        },
                  colors: const {
                    'AUTO': Colors.blue,
                    'LOW': Colors.green,
                    'MEDIUM': Colors.orange,
                    'HIGH': Colors.red,
                    'OFF': Colors.grey,
                  },
                ),

                const SizedBox(height: 20),

                // Heater Override
                _SectionHeader(
                    title: 'Heater',
                    icon: Icons.local_fire_department),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _heaterOverride
                            ? Colors.red.withOpacity(0.4)
                            : Colors.grey.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.local_fire_department,
                        color:
                            _heaterOverride ? Colors.red : Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _heaterOverride ? 'Heater ON' : 'Heater OFF',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _heaterOverride
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    ),
                    Switch(
                      value: _heaterOverride,
                      activeColor: Colors.red,
                      onChanged: _sending
                          ? null
                          : (val) {
                              setState(() => _heaterOverride = val);
                              _sendCommand({'heater_override': val});
                            },
                    ),
                  ]),
                ),

                const SizedBox(height: 20),

                // Lights Override
                _SectionHeader(
                    title: 'Lights', icon: Icons.lightbulb),
                const SizedBox(height: 8),
                _SegmentCard(
                  options: const ['AUTO', 'ON', 'OFF', 'DIM'],
                  selected: _lightsOverride,
                  onChanged: _sending
                      ? null
                      : (val) {
                          setState(() => _lightsOverride = val);
                          _sendCommand({'lights_override': val});
                        },
                  colors: const {
                    'AUTO': Colors.blue,
                    'ON': Colors.amber,
                    'DIM': Colors.orange,
                    'OFF': Colors.grey,
                  },
                ),

                const SizedBox(height: 20),

                // Trigger Actions
                _SectionHeader(
                    title: 'Trigger Actions',
                    icon: Icons.play_circle_outline),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: _TriggerButton(
                      label: 'Trigger\nFeeder',
                      icon: Icons.restaurant,
                      color: Colors.brown,
                      onPressed: _sending
                          ? null
                          : () => _triggerAction('trigger_feeder'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TriggerButton(
                      label: 'Trigger\nWater Pump',
                      icon: Icons.water_drop,
                      color: Colors.blue,
                      onPressed: _sending
                          ? null
                          : () => _triggerAction('trigger_pump'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TriggerButton(
                      label: 'Trigger\nManure',
                      icon: Icons.clean_hands,
                      color: Colors.green,
                      onPressed: _sending
                          ? null
                          : () => _triggerAction('trigger_manure'),
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                // Reset all to AUTO
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _sending
                        ? null
                        : () {
                            setState(() {
                              _fanOverride = 'AUTO';
                              _heaterOverride = false;
                              _lightsOverride = 'AUTO';
                            });
                            _sendCommand({
                              'fan_override': 'AUTO',
                              'heater_override': false,
                              'lights_override': 'AUTO',
                            });
                          },
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset All to AUTO'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
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

class _SegmentCard extends StatelessWidget {
  final List<String> options;
  final String selected;
  final void Function(String)? onChanged;
  final Map<String, Color> colors;

  const _SegmentCard({
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) {
          final isSelected = selected == opt;
          final color = colors[opt] ?? Colors.grey;
          return GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(opt),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color:
                        isSelected ? color : Colors.grey.withOpacity(0.3),
                    width: isSelected ? 2 : 1),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey,
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TriggerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _TriggerButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 28),
        const SizedBox(height: 6),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}