import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/live_data_provider.dart';
import '../../providers/threshold_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LiveDataProvider()),
        ChangeNotifierProvider(create: (_) => ThresholdProvider()),
      ],
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final live = Provider.of<LiveDataProvider>(context);
    final thresh = Provider.of<ThresholdProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Poultry House'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: live.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stale data banner
                  if (live.isStale)
                    _StaleBanner(lastUpdate: live.lastUpdateText),

                  // Node offline banner
                  if (live.data != null &&
                      (!live.data!.nodeAOnline || !live.data!.nodeBOnline))
                    _OfflineBanner(
                      nodeA: live.data!.nodeAOnline,
                      nodeB: live.data!.nodeBOnline,
                    ),

                  // Climate section
                  _SectionHeader(title: 'Climate', icon: Icons.thermostat),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: _SensorCard(
                        label: 'Temperature',
                        value: live.data != null
                            ? '${live.data!.tempAvg.toStringAsFixed(1)}°C'
                            : '--',
                        subtitle:
                            'Min ${live.data?.tempMin.toStringAsFixed(1) ?? '--'} / Max ${live.data?.tempMax.toStringAsFixed(1) ?? '--'}',
                        icon: Icons.device_thermostat,
                        color: live.data != null
                            ? thresh.tempColor(live.data!.tempAvg)
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SensorCard(
                        label: 'Humidity',
                        value: live.data != null
                            ? '${live.data!.rhAvg.toStringAsFixed(1)}%RH'
                            : '--',
                        icon: Icons.water_drop,
                        color: live.data != null
                            ? thresh.rhColor(live.data!.rhAvg)
                            : Colors.grey,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _SensorCard(
                        label: 'NH₃',
                        value: live.data != null
                            ? '${live.data!.nh3Max.toStringAsFixed(1)} ppm'
                            : '--',
                        icon: Icons.air,
                        color: live.data != null
                            ? thresh.nh3Color(live.data!.nh3Max)
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SensorCard(
                        label: 'CO₂',
                        value: live.data != null
                            ? '${live.data!.co2Avg.toStringAsFixed(0)} ppm'
                            : '--',
                        icon: Icons.cloud,
                        color: live.data != null
                            ? thresh.co2Color(live.data!.co2Avg)
                            : Colors.grey,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  _SensorCard(
                    label: 'Light Intensity',
                    value: live.data != null
                        ? '${live.data!.lightAvg.toStringAsFixed(1)} lux'
                        : '--',
                    icon: Icons.light_mode,
                    color: Colors.amber,
                    wide: true,
                  ),

                  const SizedBox(height: 20),

                  // Actuators section
                  _SectionHeader(title: 'Actuators', icon: Icons.settings),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: _ActuatorCard(
                        label: 'Fan Speed',
                        value: live.data?.fanSpeed ?? '--',
                        icon: Icons.wind_power,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActuatorCard(
                        label: 'Heater',
                        value: live.data != null
                            ? (live.data!.heater ? 'ON' : 'OFF')
                            : '--',
                        icon: Icons.local_fire_department,
                        isOn: live.data?.heater ?? false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActuatorCard(
                        label: 'Lights',
                        value: live.data?.lights ?? '--',
                        icon: Icons.lightbulb,
                        isOn: live.data?.lights == 'ON',
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // Production section
                  _SectionHeader(title: 'Production', icon: Icons.egg_alt),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: _SensorCard(
                        label: 'Eggs Today',
                        value: '${live.data?.totalEggsToday ?? '--'}',
                        icon: Icons.egg,
                        color: Colors.brown,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SensorCard(
                        label: 'Laying Rate',
                        value: live.data != null
                            ? '${live.data!.layingRate.toStringAsFixed(1)}%'
                            : '--',
                        icon: Icons.percent,
                        color: (live.data?.layingRate ?? 0) >= 90
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // Feed & Water section
                  _SectionHeader(
                      title: 'Feed & Water', icon: Icons.water_drop),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: _WaterCard(
                        label: 'H1 Water',
                        percent: live.data?.h1WaterPct ?? 0,
                        color: thresh.waterColor(live.data?.h1WaterPct ?? 0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _WaterCard(
                        label: 'H2 Water',
                        percent: live.data?.h2WaterPct ?? 0,
                        color: thresh.waterColor(live.data?.h2WaterPct ?? 0),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 12),

                  // Last updated
                  Center(
                    child: Text(
                      'Last updated: ${live.lastUpdateText}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
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

class _StaleBanner extends StatelessWidget {
  final String lastUpdate;
  const _StaleBanner({required this.lastUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Data may be outdated — last update $lastUpdate',
            style: const TextStyle(color: Colors.orange),
          ),
        ),
      ]),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final bool nodeA;
  final bool nodeB;
  const _OfflineBanner({required this.nodeA, required this.nodeB});

  @override
  Widget build(BuildContext context) {
    final offlineNode = !nodeA ? 'A' : 'B';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.red),
        const SizedBox(width: 8),
        Text(
          'Node $offlineNode offline — check hardware',
          style: const TextStyle(color: Colors.red),
        ),
      ]),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool wide;

  const _SensorCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6))),
        ]),
        const SizedBox(height: 8),
        Text(value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
        if (subtitle != null)
          Text(subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5))),
      ]),
    );
  }
}

class _ActuatorCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isOn;

  const _ActuatorCard({
    required this.label,
    required this.value,
    required this.icon,
    this.isOn = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isOn ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6)),
            textAlign: TextAlign.center),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

class _WaterCard extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;

  const _WaterCard(
      {required this.label, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 8),
        Text('${percent.toStringAsFixed(0)}%',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ]),
    );
  }
}