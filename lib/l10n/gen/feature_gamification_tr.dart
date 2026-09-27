/// Переводы названий рангов геймификации (lib/utils/gamification.dart,
/// GamificationStats.levelTitleKey) — раньше названия рангов были захардкожены
/// на русском прямо в списке _levelTitles и никогда не переводились, поэтому
/// у всех пользователей ранг в профиле/достижениях/лидерборде показывался
/// на русском независимо от выбранного языка интерфейса.
///
/// Подключается централизованно в lib/l10n/app_translations.dart — этот файл
/// не редактировать вручную для wiring, только для добавления/правки строк.
const Map<String, Map<String, String>> kFeatureGamificationTranslations = {
  'gamification.tier_novice': {'ru': 'Новичок', 'en': 'Newbie', 'ka': 'დამწყები'},
  'gamification.tier_amateur': {'ru': 'Любитель', 'en': 'Amateur', 'ka': 'მოყვარული'},
  'gamification.tier_expert': {'ru': 'Знаток', 'en': 'Expert', 'ka': 'ექსპერტი'},
  'gamification.tier_pro': {'ru': 'Профи', 'en': 'Pro', 'ka': 'პროფესიონალი'},
  'gamification.tier_master': {'ru': 'Мастер', 'en': 'Master', 'ka': 'ოსტატი'},
  'gamification.tier_legend': {'ru': 'Легенда трассы', 'en': 'Track legend', 'ka': 'ტრასის ლეგენდა'},
};
