/// Переводы для CarSpot Coins (внутренняя валюта): экран монет
/// (coins_screen.dart), пункт в настройках и диалог "буст за Premium или
/// за монеты" на экранах сходки и автосервиса (coin_boost_helper.dart).
///
/// Подключается централизованно в lib/l10n/app_translations.dart — этот файл
/// не редактировать вручную для wiring, только для добавления/правки строк.
const Map<String, Map<String, String>> kFeatureCoinsTranslations = {
  'settings.coins_title': {'ru': 'CarSpot Coins', 'en': 'CarSpot Coins', 'ka': 'CarSpot Coins'},
  'settings.coins_balance': {
    'ru': 'Баланс: {balance} монет',
    'en': 'Balance: {balance} coins',
    'ka': 'ბალანსი: {balance} მონეტა',
  },

  'boost.coins_balance_line': {
    'ru': 'У вас {balance} монет. Буст стоит {cost} монет.',
    'en': 'You have {balance} coins. Boost costs {cost} coins.',
    'ka': 'თქვენ გაქვთ {balance} მონეტა. დაწინაურება ღირს {cost} მონეტა.',
  },
  'boost.pay_with_coins_button': {
    'ru': 'Монетами ({cost})',
    'en': 'Coins ({cost})',
    'ka': 'მონეტებით ({cost})',
  },
  'boost.top_up_button': {
    'ru': 'Пополнить монеты',
    'en': 'Top up coins',
    'ka': 'მონეტების შევსება',
  },

  'coins.purchase_confirmed_snackbar': {
    'ru': 'Покупка подтверждена — монеты зачислены! 🎉',
    'en': 'Purchase confirmed — coins credited! 🎉',
    'ka': 'შესყიდვა დადასტურდა — მონეტები ჩაირიცხა! 🎉',
  },
  'coins.generic_error': {
    'ru': 'Ошибка: {error}',
    'en': 'Error: {error}',
    'ka': 'შეცდომა: {error}',
  },
  'coins.balance_label': {'ru': 'Ваш баланс', 'en': 'Your balance', 'ka': 'თქვენი ბალანსი'},
  'coins.what_for_title': {
    'ru': 'Зачем нужны монеты',
    'en': 'What coins are for',
    'ka': 'რისთვის გჭირდებათ მონეტები',
  },
  'coins.what_for_body': {
    'ru': 'Монетами CarSpot Coins можно поднять свою сходку или автосервис в топ ленты и каталога без подписки Premium. Подписчикам Premium такой буст всегда бесплатен — монеты нужны в первую очередь тем, у кого подписки нет.',
    'en': 'CarSpot Coins let you boost your meetup or auto service to the top of the feed and catalog without a Premium subscription. For Premium subscribers this boost is always free — coins are mainly for those without a subscription.',
    'ka': 'CarSpot Coins-ის საშუალებით შეგიძლიათ თქვენი შეხვედრა ან ავტოსერვისი ლენტისა და კატალოგის თავში აწიოთ Premium გამოწერის გარეშე. Premium-ის გამომწერებისთვის ეს დაწინაურება ყოველთვის უფასოა — მონეტები ძირითადად საჭიროა მათთვის, ვისაც გამოწერა არ აქვს.',
  },
  'coins.buy_title': {'ru': 'Купить монеты', 'en': 'Buy coins', 'ka': 'მონეტების ყიდვა'},
  'coins.buy_unavailable': {
    'ru': 'Покупка монет пока недоступна на этом устройстве.',
    'en': 'Buying coins is not available on this device yet.',
    'ka': 'მონეტების ყიდვა ამ მოწყობილობაზე ჯერ მიუწვდომელია.',
  },
  'coins.history_title': {'ru': 'История операций', 'en': 'Transaction history', 'ka': 'ოპერაციების ისტორია'},
  'coins.history_empty': {'ru': 'Пока нет операций', 'en': 'No transactions yet', 'ka': 'ჯერ არ არის ოპერაციები'},
  'coins.tx_purchase': {'ru': 'Покупка монет', 'en': 'Coin purchase', 'ka': 'მონეტების შესყიდვა'},
  'coins.tx_boost_event': {'ru': 'Буст сходки', 'en': 'Event boost', 'ka': 'შეხვედრის დაწინაურება'},
  'coins.tx_boost_business': {'ru': 'Буст автосервиса', 'en': 'Business boost', 'ka': 'ავტოსერვისის დაწინაურება'},

  'coins.open_profile_boost': {
    'ru': 'Прокачать профиль',
    'en': 'Boost your profile',
    'ka': 'პროფილის გაუმჯობესება',
  },

  'profile_boost.title': {'ru': 'Прокачка профиля', 'en': 'Profile boost', 'ka': 'პროფილის გაუმჯობესება'},
  'profile_boost.xp_title': {'ru': 'Бонусный опыт', 'en': 'Bonus XP', 'ka': 'ბონუს გამოცდილება'},
  'profile_boost.xp_body': {
    'ru': 'Сейчас бонуса: {bonus} XP. Он прибавляется поверх обычного уровня, который считается по вашей активности в приложении.',
    'en': 'Current bonus: {bonus} XP. It is added on top of your normal level, which is based on your activity in the app.',
    'ka': 'ამჟამინდელი ბონუსი: {bonus} XP. ის ემატება ჩვეულებრივ დონეს, რომელიც გამოითვლება აპში თქვენი აქტივობის მიხედვით.',
  },
  'profile_boost.xp_buy_button': {
    'ru': 'Купить +{grant} XP за {cost} монет',
    'en': 'Buy +{grant} XP for {cost} coins',
    'ka': 'იყიდეთ +{grant} XP {cost} მონეტად',
  },
  'profile_boost.xp_bought_snackbar': {
    'ru': 'Бонусный опыт начислен! 🎉',
    'en': 'Bonus XP credited! 🎉',
    'ka': 'ბონუს გამოცდილება ჩაირიცხა! 🎉',
  },

  'profile_boost.search_title': {'ru': 'Буст в поиске', 'en': 'Search boost', 'ka': 'ძებნის დაწინაურება'},
  'profile_boost.search_body': {
    'ru': 'Поднимите свой профиль в топ результатов поиска пользователей на {hours} ч.',
    'en': 'Boost your profile to the top of user search results for {hours} h.',
    'ka': 'აწიეთ თქვენი პროფილი მომხმარებელთა ძებნის შედეგების თავში {hours} სთ-ით.',
  },
  'profile_boost.search_buy_button': {
    'ru': 'Поднять профиль за {cost} монет',
    'en': 'Boost profile for {cost} coins',
    'ka': 'პროფილის აწევა {cost} მონეტად',
  },
  'profile_boost.search_active': {
    'ru': 'Буст уже активен',
    'en': 'Boost already active',
    'ka': 'დაწინაურება უკვე აქტიურია',
  },
  'profile_boost.search_boost_bought_snackbar': {
    'ru': 'Профиль поднят в топ поиска! 🎉',
    'en': 'Profile boosted to the top of search! 🎉',
    'ka': 'პროფილი აიწია ძებნის თავში! 🎉',
  },

  'profile_boost.frames_title': {'ru': 'Рамки аватара', 'en': 'Avatar frames', 'ka': 'ავატარის ჩარჩოები'},
  'profile_boost.badges_title': {'ru': 'Значки', 'en': 'Badges', 'ka': 'ნიშნები'},
  'profile_boost.colors_title': {'ru': 'Цвет имени', 'en': 'Name color', 'ka': 'სახელის ფერი'},
  'profile_boost.cosmetic_buy': {
    'ru': 'Купить за {cost}',
    'en': 'Buy for {cost}',
    'ka': 'ყიდვა {cost}-ად',
  },
  'profile_boost.cosmetic_equip': {'ru': 'Надеть', 'en': 'Equip', 'ka': 'ატარება'},
  'profile_boost.cosmetic_unequip': {'ru': 'Снять', 'en': 'Unequip', 'ka': 'მოხსნა'},
};
