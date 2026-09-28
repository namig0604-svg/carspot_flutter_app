/// Топливный трекер — экран FuelTrackerScreen. Только ru/en/ka — остальные
/// языки (az/hy/kk/uk) откатываются на русский.
/// Подключается централизованно в lib/l10n/app_translations.dart.
const Map<String, Map<String, String>> kFeatureFuelTrackerTranslations = {
  'fuel_tracker.title': {'ru': 'Топливный трекер', 'en': 'Fuel tracker', 'ka': 'საწვავის ტრეკერი'},
  'home.menu_fuel_tracker': {'ru': 'Топливо', 'en': 'Fuel', 'ka': 'საწვავი'},
  'fuel_tracker.empty': {
    'ru': 'Пока нет заправок — добавьте первую кнопкой ниже',
    'en': 'No fill-ups yet — add your first one with the button below',
    'ka': 'ჯერ არ არის ჩასხმები — დაამატეთ პირველი ქვემოთ მოცემული ღილაკით',
  },
  'fuel_tracker.new_entry_title': {'ru': 'Новая заправка', 'en': 'New fill-up', 'ka': 'ახალი ჩასხმა'},
  'fuel_tracker.liters_label': {'ru': 'Литры', 'en': 'Liters', 'ka': 'ლიტრი'},
  'fuel_tracker.cost_label': {'ru': 'Стоимость', 'en': 'Cost', 'ka': 'ღირებულება'},
  'fuel_tracker.odometer_label': {'ru': 'Пробег (км), необязательно', 'en': 'Odometer (km), optional', 'ka': 'გარბენი (კმ), არასავალდებულო'},
  'fuel_tracker.station_label': {'ru': 'АЗС, необязательно', 'en': 'Gas station, optional', 'ka': 'ბენზინგასამართი, არასავალდებულო'},
  'fuel_tracker.full_tank_label': {'ru': 'Полный бак', 'en': 'Full tank', 'ka': 'სავსე ბაკი'},
  'fuel_tracker.full_tank_hint': {
    'ru': 'Нужно для точного расчёта расхода — если заправили не полностью, выключите',
    'en': 'Needed for an accurate consumption calculation — turn off if you filled up partially',
    'ka': 'საჭიროა ხარჯვის ზუსტი გამოთვლისთვის — თუ ნაწილობრივ ჩაასხით, გამორთეთ',
  },
  'fuel_tracker.date_label': {'ru': 'Дата: {date}', 'en': 'Date: {date}', 'ka': 'თარიღი: {date}'},
  'fuel_tracker.save': {'ru': 'Сохранить', 'en': 'Save', 'ka': 'შენახვა'},
  'fuel_tracker.stat_total_cost': {'ru': 'Всего потрачено', 'en': 'Total spent', 'ka': 'სულ დახარჯული'},
  'fuel_tracker.stat_avg_price': {'ru': 'Средняя цена/л', 'en': 'Avg price/L', 'ka': 'საშ. ფასი/ლ'},
  'fuel_tracker.stat_consumption': {'ru': 'Средний расход', 'en': 'Avg consumption', 'ka': 'საშ. ხარჯვა'},
  'fuel_tracker.stat_total_liters': {'ru': 'Всего литров', 'en': 'Total liters', 'ka': 'სულ ლიტრი'},
  'fuel_tracker.unit_l_100km': {'ru': 'л/100км', 'en': 'L/100km', 'ka': 'ლ/100კმ'},
  'fuel_tracker.unit_km': {'ru': 'км', 'en': 'km', 'ka': 'კმ'},
  'fuel_tracker.list_item': {
    'ru': '{liters} л за {cost}',
    'en': '{liters} L for {cost}',
    'ka': '{liters} ლ, {cost}-ად',
  },
};
