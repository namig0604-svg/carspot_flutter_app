/// Переводы для экрана управления рангами администрации и выдачи монет
/// (admin_ranks_screen.dart) — доступен только пользователям с назначенным
/// admin_rank (модератор/администратор/тех.администратор/разработчик).
///
/// Подключается централизованно в lib/l10n/app_translations.dart — этот файл
/// не редактировать вручную для wiring, только для добавления/правки строк.
const Map<String, Map<String, String>> kFeatureAdminRanksTranslations = {
  'settings.admin_ranks_link': {
    'ru': 'Ранги и выдача монет',
    'en': 'Ranks & coin grants',
    'ka': 'რანგები და მონეტების გაცემა',
  },
  'settings.admin_ranks_subtitle': {
    'ru': 'Назначение рангов администрации и ручная выдача монет',
    'en': 'Assign admin ranks and grant coins manually',
    'ka': 'ადმინისტრაციის რანგების მინიჭება და მონეტების ხელით გაცემა',
  },
  'admin_ranks.title': {
    'ru': 'Ранги администрации',
    'en': 'Admin ranks',
    'ka': 'ადმინისტრაციის რანგები',
  },
  'admin_ranks.search_hint': {
    'ru': 'Поиск по имени пользователя',
    'en': 'Search by username',
    'ka': 'ძებნა მომხმარებლის სახელით',
  },
  'admin_ranks.grant_coins_tooltip': {
    'ru': 'Выдать монеты',
    'en': 'Grant coins',
    'ka': 'მონეტების გაცემა',
  },
  'admin_ranks.grant_coins_title': {
    'ru': 'Выдать монеты {username}',
    'en': 'Grant coins to {username}',
    'ka': 'მონეტების გადაცემა {username}-ს',
  },
  'admin_ranks.amount_label': {
    'ru': 'Количество монет',
    'en': 'Coin amount',
    'ka': 'მონეტების რაოდენობა',
  },
  'admin_ranks.reason_label_optional': {
    'ru': 'Причина (необязательно)',
    'en': 'Reason (optional)',
    'ka': 'მიზეზი (არასავალდებულო)',
  },
  'admin_ranks.invalid_amount': {
    'ru': 'Введите корректное число монет',
    'en': 'Enter a valid coin amount',
    'ka': 'შეიყვანეთ მონეტების სწორი რაოდენობა',
  },
  'admin_ranks.grant_coins_success': {
    'ru': 'Выдано {amount} монет. Новый баланс: {balance}',
    'en': 'Granted {amount} coins. New balance: {balance}',
    'ka': 'გაცემულია {amount} მონეტა. ახალი ბალანსი: {balance}',
  },
  'admin_ranks.set_rank_title': {
    'ru': 'Ранг для {username}',
    'en': 'Rank for {username}',
    'ka': 'რანგი {username}-სთვის',
  },
  'admin_ranks.no_rank': {
    'ru': 'Без ранга',
    'en': 'No rank',
    'ka': 'რანგის გარეშე',
  },
  'admin_ranks.rank_updated': {
    'ru': 'Ранг обновлён',
    'en': 'Rank updated',
    'ka': 'რანგი განახლდა',
  },
  'admin_ranks.grant_coins_action': {
    'ru': 'Выдать монеты',
    'en': 'Grant coins',
    'ka': 'მონეტების გადაცემა',
  },
  'admin_ranks.set_rank_action': {
    'ru': 'Назначить ранг',
    'en': 'Set rank',
    'ka': 'რანგის მინიჭება',
  },
  'admin_ranks.current_admins_title': {
    'ru': 'Текущая администрация',
    'en': 'Current admins',
    'ka': 'მიმდინარე ადმინისტრაცია',
  },
  'admin_ranks.no_admins': {
    'ru': 'Пока никто не назначен',
    'en': 'No one assigned yet',
    'ka': 'ჯერ არავინ არის დანიშნული',
  },
};
