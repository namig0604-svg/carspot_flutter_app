/// Переводы для экрана "Мои точки" (my_points_screen.dart) — список сходок
/// и заведений, созданных текущим пользователем, а также подпись пункта
/// меню на главном экране, который на него ведёт.
///
/// Подключается централизованно в lib/l10n/app_translations.dart — этот файл
/// не редактировать вручную для wiring, только для добавления/правки строк.
const Map<String, Map<String, String>> kFeatureMyPointsTranslations = {
  'home.menu_my_points': {'ru': 'Мои точки', 'en': 'My points', 'ka': 'ჩემი წერტილები'},
  'my_points.title': {'ru': 'Мои точки', 'en': 'My points', 'ka': 'ჩემი წერტილები'},
  'my_points.tab_events': {'ru': 'Сходки', 'en': 'Meetups', 'ka': 'შეხვედრები'},
  'my_points.tab_businesses': {'ru': 'Сервисы', 'en': 'Services', 'ka': 'სერვისები'},
  'my_points.empty_events': {
    'ru': 'Вы пока не создали ни одной сходки',
    'en': 'You haven\'t created any meetups yet',
    'ka': 'თქვენ ჯერ არ შეგიქმნიათ არცერთი შეხვედრა',
  },
  'my_points.empty_businesses': {
    'ru': 'Вы пока не добавили ни одного заведения',
    'en': 'You haven\'t added any business yet',
    'ka': 'თქვენ ჯერ არ დაგიმატებიათ არცერთი დაწესებულება',
  },
  'my_points.address_pending': {'ru': 'Адрес уточняется', 'en': 'Address pending', 'ka': 'მისამართი დაზუსტების პროცესშია'},
  'my_points.error_message': {'ru': 'Ошибка: {error}', 'en': 'Error: {error}', 'ka': 'შეცდომა: {error}'},
};
