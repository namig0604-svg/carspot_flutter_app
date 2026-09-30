/// Переводы для сетки меню на главном экране (home_screen.dart,
/// _buildProfileTab / гараж-сетка): заголовки секций и плитки, которые были
/// захардкожены на русском напрямую в коде и никогда не подключались к
/// системе переводов — из-за этого при выборе английского/другого языка
/// они не переключались (см. context.t()/tr() в lib/l10n/app_translations.dart).
///
/// Подключается централизованно в lib/l10n/app_translations.dart — этот файл
/// не редактировать вручную для wiring, только для добавления/правки строк.
const Map<String, Map<String, String>> kFeatureHomeMenuGridTranslations = {
  'home.section_my_car': {'ru': 'Моё авто', 'en': 'My car', 'ka': 'ჩემი მანქანა'},
  'home.menu_parking': {'ru': 'Парковка', 'en': 'Parking', 'ka': 'პარკინგი'},
  'home.menu_service_log': {'ru': 'Сервисный дневник', 'en': 'Service log', 'ka': 'სერვისის ჟურნალი'},
  'home.menu_documents': {'ru': 'Документы', 'en': 'Documents', 'ka': 'დოკუმენტები'},
  'home.menu_expenses': {'ru': 'Расходы', 'en': 'Expenses', 'ka': 'ხარჯები'},
  'home.menu_vin_check': {'ru': 'Проверка VIN', 'en': 'VIN check', 'ka': 'VIN შემოწმება'},
  'home.section_community': {'ru': 'Сообщество', 'en': 'Community', 'ka': 'საზოგადოება'},
  'home.menu_marketplace': {'ru': 'Барахолка', 'en': 'Marketplace', 'ka': 'ბაზარი'},
  'home.section_my_activity': {'ru': 'Моя активность', 'en': 'My activity', 'ka': 'ჩემი აქტივობა'},
  'home.menu_my_bookings': {'ru': 'Мои записи', 'en': 'My bookings', 'ka': 'ჩემი ჩანაწერები'},
  'home.section_safety': {'ru': 'Безопасность и сервисы', 'en': 'Safety & services', 'ka': 'უსაფრთხოება და სერვისები'},
  'home.menu_road_hazards': {'ru': 'Опасности на дороге', 'en': 'Road hazards', 'ka': 'საგზაო საფრთხეები'},
  'home.section_other': {'ru': 'Прочее', 'en': 'Other', 'ka': 'სხვა'},
  'home.menu_help': {'ru': 'Помощь', 'en': 'Help', 'ka': 'დახმარება'},

  // Подзаголовки для крупных карточек-категорий на главном экране
  // (редизайн меню: 5 категорий вместо ~19 плоских иконок).
  'home.section_my_car_subtitle': {'ru': 'Гараж, сервис, документы, топливо и ИИ-диагностика', 'en': 'Garage, service, documents, fuel and AI diagnosis', 'ka': 'გარაჟი, სერვისი, დოკუმენტები, საწვავი და AI დიაგნოსტიკა'},
  'home.section_community_subtitle': {'ru': 'Друзья, клубы, форум, маркетплейс и лидеры', 'en': 'Friends, clubs, forum, marketplace and leaders', 'ka': 'მეგობრები, კლუბები, ფორუმი, ბაზარი და ლიდერები'},
  'home.section_my_activity_subtitle': {'ru': 'Записи, избранное, достижения и челленджи', 'en': 'Bookings, favorites, achievements and challenges', 'ka': 'ჩანაწერები, ფავორიტები, მიღწევები და გამოწვევები'},
  'home.section_safety_subtitle': {'ru': 'SOS, дорожные опасности, автосервисы и ваши точки', 'en': 'SOS, road hazards, auto services and your points', 'ka': 'SOS, საგზაო საფრთხეები, ავტოსერვისები და თქვენი წერტილები'},
  'home.section_other_subtitle': {'ru': 'Настройки, помощь и интерактивный тур по приложению', 'en': 'Settings, help and the interactive app tour', 'ka': 'პარამეტრები, დახმარება და აპლიკაციის ტური'},
};
