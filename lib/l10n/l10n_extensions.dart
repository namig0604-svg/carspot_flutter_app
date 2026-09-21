import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import 'app_translations.dart';

/// Удобный доступ к переводам из виджетов: `context.t('common.save')`.
///
/// Подписывается на [SettingsProvider] через `context.watch`, поэтому при
/// смене языка (SettingsProvider.setLanguageCode) все виджеты, использующие
/// `context.t(...)`, автоматически перестраиваются с новым текстом.
extension L10nX on BuildContext {
  /// Текущий выбранный язык интерфейса ('ru' / 'en' / 'ka').
  String get lang => watch<SettingsProvider>().languageCode;

  /// Перевод строки по ключу на текущий язык (с фолбэком на русский).
  String t(String key) => tr(key, lang);

  /// Перевод с подстановкой параметров: `context.tArgs('x', {'n': '5'})`
  /// заменит `{n}` в переводе на '5'.
  String tArgs(String key, Map<String, String> args) {
    var text = t(key);
    args.forEach((k, v) {
      text = text.replaceAll('{$k}', v);
    });
    return text;
  }
}
