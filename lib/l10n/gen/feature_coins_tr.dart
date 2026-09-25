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
};
