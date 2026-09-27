import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/l10n_extensions.dart';

/// Открывает маршрут до точки во внешнем приложении Google Maps (или в браузере,
/// если приложения нет) — без какого-либо API-ключа, обычная диплинк-ссылка.
Future<void> openDirections(BuildContext context, double latitude, double longitude) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
  );
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('maps_launcher.open_failed'))),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tArgs('maps_launcher.error_message', {'error': '$e'}))));
    }
  }
}
