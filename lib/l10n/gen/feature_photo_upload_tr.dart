// Переводы для функции выбора фото из галереи/камеры (вместо ручного ввода
// URL) на экранах: профиль (аватар), машина (фото), сходка (обложка,
// создание и редактирование), клуб (логотип и обложка).
const Map<String, Map<String, String>> kFeaturePhotoUploadTranslations = {
  'edit_profile.pick_from_gallery': {'ru': 'Из галереи', 'en': 'From gallery', 'ka': 'გალერეიდან'},
  'edit_profile.pick_from_camera': {'ru': 'Камера', 'en': 'Camera', 'ka': 'კამერა'},
  'edit_profile.avatar_upload_error': {
    'ru': 'Не удалось загрузить фото: {error}',
    'en': 'Failed to upload photo: {error}',
    'ka': 'ფოტოს ატვირთვა ვერ მოხერხდა: {error}',
  },

  'car_form.pick_from_gallery': {'ru': 'Из галереи', 'en': 'From gallery', 'ka': 'გალერეიდან'},
  'car_form.pick_from_camera': {'ru': 'Камера', 'en': 'Camera', 'ka': 'კამერა'},
  'car_form.photo_upload_error': {
    'ru': 'Не удалось загрузить фото машины: {error}',
    'en': 'Failed to upload car photo: {error}',
    'ka': 'მანქანის ფოტოს ატვირთვა ვერ მოხერხდა: {error}',
  },

  'club_form.pick_from_gallery': {'ru': 'Из галереи', 'en': 'From gallery', 'ka': 'გალერეიდან'},
  'club_form.pick_from_camera': {'ru': 'Камера', 'en': 'Camera', 'ka': 'კამერა'},
  'club_form.logo_upload_error': {
    'ru': 'Не удалось загрузить логотип: {error}',
    'en': 'Failed to upload logo: {error}',
    'ka': 'ლოგოს ატვირთვა ვერ მოხერხდა: {error}',
  },
  'club_form.cover_upload_error': {
    'ru': 'Не удалось загрузить обложку: {error}',
    'en': 'Failed to upload cover photo: {error}',
    'ka': 'ყდის ფოტოს ატვირთვა ვერ მოხერხდა: {error}',
  },

  'create_event.pick_from_gallery': {'ru': 'Из галереи', 'en': 'From gallery', 'ka': 'გალერეიდან'},
  'create_event.pick_from_camera': {'ru': 'Камера', 'en': 'Camera', 'ka': 'კამერა'},
  'create_event.cover_upload_error': {
    'ru': 'Не удалось загрузить обложку сходки: {error}',
    'en': 'Failed to upload event cover: {error}',
    'ka': 'ღონისძიების ყდის ფოტოს ატვირთვა ვერ მოხერხდა: {error}',
  },

  'edit_event.pick_from_gallery': {'ru': 'Из галереи', 'en': 'From gallery', 'ka': 'გალერეიდან'},
  'edit_event.pick_from_camera': {'ru': 'Камера', 'en': 'Camera', 'ka': 'კამერა'},
  'edit_event.cover_upload_error': {
    'ru': 'Не удалось загрузить обложку сходки: {error}',
    'en': 'Failed to upload event cover: {error}',
    'ka': 'ღონისძიების ყდის ფოტოს ატვირთვა ვერ მოხერხდა: {error}',
  },
};
