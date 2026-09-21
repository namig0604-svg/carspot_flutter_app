/// Переводы для батча 8 (edit_event_screen, photo_gallery_screen,
/// create_event_screen, chat_room_screen).
///
/// Подключается централизованно в lib/l10n/app_translations.dart — этот файл
/// не редактировать вручную для wiring, только для добавления/правки строк.
const Map<String, Map<String, String>> kBatch8Translations = {
  // ─────────────────────────── edit_event_screen.dart ───────────────────────────
  'edit_event.title': {'ru': 'Изменить сходку', 'en': 'Edit meetup', 'ka': 'შეხვედრის რედაქტირება'},
  'edit_event.delete_tooltip': {'ru': 'Удалить сходку', 'en': 'Delete meetup', 'ka': 'შეხვედრის წაშლა'},
  'edit_event.fill_required_fields': {
    'ru': 'Заполни все обязательные поля (*)',
    'en': 'Fill in all required fields (*)',
    'ka': 'შეავსე ყველა სავალდებულო ველი (*)',
  },
  'edit_event.pick_location_on_map': {
    'ru': 'Укажи точку проведения на карте',
    'en': 'Pick the location on the map',
    'ka': 'მიუთითე ადგილმდებარეობა რუკაზე',
  },
  'edit_event.event_updated': {'ru': 'Сходка обновлена', 'en': 'Meetup updated', 'ka': 'შეხვედრა განახლდა'},
  'edit_event.error_prefix': {'ru': 'Ошибка: {error}', 'en': 'Error: {error}', 'ka': 'შეცდომა: {error}'},
  'edit_event.delete_confirm_title': {'ru': 'Удалить сходку?', 'en': 'Delete meetup?', 'ka': 'წავშალო შეხვედრა?'},
  'edit_event.delete_confirm_body': {
    'ru': 'Сходка будет отменена для всех участников. Это нельзя отменить.',
    'en': 'The meetup will be cancelled for all participants. This cannot be undone.',
    'ka': 'შეხვედრა გაუქმდება ყველა მონაწილისთვის. ამის გაუქმება შეუძლებელია.',
  },
  'edit_event.event_deleted': {'ru': 'Сходка удалена', 'en': 'Meetup deleted', 'ka': 'შეხვედრა წაიშალა'},
  'edit_event.title_label': {'ru': 'Название сходки *', 'en': 'Meetup title *', 'ka': 'შეხვედრის დასახელება *'},
  'edit_event.description_label': {'ru': 'Описание', 'en': 'Description', 'ka': 'აღწერა'},
  'edit_event.type_label': {'ru': 'Тип сходки *', 'en': 'Meetup type *', 'ka': 'შეხვედრის ტიპი *'},
  'edit_event.country_label': {'ru': 'Страна *', 'en': 'Country *', 'ka': 'ქვეყანა *'},
  'edit_event.city_label': {'ru': 'Город *', 'en': 'City *', 'ka': 'ქალაქი *'},
  'edit_event.location_label': {'ru': 'Место проведения *', 'en': 'Venue *', 'ka': 'გამართვის ადგილი *'},
  'edit_event.pick_location_button': {
    'ru': 'Указать точку на карте *',
    'en': 'Pick a point on the map *',
    'ka': 'მიუთითე წერტილი რუკაზე *',
  },
  'edit_event.location_point': {'ru': 'Точка: {lat}, {lng}', 'en': 'Point: {lat}, {lng}', 'ka': 'წერტილი: {lat}, {lng}'},
  'edit_event.date_label': {'ru': 'Дата (YYYY-MM-DD) *', 'en': 'Date (YYYY-MM-DD) *', 'ka': 'თარიღი (YYYY-MM-DD) *'},
  'edit_event.time_label': {'ru': 'Время (HH:MM) *', 'en': 'Time (HH:MM) *', 'ka': 'დრო (HH:MM) *'},
  'edit_event.duration_label': {'ru': 'Продолжительность *', 'en': 'Duration *', 'ka': 'ხანგრძლივობა *'},
  'edit_event.duration_helper': {
    'ru': 'Сходка автоматически закроется, когда это время истечёт',
    'en': 'The meetup will close automatically once this time runs out',
    'ka': 'შეხვედრა ავტომატურად დაიხურება ამ დროის ამოწურვისას',
  },
  'edit_event.private_event_title': {'ru': 'Закрытая сходка', 'en': 'Private meetup', 'ka': 'დახურული შეხვედრა'},
  'edit_event.private_event_subtitle': {
    'ru': 'Видна и доступна только участникам клуба',
    'en': 'Visible and accessible only to club members',
    'ka': 'ხილულია და ხელმისაწვდომია მხოლოდ კლუბის წევრებისთვის',
  },

  // ─────────────────────────── photo_gallery_screen.dart ───────────────────────────
  'photo_gallery.error_prefix': {'ru': 'Ошибка: {error}', 'en': 'Error: {error}', 'ka': 'შეცდომა: {error}'},
  'photo_gallery.gallery_open_error': {
    'ru': 'Не удалось открыть галерею: {error}',
    'en': 'Could not open the gallery: {error}',
    'ka': 'გალერეის გახსნა ვერ მოხერხდა: {error}',
  },
  'photo_gallery.upload_error': {
    'ru': 'Ошибка загрузки: {error}',
    'en': 'Upload error: {error}',
    'ka': 'ატვირთვის შეცდომა: {error}',
  },
  'photo_gallery.delete_photo_title': {'ru': 'Удалить фото?', 'en': 'Delete photo?', 'ka': 'წავშალო ფოტო?'},
  'photo_gallery.unpin': {'ru': 'Открепить', 'en': 'Unpin', 'ka': 'დაუმაგრება'},
  'photo_gallery.pin_premium': {
    'ru': 'Закрепить сверху галереи (Premium)',
    'en': 'Pin to top of gallery (Premium)',
    'ka': 'გალერეის თავში მიმაგრება (Premium)',
  },
  'photo_gallery.empty_title': {'ru': 'Пока нет фото', 'en': 'No photos yet', 'ka': 'ჯერ ფოტო არ არის'},
  'photo_gallery.empty_subtitle': {
    'ru': 'Нажми на камеру, чтобы добавить первое',
    'en': 'Tap the camera button to add the first one',
    'ka': 'დააჭირე კამერას პირველი ფოტოს დასამატებლად',
  },

  // ─────────────────────────── create_event_screen.dart ───────────────────────────
  'create_event.title_club': {'ru': 'Сходка клуба', 'en': 'Club meetup', 'ka': 'კლუბის შეხვედრა'},
  'create_event.title': {'ru': 'Создать сходку', 'en': 'Create meetup', 'ka': 'შეხვედრის შექმნა'},
  'create_event.title_label': {'ru': 'Название сходки *', 'en': 'Meetup title *', 'ka': 'შეხვედრის დასახელება *'},
  'create_event.description_label': {'ru': 'Описание', 'en': 'Description', 'ka': 'აღწერა'},
  'create_event.type_label': {'ru': 'Тип сходки *', 'en': 'Meetup type *', 'ka': 'შეხვედრის ტიპი *'},
  'create_event.country_label': {'ru': 'Страна *', 'en': 'Country *', 'ka': 'ქვეყანა *'},
  'create_event.city_label': {'ru': 'Город *', 'en': 'City *', 'ka': 'ქალაქი *'},
  'create_event.location_label': {'ru': 'Место проведения *', 'en': 'Venue *', 'ka': 'გამართვის ადგილი *'},
  'create_event.pick_location_button': {
    'ru': 'Указать точку на карте *',
    'en': 'Pick a point on the map *',
    'ka': 'მიუთითე წერტილი რუკაზე *',
  },
  'create_event.location_point_selected': {
    'ru': 'Точка выбрана: {lat}, {lng}',
    'en': 'Point selected: {lat}, {lng}',
    'ka': 'წერტილი არჩეულია: {lat}, {lng}',
  },
  'create_event.date_label': {'ru': 'Дата (YYYY-MM-DD) *', 'en': 'Date (YYYY-MM-DD) *', 'ka': 'თარიღი (YYYY-MM-DD) *'},
  'create_event.time_label': {'ru': 'Время (HH:MM) *', 'en': 'Time (HH:MM) *', 'ka': 'დრო (HH:MM) *'},
  'create_event.duration_label': {'ru': 'Продолжительность *', 'en': 'Duration *', 'ka': 'ხანგრძლივობა *'},
  'create_event.duration_helper': {
    'ru': 'Сходка автоматически закроется, когда это время истечёт',
    'en': 'The meetup will close automatically once this time runs out',
    'ka': 'შეხვედრა ავტომატურად დაიხურება ამ დროის ამოწურვისას',
  },
  'create_event.private_event_title': {'ru': 'Закрытая сходка', 'en': 'Private meetup', 'ka': 'დახურული შეხვედრა'},
  'create_event.private_event_subtitle': {
    'ru': 'Видна и доступна только участникам клуба',
    'en': 'Visible and accessible only to club members',
    'ka': 'ხილულია და ხელმისაწვდომია მხოლოდ კლუბის წევრებისთვის',
  },
  'create_event.fill_required_fields': {
    'ru': 'Заполни все обязательные поля (*)',
    'en': 'Fill in all required fields (*)',
    'ka': 'შეავსე ყველა სავალდებულო ველი (*)',
  },
  'create_event.pick_location_on_map': {
    'ru': 'Укажи точку проведения на карте',
    'en': 'Pick the location on the map',
    'ka': 'მიუთითე ადგილმდებარეობა რუკაზე',
  },
  'create_event.event_created': {'ru': 'Сходка создана! 🎉', 'en': 'Meetup created! 🎉', 'ka': 'შეხვედრა შეიქმნა! 🎉'},
  'create_event.error_prefix': {'ru': 'Ошибка: {error}', 'en': 'Error: {error}', 'ka': 'შეცდომა: {error}'},

  // ─────────────────────────── chat_room_screen.dart ───────────────────────────
  'chat_room.error_prefix': {'ru': 'Ошибка: {error}', 'en': 'Error: {error}', 'ka': 'შეცდომა: {error}'},
  'chat_room.gallery_open_error': {
    'ru': 'Не удалось открыть галерею: {error}',
    'en': 'Could not open the gallery: {error}',
    'ka': 'გალერეის გახსნა ვერ მოხერხდა: {error}',
  },
  'chat_room.no_image_url_error': {
    'ru': 'Сервер не вернул ссылку на фото',
    'en': 'The server did not return a photo link',
    'ka': 'სერვერმა არ დააბრუნა ფოტოს ბმული',
  },
  'chat_room.image_send_error': {
    'ru': 'Ошибка отправки фото: {error}',
    'en': 'Error sending photo: {error}',
    'ka': 'ფოტოს გაგზავნის შეცდომა: {error}',
  },
  'chat_room.delete_message_title': {'ru': 'Удалить сообщение?', 'en': 'Delete message?', 'ka': 'წავშალო შეტყობინება?'},
  'chat_room.online': {'ru': 'онлайн', 'en': 'online', 'ka': 'ონლაინ'},
  'chat_room.offline': {'ru': 'не в сети', 'en': 'offline', 'ka': 'ოფლაინ'},
  'chat_room.online_count': {
    'ru': '{online} из {total} онлайн',
    'en': '{online} of {total} online',
    'ka': '{online} / {total} ონლაინ',
  },
  'chat_room.default_username': {'ru': 'Пользователь', 'en': 'User', 'ka': 'მომხმარებელი'},
  'chat_room.no_messages_yet': {
    'ru': 'Нет сообщений. Напиши первым! 👋',
    'en': 'No messages yet. Be the first to write! 👋',
    'ka': 'შეტყობინებები ჯერ არ არის. დაწერე პირველმა! 👋',
  },
  'chat_room.send_photo_tooltip': {'ru': 'Отправить фото', 'en': 'Send photo', 'ka': 'ფოტოს გაგზავნა'},
  'chat_room.message_hint': {'ru': 'Написать сообщение...', 'en': 'Write a message...', 'ka': 'დაწერე შეტყობინება...'},
};
