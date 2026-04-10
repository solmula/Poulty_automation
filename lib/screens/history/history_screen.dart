import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String _selectedMetric = 'temp_avg';

  final Map<String, String> _metricLabels = {
    'temp_avg': 'Temperature (°C)',
    'rh_avg': 'Humidity (%RH)',
    'nh3_max': 'NH₃ (ppm)',
    'co2_avg': 'CO₂ (ppm)',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final snap = await _firestore
          .collection('sensor_history')
          .orderBy('timestamp', descending: true)
          .limit(48)
          .get();
      if (mounted) {
        setState(() {
          _records = snap.docs.map((d) => d.data()).toList().reversed.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<FlSpot> _getSpots() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _records.length; i++) {
      final val = (_records[i][_selectedMetric] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), val));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Charts'),
            Tab(text: 'Daily Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChartsTab(theme),
          _buildReportsTab(theme),
        ],
      ),
    );
  }

  Widget _buildChartsTab(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart,
                size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No history data yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Data will appear once ESP32 starts logging',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey)),
          ],
        ),
      );
    }

    final spots = _getSpots();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Metric selector
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Wrap(
            spacing: 8,
            children: _metricLabels.entries.map((e) {
              final isSelected = _selectedMetric == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: isSelected,
                onSelected: (_) =>
                    setState(() => _selectedMetric = e.key),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Chart
        Container(
          height: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.grey.withOpacity(0.15),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (_) => FlLine(
                  color: Colors.grey.withOpacity(0.1),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (val, _) => Text(
                      val.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 2.5,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color:
                        theme.colorScheme.primary.withOpacity(0.08),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Stats summary
        if (_records.isNotEmpty) ...[
          Row(children: [
            Expanded(
                child: _StatCard(
              label: 'Min',
              value: _records
                  .map((r) => (r[_selectedMetric] ?? 0).toDouble())
                  .reduce((a, b) => a < b ? a : b)
                  .toStringAsFixed(1),
              color: Colors.blue,
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _StatCard(
              label: 'Max',
              value: _records
                  .map((r) => (r[_selectedMetric] ?? 0).toDouble())
                  .reduce((a, b) => a > b ? a : b)
                  .toStringAsFixed(1),
              color: Colors.red,
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _StatCard(
              label: 'Avg',
              value: (_records
                          .map((r) =>
                              (r[_selectedMetric] ?? 0).toDouble())
                          .reduce((a, b) => a + b) /
                      _records.length)
                  .toStringAsFixed(1),
              color: Colors.green,
            )),
          ]),
        ],
      ],
    );
  }

  Widget _buildReportsTab(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('daily_reports')
          .orderBy('date', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description,
                    size: 64, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('No daily reports yet',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['date'] ?? '--',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 16),
                  Row(children: [
                    _ReportItem(
                        label: 'Eggs',
                        value: '${data['total_eggs'] ?? 0}'),
                    _ReportItem(
                        label: 'Laying',
                        value:
                            '${(data['laying_rate_pct'] ?? 0).toStringAsFixed(1)}%'),
                    _ReportItem(
                        label: 'Feed',
                        value:
                            '${(data['feed_consumed_kg'] ?? 0).toStringAsFixed(1)}kg'),
                    _ReportItem(
                        label: 'FCR',
                        value:
                            '${(data['fcr'] ?? 0).toStringAsFixed(2)}'),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    _ReportItem(
                        label: 'Avg Temp',
                        value:
                            '${(data['avg_temp'] ?? 0).toStringAsFixed(1)}°C'),
                    _ReportItem(
                        label: 'Max NH₃',
                        value:
                            '${(data['max_nh3'] ?? 0).toStringAsFixed(1)}ppm'),
                    _ReportItem(
                        label: 'Light hrs',
                        value:
                            '${(data['light_hours'] ?? 0).toStringAsFixed(1)}h'),
                    _ReportItem(
                        label: 'Alerts',
                        value: '${data['alerts_count'] ?? 0}'),
                  ]),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

class _ReportItem extends StatelessWidget {
  final String label;
  final String value;
  const _ReportItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(children: [
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey)),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}