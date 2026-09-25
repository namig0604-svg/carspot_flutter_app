import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_colors.dart';
import '../utils/location_helper.dart';

class _WeatherAlert {
  final String message;
  final IconData icon;
  final Color color;
  const _WeatherAlert(this.message, this.icon, this.color);
}

/// Баннер погодного предупреждения для водителей: гололёд, туман, сильный
/// дождь/снег по текущей геопозиции. Данные — бесплатный Open-Meteo API,
/// ключ не нужен. Если не удалось определить позицию или погода спокойная —
/// баннер просто не показывается (виджет схлопывается в SizedBox.shrink()).
class WeatherAlertBanner extends StatefulWidget {
  const WeatherAlertBanner({Key? key}) : super(key: key);

  @override
  State<WeatherAlertBanner> createState() => _WeatherAlertBannerState();
}

class _WeatherAlertBannerState extends State<WeatherAlertBanner> {
  String? _message;
  IconData _icon = Icons.warning_amber_rounded;
  Color _color = Colors.amber;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final position = await determineCurrentPosition();
      if (position == null) return;

      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${position.latitude}&longitude=${position.longitude}'
        '&current=temperature_2m,weather_code,precipitation,wind_speed_10m'
        '&timezone=auto',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return;

      final code = current['weather_code'] as int?;
      final temp = (current['temperature_2m'] as num?)?.toDouble();
      final precipitation = (current['precipitation'] as num?)?.toDouble() ?? 0;
      final windSpeed = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0;

      final alert = _buildAlert(code: code, temp: temp, precipitation: precipitation, windSpeed: windSpeed);
      if (alert != null && mounted) {
        setState(() {
          _message = alert.message;
          _icon = alert.icon;
          _color = alert.color;
        });
      }
    } catch (_) {
      // Тихо игнорируем — баннер просто не появится, это не критичная функция.
    }
  }

  _WeatherAlert? _buildAlert({int? code, double? temp, required double precipitation, required double windSpeed}) {
    const fogCodes = {45, 48};
    const freezingCodes = {56, 57, 66, 67};
    const thunderCodes = {95, 96, 99};
    const heavySnowCodes = {75, 86};
    const heavyRainCodes = {65, 82};

    if (code != null && freezingCodes.contains(code)) {
      return _WeatherAlert('На дороге возможен гололёд — переохлаждённый дождь', Icons.ac_unit, AppColors.blue);
    }
    if (temp != null && temp <= 0 && precipitation > 0) {
      return _WeatherAlert('Возможен гололёд — осадки при температуре около нуля', Icons.ac_unit, AppColors.blue);
    }
    if (code != null && fogCodes.contains(code)) {
      return _WeatherAlert('Туман — снизьте скорость, включите противотуманки', Icons.foggy, Colors.grey);
    }
    if (code != null && thunderCodes.contains(code)) {
      return _WeatherAlert('Гроза — возможен сильный ливень и порывы ветра', Icons.thunderstorm, Colors.deepPurple);
    }
    if (code != null && heavySnowCodes.contains(code)) {
      return _WeatherAlert('Сильный снегопад — дороги могут быть скользкими', Icons.snowing, AppColors.blue);
    }
    if (code != null && heavyRainCodes.contains(code)) {
      return _WeatherAlert('Сильный дождь — риск аквапланирования', Icons.water_drop, AppColors.blue);
    }
    if (windSpeed >= 50) {
      return _WeatherAlert('Сильный порывистый ветер — осторожно на трассе', Icons.air, Colors.amber);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_message == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _message!,
              style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            color: _color,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _message = null),
          ),
        ],
      ),
    );
  }
}
