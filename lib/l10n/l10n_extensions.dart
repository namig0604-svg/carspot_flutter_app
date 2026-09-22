import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import 'app_translations.dart';

/// Удобный доступ к переводам из виджетов: `context.t('common.save')`.
///
/// Подписывается на [SettingsProvider] через `context.watch`, поэтому при
/// смене языка (SettingsProvider.setLanguageCode) все виджеты, использующие
/// `context.t(...)` ИЗ build(), автоматически перестраиваются с новым текстом.
extension L10nX on BuildContext {
  /// Текущий выбранный язык интерфейса ('ru' / 'en' / 'ka').
  ///
  /// ВАЖНО: `context.watch()` из пакета provider разрешён только во время
  /// build() — если t()/tArgs() вызвать из обработчика события (onTap,
  /// onPressed, внутри async-метода, в catch-блоке и т.п.), в debug-режиме
  /// это падает с ассертом "Tried to listen to a value exposed with
  /// provider, from outside of the widget tree" (именно так и происходило
  /// при открытии пикера марки/модели машины — context.t() вызывался прямо
  /// внутри async-обработчика тапа). В release-сборке ассерты вырезаются,
  /// поэтому там ничего не падало — баг был виден только в `flutter run`.
  ///
  /// Поэтому сначала пробуем watch (чтобы работала живая перестройка при
  /// смене языка для вызовов из build()), а если это невозможно — тихо
  /// откатываемся на read() (без подписки на изменения, но зато безопасно
  /// из любого места, включая обработчики событий).
  String get lang {
    try {
      return watch<SettingsProvider>().languageCode;
    } catch (_) {
      return read<SettingsProvider>().languageCode;
    }
  }

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
