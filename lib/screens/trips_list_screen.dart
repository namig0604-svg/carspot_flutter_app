import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../widgets/section_background.dart';
import '../l10n/l10n_extensions.dart';
import 'drive_tracker_screen.dart';
import 'trip_detail_screen.dart';

/// "Поездки": статистика вождения (всего км, время, макс. скорость,
/// разбивка по месяцам) + история прошлых поездок. Точка входа — плитка
/// в "Мой Гараж" (см. car_hub_screen.dart) и кнопка "Начать поездку" здесь.
class TripsListScreen extends StatefulWidget {
  const TripsListScreen({Key? key}) : super(key: key);

  @override
  State<TripsListScreen> createState() => _TripsListScreenState();
}

class _TripsListScreenState extends State<TripsListScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final results = await Future.wait([
        ApiService.get('/api/trips/stats/mine', token: authProvider.accessToken),
        ApiService.get('/api/trips/mine', token: authProvider.accessToken),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] is Map<String, dynamic> ? results[0] as Map<String, dynamic> : null;
        _items = results[1] is Map && results[1]['items'] is List ? results[1]['items'] as List : [];
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startTrip() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DriveTrackerScreen()));
    if (mounted) _load();
  }

  Future<void> _openTrip(Map<String, dynamic> item) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: item['id'] as String)),
    );
    if (deleted == true && mounted) _load();
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}ч ${m}м';
    return '${m}м';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.black, title: Text(context.t('trips_list.title'))),
      backgroundColor: AppColors.scaffoldBg(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startTrip,
        backgroundColor: AppColors.blue,
        icon: const Icon(Icons.play_arrow),
        label: Text(context.t('trips_list.new_trip')),
      ),
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.blue, glowAlignment: Alignment.topRight),
          _isLoading
              ? const Center(child: AppLoader(size: 32))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      if (_stats != null) _buildStatsCard(context, _stats!),
                      const SizedBox(height: 20),
                      if (_items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            context.t('trips_list.empty'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMutedDark),
                          ),
                        )
                      else
                        ..._items.map((raw) {
                          final item = raw as Map<String, dynamic>;
                          final distance = (item['distance_km'] as num?)?.toDouble() ?? 0;
                          final duration = (item['duration_s'] as num?)?.toInt() ?? 0;
                          return Card(
                            color: AppColors.surfaceDark,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const Icon(Icons.route, color: AppColors.blue),
                              title: Text('${distance.toStringAsFixed(1)} км', style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${_formatDate(item['started_at'] as String?)} · ${_formatDuration(duration)}',
                                style: const TextStyle(color: AppColors.textMutedDark),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: AppColors.textMutedDark),
                              onTap: () => _openTrip(item),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, Map<String, dynamic> stats) {
    final totalDistance = (stats['total_distance_km'] as num?)?.toDouble() ?? 0;
    final totalDuration = (stats['total_duration_s'] as num?)?.toInt() ?? 0;
    final totalTrips = (stats['total_trips'] as num?)?.toInt() ?? 0;
    final topSpeed = (stats['top_speed_kmh'] as num?)?.toDouble() ?? 0;
    final monthly = (stats['monthly'] as List? ?? []).map((m) => m as Map<String, dynamic>).toList();
    final maxMonthly = monthly.fold<double>(0, (acc, m) => (m['distance_km'] as num).toDouble() > acc ? (m['distance_km'] as num).toDouble() : acc);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t('trips_list.stats_title'), style: const TextStyle(color: AppColors.textOnDark, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat(context, '${totalDistance.toStringAsFixed(0)} км', context.t('trips_list.stat_total_distance')),
              _miniStat(context, _formatDuration(totalDuration), context.t('trips_list.stat_total_duration')),
              _miniStat(context, '$totalTrips', context.t('trips_list.stat_total_trips')),
              _miniStat(context, '${topSpeed.toStringAsFixed(0)} км/ч', context.t('trips_list.stat_top_speed')),
            ],
          ),
          if (monthly.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(context.t('trips_list.monthly_chart_title'), style: const TextStyle(color: AppColors.textMutedDark, fontSize: 12)),
            const SizedBox(height: 8),
            ...monthly.map((m) {
              final value = (m['distance_km'] as num).toDouble();
              final ratio = maxMonthly > 0 ? value / maxMonthly : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 44, child: Text(_monthLabel(m['month'] as String), style: const TextStyle(color: AppColors.textMutedDark, fontSize: 11))),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 8,
                            backgroundColor: AppColors.surfaceDarkAlt,
                            valueColor: const AlwaysStoppedAnimation(AppColors.blue),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 50, child: Text('${value.toStringAsFixed(0)} км', style: const TextStyle(color: AppColors.textOnDark, fontSize: 11))),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: AppColors.textOnDark, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMutedDark, fontSize: 10)),
        ],
      ),
    );
  }

  String _monthLabel(String ym) {
    const names = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    final parts = ym.split('-');
    if (parts.length != 2) return ym;
    final idx = int.tryParse(parts[1]);
    if (idx == null || idx < 1 || idx > 12) return ym;
    return names[idx - 1];
  }
}
