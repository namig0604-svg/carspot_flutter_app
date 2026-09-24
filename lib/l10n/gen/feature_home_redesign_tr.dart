/// Переводы для обновлённого верха ленты сходок на главном экране
/// (home_screen.dart, _buildEventsTab): вкладки сортировки и карточки
/// быстрой статистики над списком — добавлены при переработке визуала
/// под стиль карточек-фильтров с счётчиками.
///
/// Подключается централизованно в lib/l10n/app_translations.dart — этот файл
/// не редактировать вручную для wiring, только для добавления/правки строк.
const Map<String, Map<String, String>> kFeatureHomeRedesignTranslations = {
  'home.sort_popular': {'ru': 'Популярные', 'en': 'Popular', 'ka': 'პოპულარული'},
  'home.sort_new': {'ru': 'Новые', 'en': 'New', 'ka': 'ახალი'},
  'home.sort_nearest': {'ru': 'Ближайшие', 'en': 'Nearest', 'ka': 'უახლოესი'},
  'home.quick_soon': {'ru': 'Скоро', 'en': 'Soon', 'ka': 'მალე'},
  'home.quick_services': {'ru': 'Сервисы', 'en': 'Services', 'ka': 'სერვისები'},
  'home.quick_clubs': {'ru': 'Клубы', 'en': 'Clubs', 'ka': 'კლუბები'},
  'home.section_soon': {'ru': 'Скоро', 'en': 'Soon', 'ka': 'მალე'},
};
