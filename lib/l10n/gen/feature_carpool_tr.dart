/// Переводы для карпулинга (lib/screens/carpool_screen.dart) — заголовок,
/// диалог предложения места, статусы бронирования и ошибки, которые были
/// захардкожены на русском и никогда не подключались к системе переводов.
///
/// Подключается централизованно в lib/l10n/app_translations.dart — этот файл
/// не редактировать вручную для wiring, только для добавления/правки строк.
const Map<String, Map<String, String>> kFeatureCarpoolTranslations = {
  'carpool.error': {'ru': 'Ошибка: {error}', 'en': 'Error: {error}', 'ka': 'შეცდომა: {error}'},
  'carpool.dialog_title': {'ru': 'Предложить место в машине', 'en': 'Offer a seat', 'ka': 'შესთავაზე ადგილი მანქანაში'},
  'carpool.from_label': {'ru': 'Откуда едем', 'en': 'Departure point', 'ka': 'საიდან მიდიხართ'},
  'carpool.departure_not_set': {'ru': 'Время отправления: не задано', 'en': 'Departure time: not set', 'ka': 'გამგზავრების დრო: არ არის მითითებული'},
  'carpool.departure_time_label': {'ru': 'Время отправления: {value}', 'en': 'Departure time: {value}', 'ka': 'გამგზავრების დრო: {value}'},
  'carpool.seats_label': {'ru': 'Мест: ', 'en': 'Seats: ', 'ka': 'ადგილები: '},
  'carpool.comment_label': {'ru': 'Комментарий (необязательно)', 'en': 'Comment (optional)', 'ka': 'კომენტარი (არასავალდებულო)'},
  'carpool.cancel': {'ru': 'Отмена', 'en': 'Cancel', 'ka': 'გაუქმება'},
  'carpool.publish': {'ru': 'Опубликовать', 'en': 'Publish', 'ka': 'გამოქვეყნება'},
  'carpool.title': {'ru': 'Карпулинг · {title}', 'en': 'Carpool · {title}', 'ka': 'კარპულინგი · {title}'},
  'carpool.offer_seat': {'ru': 'Предложить место', 'en': 'Offer a seat', 'ka': 'ადგილის შეთავაზება'},
  'carpool.empty_state': {'ru': 'Пока никто не предложил место — предложите первым!', 'en': 'No one has offered a seat yet — be the first!', 'ka': 'ჯერ არავის შემოუთავაზებია ადგილი — იყავი პირველი!'},
  'carpool.driver_fallback': {'ru': 'Водитель', 'en': 'Driver', 'ka': 'მძღოლი'},
  'carpool.seats_free': {'ru': '{left} своб. из {total}', 'en': '{left} free of {total}', 'ka': '{left} თავისუფალი {total}-დან'},
  'carpool.no_seats': {'ru': 'Мест нет', 'en': 'No seats left', 'ka': 'ადგილი არ არის'},
  'carpool.delete': {'ru': 'Удалить', 'en': 'Delete', 'ka': 'წაშლა'},
  'carpool.cancel_booking': {'ru': 'Отменить бронь', 'en': 'Cancel booking', 'ka': 'ჯავშნის გაუქმება'},
  'carpool.book_seat': {'ru': 'Забронировать место', 'en': 'Book a seat', 'ka': 'ადგილის დაჯავშნა'},
  'carpool.datetime_format': {'ru': '{date} в {time}', 'en': '{date} at {time}', 'ka': '{date}, {time} საათზე'},
};
