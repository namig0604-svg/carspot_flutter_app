/// Сезонные челленджи — экран ChallengesScreen и утилита challenge_goal.dart.
/// Только ru/en/ka — остальные 4 языка падают на русский по общей схеме
/// (см. tr() в app_translations.dart), как и FAQ/гайд.
/// Подключается централизованно в lib/l10n/app_translations.dart.
const Map<String, Map<String, String>> kFeatureChallengesTranslations = {
  'challenges.title': {'ru': 'Сезонные челленджи', 'en': 'Seasonal challenges', 'ka': 'სეზონური გამოწვევები'},
  'home.menu_challenges': {'ru': 'Челленджи', 'en': 'Challenges', 'ka': 'გამოწვევები'},
  'challenges.empty_title': {
    'ru': 'Сейчас нет активных челленджей — загляните позже',
    'en': 'No active challenges right now — check back later',
    'ka': 'ამჟამად აქტიური გამოწვევები არ არის — შემოწმეთ მოგვიანებით',
  },
  'challenges.error_message': {
    'ru': 'Не удалось загрузить челленджи: {error}',
    'en': 'Couldn’t load challenges: {error}',
    'ka': 'გამოწვევების ჩატვირთვა ვერ მოხერხდა: {error}',
  },
  'challenges.claim_button': {'ru': 'Забрать награду', 'en': 'Claim reward', 'ka': 'ჯილდოს მიღება'},
  'challenges.claimed_label': {'ru': 'Награда получена', 'en': 'Reward claimed', 'ka': 'ჯილდო მიღებულია'},
  'challenges.claim_success': {
    'ru': 'Награда начислена: +{xp} XP, +{coins} монет',
    'en': 'Reward granted: +{xp} XP, +{coins} coins',
    'ka': 'ჯილდო ჩაირიცხა: +{xp} XP, +{coins} მონეტა',
  },
  'challenges.ends_in_days': {
    'ru': 'Осталось {days} дн.',
    'en': '{days}d left',
    'ka': 'დარჩა {days} დღე',
  },
  'challenges.goal_attend_events': {
    'ru': 'Посетить сходки',
    'en': 'Attend meetups',
    'ka': 'შეხვედრების დასწრება',
  },
  'challenges.goal_create_events': {
    'ru': 'Создать сходки',
    'en': 'Create meetups',
    'ka': 'შეხვედრების შექმნა',
  },
  'challenges.goal_add_cars': {
    'ru': 'Добавить машины в гараж',
    'en': 'Add cars to your garage',
    'ka': 'მანქანების დამატება გარაჟში',
  },
  'challenges.goal_rate_events': {
    'ru': 'Оценить сходки',
    'en': 'Rate meetups',
    'ka': 'შეხვედრების შეფასება',
  },
  'home.challenges_banner_label': {
    'ru': 'Активный челлендж',
    'en': 'Active challenge',
    'ka': 'აქტიური გამოწვევა',
  },
  'home.challenges_banner_view_all': {
    'ru': 'Все челленджи',
    'en': 'All challenges',
    'ka': 'ყველა გამოწვევა',
  },
};
