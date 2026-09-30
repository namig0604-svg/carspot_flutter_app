/// Трекер поездок — DriveTrackerScreen (запись), TripDetailScreen (детали
/// поездки с картой маршрута), TripsListScreen (история + статистика
/// вождения), плюс пункт меню в "Мой Гараж". Только ru/en/ka — остальные
/// языки (az/hy/kk/uk) откатываются на русский.
/// Подключается централизованно в lib/l10n/app_translations.dart.
const Map<String, Map<String, String>> kFeatureDriveTrackerTranslations = {
  'home.menu_trips': {'ru': 'Поездки', 'en': 'Trips', 'ka': 'მოგზაურობები'},

  'drive_tracker.title': {'ru': 'Поездка', 'en': 'Drive', 'ka': 'მგზავრობა'},
  'drive_tracker.intro_text': {
    'ru': 'Приложение запишет маршрут, дистанцию и скорость, пока этот экран открыт',
    'en': 'The app will record your route, distance and speed while this screen is open',
    'ka': 'აპლიკაცია ჩაწერს მარშრუტს, მანძილს და სიჩქარეს, სანამ ეს ეკრანი ღიაა',
  },
  'drive_tracker.start_button': {'ru': 'Начать поездку', 'en': 'Start drive', 'ka': 'მგზავრობის დაწყება'},
  'drive_tracker.stop_button': {'ru': 'Завершить поездку', 'en': 'End drive', 'ka': 'მგზავრობის დასრულება'},
  'drive_tracker.cancel_button': {'ru': 'Отменить', 'en': 'Cancel', 'ka': 'გაუქმება'},
  'drive_tracker.cancel_confirm_title': {'ru': 'Отменить поездку?', 'en': 'Cancel this drive?', 'ka': 'გავაუქმოთ მგზავრობა?'},
  'drive_tracker.cancel_confirm_body': {
    'ru': 'Записанный маршрут не будет сохранён',
    'en': 'The recorded route will not be saved',
    'ka': 'ჩაწერილი მარშრუტი არ შეინახება',
  },
  'drive_tracker.cancel_confirm_yes': {'ru': 'Да, отменить', 'en': 'Yes, cancel', 'ka': 'დიახ, გაუქმება'},
  'drive_tracker.cancel_confirm_no': {'ru': 'Нет, продолжить', 'en': 'No, keep going', 'ka': 'არა, გავაგრძელოთ'},
  'drive_tracker.location_service_disabled': {
    'ru': 'Включите геолокацию на устройстве',
    'en': 'Turn on location services on your device',
    'ka': 'ჩართეთ გეოლოკაცია მოწყობილობაზე',
  },
  'drive_tracker.location_permission_denied': {
    'ru': 'Нужен доступ к геолокации, чтобы записать поездку',
    'en': 'Location access is needed to record a drive',
    'ka': 'მგზავრობის ჩასაწერად საჭიროა გეოლოკაციაზე წვდომა',
  },
  'drive_tracker.too_short': {
    'ru': 'Поездка слишком короткая — не сохранена',
    'en': 'Drive was too short — not saved',
    'ka': 'მგზავრობა ძალიან მოკლეა — არ შეინახა',
  },
  'drive_tracker.save_error': {'ru': 'Не удалось сохранить поездку: {error}', 'en': 'Could not save the drive: {error}', 'ka': 'ვერ მოხერხდა მგზავრობის შენახვა: {error}'},
  'drive_tracker.distance_label': {'ru': 'Дистанция', 'en': 'Distance', 'ka': 'მანძილი'},
  'drive_tracker.duration_label': {'ru': 'Время', 'en': 'Duration', 'ka': 'დრო'},
  'drive_tracker.speed_label': {'ru': 'Скорость', 'en': 'Speed', 'ka': 'სიჩქარე'},
  'drive_tracker.unit_km': {'ru': 'км', 'en': 'km', 'ka': 'კმ'},
  'drive_tracker.unit_kmh': {'ru': 'км/ч', 'en': 'km/h', 'ka': 'კმ/სთ'},

  'trip_detail.title': {'ru': 'Поездка', 'en': 'Trip', 'ka': 'მგზავრობა'},
  'trip_detail.load_error': {'ru': 'Не удалось загрузить поездку', 'en': 'Could not load the trip', 'ka': 'ვერ ჩაიტვირთა მგზავრობა'},
  'trip_detail.delete_button': {'ru': 'Удалить', 'en': 'Delete', 'ka': 'წაშლა'},
  'trip_detail.delete_confirm_title': {'ru': 'Удалить поездку?', 'en': 'Delete this trip?', 'ka': 'წავშალოთ მგზავრობა?'},
  'trip_detail.delete_confirm_body': {
    'ru': 'Это действие необратимо',
    'en': 'This action cannot be undone',
    'ka': 'ეს მოქმედება შეუქცევადია',
  },
  'trip_detail.distance': {'ru': 'Дистанция', 'en': 'Distance', 'ka': 'მანძილი'},
  'trip_detail.duration': {'ru': 'Время', 'en': 'Duration', 'ka': 'დრო'},
  'trip_detail.top_speed': {'ru': 'Макс. скорость', 'en': 'Top speed', 'ka': 'მაქს. სიჩქარე'},
  'trip_detail.speed_distribution': {'ru': 'Распределение скорости', 'en': 'Speed distribution', 'ka': 'სიჩქარის განაწილება'},
  'trip_detail.speed_band_low': {'ru': '<30', 'en': '<30', 'ka': '<30'},
  'trip_detail.speed_band_mid': {'ru': '30–60', 'en': '30–60', 'ka': '30–60'},
  'trip_detail.speed_band_high': {'ru': '60–90', 'en': '60–90', 'ka': '60–90'},
  'trip_detail.speed_band_vhigh': {'ru': '>90', 'en': '>90', 'ka': '>90'},

  'trips_list.title': {'ru': 'Поездки', 'en': 'Trips', 'ka': 'მოგზაურობები'},
  'trips_list.new_trip': {'ru': 'Начать поездку', 'en': 'Start drive', 'ka': 'მგზავრობის დაწყება'},
  'trips_list.empty': {
    'ru': 'Пока нет ни одной поездки — начните первую кнопкой ниже',
    'en': 'No trips yet — start your first one with the button below',
    'ka': 'ჯერ არცერთი მგზავრობა — დაიწყეთ პირველი ქვემოთ მოცემული ღილაკით',
  },
  'trips_list.stats_title': {'ru': 'Статистика вождения', 'en': 'Driving stats', 'ka': 'ტარების სტატისტიკა'},
  'trips_list.stat_total_distance': {'ru': 'Всего км', 'en': 'Total distance', 'ka': 'სულ კმ'},
  'trips_list.stat_total_duration': {'ru': 'В пути', 'en': 'Time driven', 'ka': 'გზაში'},
  'trips_list.stat_total_trips': {'ru': 'Поездок', 'en': 'Trips', 'ka': 'მგზავრობა'},
  'trips_list.stat_top_speed': {'ru': 'Макс. скорость', 'en': 'Top speed', 'ka': 'მაქს. სიჩქარე'},
  'trips_list.monthly_chart_title': {'ru': 'По месяцам', 'en': 'By month', 'ka': 'თვეების მიხედვით'},
};
