import 'gen/batch1_tr.dart';
import 'gen/batch2_tr.dart';
import 'gen/batch3_tr.dart';
import 'gen/batch4_tr.dart';
import 'gen/batch5_tr.dart';
import 'gen/batch6_tr.dart';
import 'gen/batch7_tr.dart';
import 'gen/batch8_tr.dart';
import 'gen/batch9_tr.dart';

/// Переводы интерфейса CarSpot.
///
/// Ключ — уникальный идентификатор строки в формате `screen.snake_case`
/// (общие для всего приложения строки — в неймспейсе `common.`).
/// Значение — словарь язык → текст. Поддерживаемые языки: 'ru' (обязателен,
/// служит и дефолтом, и фолбэком, если перевод для языка ещё не добавлен),
/// 'en', 'ka' (грузинский).
///
/// Как добавить новую строку:
/// 1. Придумать ключ в стиле `screen_name.what_it_is`.
/// 2. Добавить сюда запись со всеми тремя языками.
/// 3. В виджете использовать `context.t('screen_name.what_it_is')`
///    (см. lib/l10n/l10n_extensions.dart).
const Map<String, Map<String, String>> kTranslations = {
  // ─────────────────────────── ОБЩИЕ ───────────────────────────
  'common.save': {'ru': 'Сохранить', 'en': 'Save', 'ka': 'შენახვა'},
  'common.cancel': {'ru': 'Отмена', 'en': 'Cancel', 'ka': 'გაუქმება'},
  'common.delete': {'ru': 'Удалить', 'en': 'Delete', 'ka': 'წაშლა'},
  'common.edit': {'ru': 'Редактировать', 'en': 'Edit', 'ka': 'რედაქტირება'},
  'common.confirm': {'ru': 'Подтвердить', 'en': 'Confirm', 'ka': 'დადასტურება'},
  'common.ok': {'ru': 'ОК', 'en': 'OK', 'ka': 'კარგი'},
  'common.yes': {'ru': 'Да', 'en': 'Yes', 'ka': 'დიახ'},
  'common.no': {'ru': 'Нет', 'en': 'No', 'ka': 'არა'},
  'common.close': {'ru': 'Закрыть', 'en': 'Close', 'ka': 'დახურვა'},
  'common.back': {'ru': 'Назад', 'en': 'Back', 'ka': 'უკან'},
  'common.search': {'ru': 'Поиск', 'en': 'Search', 'ka': 'ძებნა'},
  'common.loading': {'ru': 'Загрузка…', 'en': 'Loading…', 'ka': 'იტვირთება…'},
  'common.error': {'ru': 'Ошибка', 'en': 'Error', 'ka': 'შეცდომა'},
  'common.retry': {'ru': 'Повторить', 'en': 'Retry', 'ka': 'თავიდან ცდა'},
  'common.send': {'ru': 'Отправить', 'en': 'Send', 'ka': 'გაგზავნა'},
  'common.share': {'ru': 'Поделиться', 'en': 'Share', 'ka': 'გაზიარება'},
  'common.settings': {'ru': 'Настройки', 'en': 'Settings', 'ka': 'პარამეტრები'},
  'common.done': {'ru': 'Готово', 'en': 'Done', 'ka': 'დასრულდა'},
  'common.next': {'ru': 'Далее', 'en': 'Next', 'ka': 'შემდეგი'},
  'common.skip': {'ru': 'Пропустить', 'en': 'Skip', 'ka': 'გამოტოვება'},
  'common.apply': {'ru': 'Применить', 'en': 'Apply', 'ka': 'გამოყენება'},
  'common.reset': {'ru': 'Сбросить', 'en': 'Reset', 'ka': 'განულება'},
  'common.select': {'ru': 'Выбрать', 'en': 'Select', 'ka': 'არჩევა'},
  'common.not_found': {'ru': 'Не найдено', 'en': 'Not found', 'ka': 'ვერ მოიძებნა'},
  'common.empty': {'ru': 'Пусто', 'en': 'Empty', 'ka': 'ცარიელია'},
  'common.optional': {'ru': 'Необязательно', 'en': 'Optional', 'ka': 'არასავალდებულო'},

  // ────────────── Строки экранов (сгенерированы батчами локализации) ──────────────
  ...kBatch1Translations,
  ...kBatch2Translations,
  ...kBatch3Translations,
  ...kBatch4Translations,
  ...kBatch5Translations,
  ...kBatch6Translations,
  ...kBatch7Translations,
  ...kBatch8Translations,
  ...kBatch9Translations,
};

/// Возвращает перевод строки [key] на язык [lang]. Если перевода для этого
/// языка нет — откатывается на русский, если нет и русского (не должно
/// случаться) — возвращает сам ключ, чтобы не падать и было видно, что
/// перевод забыли добавить.
String tr(String key, String lang) {
  final entry = kTranslations[key];
  if (entry == null) return key;
  return entry[lang] ?? entry['ru'] ?? key;
}
