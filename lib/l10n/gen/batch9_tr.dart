/// Переводы для батча 9 (login_screen, people_list_screen, edit_profile_screen).
///
/// Подключается централизованно в lib/l10n/app_translations.dart — этот файл
/// не редактировать вручную для wiring, только для добавления/правки строк.
const Map<String, Map<String, String>> kBatch9Translations = {
  // ─────────────────────────── login_screen.dart ───────────────────────────
  'login.tab_login': {'ru': 'ВХОД', 'en': 'LOG IN', 'ka': 'შესვლა'},
  'login.tab_register': {'ru': 'РЕГИСТРАЦИЯ', 'en': 'SIGN UP', 'ka': 'რეგისტრაცია'},
  'login.field_username': {'ru': 'Логин', 'en': 'Username', 'ka': 'მომხმარებლის სახელი'},
  'login.field_email': {'ru': 'Email', 'en': 'Email', 'ka': 'ელფოსტა'},
  'login.field_full_name': {'ru': 'Полное имя', 'en': 'Full name', 'ka': 'სრული სახელი'},
  'login.field_country': {'ru': 'Страна', 'en': 'Country', 'ka': 'ქვეყანა'},
  'login.field_city': {'ru': 'Город', 'en': 'City', 'ka': 'ქალაქი'},
  'login.field_referral_code': {
    'ru': 'Реферальный код (если есть)',
    'en': 'Referral code (if any)',
    'ka': 'სარეფერალო კოდი (არსებობის შემთხვევაში)',
  },
  'login.field_password': {'ru': 'Пароль', 'en': 'Password', 'ka': 'პაროლი'},
  'login.submit_login': {'ru': 'Войти', 'en': 'Log in', 'ka': 'შესვლა'},
  'login.submit_register': {'ru': 'Зарегистрироваться', 'en': 'Sign up', 'ka': 'რეგისტრაცია'},
  'login.no_account_prompt': {'ru': 'Нет аккаунта? ', 'en': "Don't have an account? ", 'ka': 'არ გაქვთ ანგარიში? '},
  'login.has_account_prompt': {'ru': 'Уже есть аккаунт? ', 'en': 'Already have an account? ', 'ka': 'უკვე გაქვთ ანგარიში? '},
  'login.switch_to_register': {'ru': 'Зарегистрируйся', 'en': 'Sign up', 'ka': 'დარეგისტრირდი'},
  'login.switch_to_login': {'ru': 'Войди', 'en': 'Log in', 'ka': 'შედი'},

  // ────────────────────────── people_list_screen.dart ──────────────────────
  'people_list.empty_default': {'ru': 'Пока никого', 'en': 'No one yet', 'ka': 'ჯერ არავინ არის'},

  // ────────────────────────── edit_profile_screen.dart ─────────────────────
  'edit_profile.username_min_length': {
    'ru': 'Юзернейм — минимум 3 символа',
    'en': 'Username must be at least 3 characters',
    'ka': 'მომხმარებლის სახელი უნდა შეიცავდეს მინიმუმ 3 სიმბოლოს',
  },
  'edit_profile.profile_updated': {'ru': 'Профиль обновлён', 'en': 'Profile updated', 'ka': 'პროფილი განახლდა'},
  'edit_profile.generic_error': {'ru': 'Ошибка: {error}', 'en': 'Error: {error}', 'ka': 'შეცდომა: {error}'},
  'edit_profile.title': {'ru': 'Редактировать профиль', 'en': 'Edit profile', 'ka': 'პროფილის რედაქტირება'},
  'edit_profile.field_username': {'ru': 'Юзернейм', 'en': 'Username', 'ka': 'მომხმარებლის სახელი'},
  'edit_profile.field_full_name': {'ru': 'Имя', 'en': 'Name', 'ka': 'სახელი'},
  'edit_profile.field_bio': {'ru': 'О себе', 'en': 'Bio', 'ka': 'ჩემ შესახებ'},
  'edit_profile.field_avatar_url': {
    'ru': 'Ссылка на фото профиля (URL)',
    'en': 'Profile photo link (URL)',
    'ka': 'პროფილის ფოტოს ბმული (URL)',
  },
};
