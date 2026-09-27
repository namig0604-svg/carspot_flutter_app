/// Переводы для мелких утилит без собственного экрана (maps_launcher.dart,
/// push_service.dart) — раньше эти строки были захардкожены на русском прямо
/// в коде утилиты и никогда не подключались к системе переводов.
///
/// Подключается централизованно в lib/l10n/app_translations.dart — этот файл
/// не редактировать вручную для wiring, только для добавления/правки строк.
const Map<String, Map<String, String>> kFeatureMiscUtilsTranslations = {
  'maps_launcher.open_failed': {'ru': 'Не удалось открыть Google Maps', 'en': 'Could not open Google Maps', 'ka': 'ვერ გაიხსნა Google Maps'},
  'maps_launcher.error_message': {'ru': 'Ошибка: {error}', 'en': 'Error: {error}', 'ka': 'შეცდომა: {error}'},
  'push_notification.open_button': {'ru': 'Открыть', 'en': 'Open', 'ka': 'გახსნა'},
};
