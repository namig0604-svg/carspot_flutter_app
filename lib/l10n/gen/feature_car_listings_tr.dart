/// Витрина «Машина на продажу» — car_listings_screen.dart,
/// car_listing_form_screen.dart, car_listing_detail_screen.dart. Только
/// ru/en/ka — остальные языки (az/hy/kk/uk) откатываются на русский.
/// Подключается централизованно в lib/l10n/app_translations.dart.
const Map<String, Map<String, String>> kFeatureCarListingsTranslations = {
  'car_listings.title': {'ru': 'Машина на продажу', 'en': 'Cars for sale', 'ka': 'მანქანა იყიდება'},
  'home.menu_car_listings': {'ru': 'Продажа авто', 'en': 'Sell a car', 'ka': 'მანქანის გაყიდვა'},
  'car_listings.search_hint': {'ru': 'Поиск по марке или модели', 'en': 'Search by make or model', 'ka': 'ძებნა მარკით ან მოდელით'},
  'car_listings.mine_chip': {'ru': 'Мои объявления', 'en': 'My listings', 'ka': 'ჩემი განცხადებები'},
  'car_listings.empty': {
    'ru': 'Пока нет объявлений — станьте первым',
    'en': 'No listings yet — be the first',
    'ka': 'ჯერ არ არის განცხადებები — იყავით პირველი',
  },
  'car_listings.status_sold': {'ru': 'Продано', 'en': 'Sold', 'ka': 'გაყიდულია'},
  'car_listings.status_reserved': {'ru': 'Забронировано', 'en': 'Reserved', 'ka': 'დაჯავშნილია'},
  'car_listings.status_removed': {'ru': 'Снято', 'en': 'Removed', 'ka': 'მოხსნილია'},
  'car_listing_form.title': {'ru': 'Новое объявление', 'en': 'New listing', 'ka': 'ახალი განცხადება'},
  'car_listing_form.make_label': {'ru': 'Марка', 'en': 'Make', 'ka': 'მარკა'},
  'car_listing_form.model_label': {'ru': 'Модель', 'en': 'Model', 'ka': 'მოდელი'},
  'car_listing_form.year_label': {'ru': 'Год', 'en': 'Year', 'ka': 'წელი'},
  'car_listing_form.mileage_label': {'ru': 'Пробег, км', 'en': 'Mileage, km', 'ka': 'გარბენი, კმ'},
  'car_listing_form.price_label': {'ru': 'Цена', 'en': 'Price', 'ka': 'ფასი'},
  'car_listing_form.required_fields_hint': {
    'ru': 'Заполните марку, модель, год и цену',
    'en': 'Fill in make, model, year and price',
    'ka': 'შეავსეთ მარკა, მოდელი, წელი და ფასი',
  },
  'car_listing_detail.title': {'ru': 'Объявление', 'en': 'Listing', 'ka': 'განცხადება'},
  'car_listing_detail.mileage_chip': {'ru': '{mileage} км', 'en': '{mileage} km', 'ka': '{mileage} კმ'},
  'car_listing_detail.delete_confirm_title': {
    'ru': 'Удалить объявление?',
    'en': 'Delete this listing?',
    'ka': 'წავშალო განცხადება?',
  },
  'car_listing_detail.delete_action': {'ru': 'Удалить', 'en': 'Delete', 'ka': 'წაშლა'},
};
