import 'gen/batch1_tr.dart';
import 'gen/batch2_tr.dart';
import 'gen/batch3_tr.dart';
import 'gen/batch4_tr.dart';
import 'gen/batch5_tr.dart';
import 'gen/batch6_tr.dart';
import 'gen/batch7_tr.dart';
import 'gen/batch8_tr.dart';
import 'gen/batch9_tr.dart';
import 'gen/feature_car_dropdowns_tr.dart';
import 'gen/feature_country_city_tr.dart';
import 'gen/feature_forgot_password_tr.dart';
import 'gen/feature_photo_upload_tr.dart';
import 'gen/feature_my_points_tr.dart';
import 'gen/feature_home_redesign_tr.dart';
import 'gen/feature_forum_tr.dart';
import 'gen/feature_coins_tr.dart';
import 'gen/feature_admin_ranks_tr.dart';
import 'gen/feature_club_ranks_tr.dart';
import 'gen/feature_premium_tiers_tr.dart';
import 'gen/feature_home_menu_grid_tr.dart';
import 'gen/feature_gamification_tr.dart';
import 'gen/feature_misc_utils_tr.dart';
import 'gen/feature_achievements_tr.dart';

// Дополнительные языки (перевод интерфейса поверх базового ru/en/ka) —
// каждый язык разбит на 3 части, заполняется отдельными переводчиками.
import 'gen/lang_uk_chunk1_tr.dart';
import 'gen/lang_uk_chunk2_tr.dart';
import 'gen/lang_uk_chunk3_tr.dart';
import 'gen/lang_uk_chunk4_tr.dart';
import 'gen/lang_uk_chunk5_tr.dart';
import 'gen/lang_uk_chunk6_tr.dart';
import 'gen/lang_uk_chunk7_tr.dart';
import 'gen/lang_az_chunk1_tr.dart';
import 'gen/lang_az_chunk2_tr.dart';
import 'gen/lang_az_chunk3_tr.dart';
import 'gen/lang_az_chunk4_tr.dart';
import 'gen/lang_az_chunk5_tr.dart';
import 'gen/lang_az_chunk6_tr.dart';
import 'gen/lang_az_chunk7_tr.dart';
import 'gen/lang_hy_chunk1_tr.dart';
import 'gen/lang_hy_chunk2_tr.dart';
import 'gen/lang_hy_chunk3_tr.dart';
import 'gen/lang_hy_chunk4_tr.dart';
import 'gen/lang_hy_chunk5_tr.dart';
import 'gen/lang_hy_chunk6_tr.dart';
import 'gen/lang_hy_chunk7_tr.dart';
import 'gen/lang_kk_chunk1_tr.dart';
import 'gen/lang_kk_chunk2_tr.dart';
import 'gen/lang_kk_chunk3_tr.dart';
import 'gen/lang_kk_chunk4_tr.dart';
import 'gen/lang_kk_chunk5_tr.dart';
import 'gen/lang_kk_chunk6_tr.dart';
import 'gen/lang_kk_chunk7_tr.dart';

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
const Map<String, Map<String, String>> _kBaseTranslations = {
  // ─────────────────────────── ОБЩИЕ ───────────────────────────
  'common.save': {'ru': 'Сохранить', 'en': 'Save', 'ka': 'შენახვა'},
  'common.cancel': {'ru': 'Отмена', 'en': 'Cancel', 'ka': 'გაუქმება'},
  'common.delete': {'ru': 'Удалить', 'en': 'Delete', 'ka': 'წაშლა'},
  'common.edit': {'ru': 'Редактировать', 'en': 'Edit', 'ka': 'რედაქტირება'},
  'common.confirm': {'ru': 'Подтвердить', 'en': 'Confirm', 'ka': 'დადასტურება'},
  'common.ok': {'ru': 'ОК', 'en': 'OK', 'ka': 'კარგი'},
  'common.distance_m': {'ru': '{value} м', 'en': '{value} m', 'ka': '{value} მ'},
  'common.distance_km': {'ru': '{value} км', 'en': '{value} km', 'ka': '{value} კმ'},
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

  // ────────────── Новые экраны (восстановление пароля, гео-сортировка,
  // выбор страны/города, марки/модели машины, загрузка фото из галереи) ──────────────
  ...kFeatureForgotPasswordTranslations,
  ...kFeatureCountryCityTranslations,
  ...kFeatureCarDropdownsTranslations,
  ...kFeaturePhotoUploadTranslations,
  ...kFeatureMyPointsTranslations,
  ...kFeatureHomeRedesignTranslations,
  ...kFeatureForumTranslations,
  ...kFeatureCoinsTranslations,
  ...kFeatureAdminRanksTranslations,
  ...kFeatureClubRanksTranslations,
  ...kFeaturePremiumTiersTranslations,
  ...kFeatureHomeMenuGridTranslations,
  ...kFeatureGamificationTranslations,
  ...kFeatureMiscUtilsTranslations,
  ...kFeatureAchievementsTranslations,
};

/// Доп. языки поверх базового набора (ru/en/ka) — каждый язык собран из
/// 2-3 частей (см. импорты выше), чтобы разные переводчики могли работать
/// параллельно, не трогая один и тот же файл.
const Map<String, String> kUkTranslations = {
  ...kUkChunk1Translations,
  ...kUkChunk2Translations,
  ...kUkChunk3Translations,
  ...kUkChunk4Translations,
  ...kUkChunk5Translations,
  ...kUkChunk6Translations,
  ...kUkChunk7Translations,
};
const Map<String, String> kAzTranslations = {
  ...kAzChunk1Translations,
  ...kAzChunk2Translations,
  ...kAzChunk3Translations,
  ...kAzChunk4Translations,
  ...kAzChunk5Translations,
  ...kAzChunk6Translations,
  ...kAzChunk7Translations,
};
const Map<String, String> kHyTranslations = {
  ...kHyChunk1Translations,
  ...kHyChunk2Translations,
  ...kHyChunk3Translations,
  ...kHyChunk4Translations,
  ...kHyChunk5Translations,
  ...kHyChunk6Translations,
  ...kHyChunk7Translations,
};
const Map<String, String> kKkTranslations = {
  ...kKkChunk1Translations,
  ...kKkChunk2Translations,
  ...kKkChunk3Translations,
  ...kKkChunk4Translations,
  ...kKkChunk5Translations,
  ...kKkChunk6Translations,
  ...kKkChunk7Translations,
};

/// Добавляет к каждой записи базовой таблицы перевод на язык [langCode] из
/// плоской карты key->текст (там, где он есть — иначе запись просто не
/// трогается, и tr() откатится на русский, как и раньше).
Map<String, Map<String, String>> _withLangOverlay(
  Map<String, Map<String, String>> base,
  String langCode,
  Map<String, String> overlay,
) {
  if (overlay.isEmpty) return base;
  final result = <String, Map<String, String>>{};
  base.forEach((key, langs) {
    if (overlay.containsKey(key)) {
      result[key] = {...langs, langCode: overlay[key]!};
    } else {
      result[key] = langs;
    }
  });
  return result;
}

/// Полная таблица переводов: базовые ru/en/ka + наложенные сверху
/// дополнительные языки. Не const (нужен цикл слияния), но строится один
/// раз при первом обращении и дальше переиспользуется как обычная таблица.
final Map<String, Map<String, String>> kTranslations = () {
  var result = _kBaseTranslations;
  result = _withLangOverlay(result, 'uk', kUkTranslations);
  result = _withLangOverlay(result, 'az', kAzTranslations);
  result = _withLangOverlay(result, 'hy', kHyTranslations);
  result = _withLangOverlay(result, 'kk', kKkTranslations);
  return result;
}();

/// Возвращает перевод строки [key] на язык [lang]. Если перевода для этого
/// языка нет — откатывается на русский, если нет и русского (не должно
/// случаться) — возвращает сам ключ, чтобы не падать и было видно, что
/// перевод забыли добавить.
String tr(String key, String lang) {
  final entry = kTranslations[key];
  if (entry == null) return key;
  return entry[lang] ?? entry['ru'] ?? key;
}
