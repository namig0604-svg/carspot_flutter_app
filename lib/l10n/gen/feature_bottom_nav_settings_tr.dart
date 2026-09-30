/// Настройка нижней панели (BottomNavSettingsScreen) + новые id разделов
/// в самой панели ("Поездки", "Гараж" — home.nav_trips/home.nav_garage).
/// Только ru/en/ka — остальные языки (az/hy/kk/uk) откатываются на русский.
/// Подключается централизованно в lib/l10n/app_translations.dart.
const Map<String, Map<String, String>> kFeatureBottomNavSettingsTranslations = {
  'home.nav_trips': {'ru': 'Поездки', 'en': 'Trips', 'ka': 'მოგზაურობები'},
  'home.nav_garage': {'ru': 'Гараж', 'en': 'Garage', 'ka': 'გარაჟი'},

  'bottom_nav_settings.section_title': {'ru': 'Нижняя панель', 'en': 'Bottom bar', 'ka': 'ქვედა პანელი'},
  'bottom_nav_settings.entry_title': {'ru': 'Настроить разделы', 'en': 'Customize sections', 'ka': 'განყოფილებების მორგება'},
  'bottom_nav_settings.entry_subtitle': {
    'ru': 'Выберите, какие 4 раздела показывать внизу экрана',
    'en': 'Choose which 4 sections to show at the bottom',
    'ka': 'აირჩიეთ, რომელი 4 განყოფილება გამოჩნდეს ქვემოთ',
  },
  'bottom_nav_settings.title': {'ru': 'Нижняя панель', 'en': 'Bottom bar', 'ka': 'ქვედა პანელი'},
  'bottom_nav_settings.intro': {
    'ru': 'Отметьте ровно 4 раздела — они появятся внизу экрана в этом же порядке. Кнопка «Добавить» всегда остаётся по центру.',
    'en': 'Pick exactly 4 sections — they will appear at the bottom in this order. The "Add" button always stays in the center.',
    'ka': 'მონიშნეთ ზუსტად 4 განყოფილება — ისინი გამოჩნდება ქვემოთ ამავე თანმიმდევრობით. ღილაკი „დამატება“ ყოველთვის ცენტრში რჩება.',
  },
  'bottom_nav_settings.selected_count': {'ru': 'Выбрано: {count} из 4', 'en': 'Selected: {count} of 4', 'ka': 'არჩეულია: {count} დან 4'},
  'bottom_nav_settings.save': {'ru': 'Сохранить', 'en': 'Save', 'ka': 'შენახვა'},
};
