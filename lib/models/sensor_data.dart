class SensorData {
  final double tempAvg;
  final double tempMin;
  final double tempMax;
  final double tempZ1;
  final double tempZ2;
  final double tempZ3;
  final double rhAvg;
  final double nh3Max;
  final double co2Avg;
  final double lightAvg;
  final String fanSpeed;
  final bool heater;
  final String lights;
  final int timestamp;
  final double h1WaterPct;
  final double h2WaterPct;
  final double h1FeedKg;
  final double h2FeedKg;
  final int totalEggsToday;
  final double layingRate;
  final bool nodeAOnline;
  final bool nodeBOnline;

  SensorData({
    required this.tempAvg,
    required this.tempMin,
    required this.tempMax,
    required this.tempZ1,
    required this.tempZ2,
    required this.tempZ3,
    required this.rhAvg,
    required this.nh3Max,
    required this.co2Avg,
    required this.lightAvg,
    required this.fanSpeed,
    required this.heater,
    required this.lights,
    required this.timestamp,
    required this.h1WaterPct,
    required this.h2WaterPct,
    required this.h1FeedKg,
    required this.h2FeedKg,
    required this.totalEggsToday,
    required this.layingRate,
    required this.nodeAOnline,
    required this.nodeBOnline,
  });

  factory SensorData.fromJson(Map<dynamic, dynamic> json) {
    final climate = json['climate'] ?? {};
    final h1 = json['h1'] ?? {};
    final h2 = json['h2'] ?? {};
    final eggs = json['eggs'] ?? {};
    final system = json['system'] ?? {};
    return SensorData(
      tempAvg: (climate['temp_avg'] ?? 0).toDouble(),
      tempMin: (climate['temp_min'] ?? 0).toDouble(),
      tempMax: (climate['temp_max'] ?? 0).toDouble(),
      tempZ1: (climate['temp_z1'] ?? 0).toDouble(),
      tempZ2: (climate['temp_z2'] ?? 0).toDouble(),
      tempZ3: (climate['temp_z3'] ?? 0).toDouble(),
      rhAvg: (climate['rh_avg'] ?? 0).toDouble(),
      nh3Max: (climate['nh3_max'] ?? 0).toDouble(),
      co2Avg: (climate['co2_avg'] ?? 0).toDouble(),
      lightAvg: (climate['light_avg'] ?? 0).toDouble(),
      fanSpeed: climate['fan_speed'] ?? '--',
      heater: climate['heater'] ?? false,
      lights: climate['lights'] ?? '--',
      timestamp: (json['timestamp'] ?? 0).toInt(),
      h1WaterPct: (h1['water_pct'] ?? 0).toDouble(),
      h2WaterPct: (h2['water_pct'] ?? 0).toDouble(),
      h1FeedKg: (h1['feed_kg'] ?? 0).toDouble(),
      h2FeedKg: (h2['feed_kg'] ?? 0).toDouble(),
      totalEggsToday: (eggs['total_today'] ?? 0).toInt(),
      layingRate: (eggs['laying_rate'] ?? 0).toDouble(),
      nodeAOnline: system['node_a_online'] ?? false,
      nodeBOnline: system['node_b_online'] ?? false,
    );
  }
}