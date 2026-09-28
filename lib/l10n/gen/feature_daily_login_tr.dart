/// Переводы для ежедневного входа (daily_login_dialog.dart, бэкенд
/// app/api/daily_login.py). Подключается централизованно в
/// lib/l10n/app_translations.dart.
const Map<String, Map<String, String>> kFeatureDailyLoginTranslations = {
  'daily_login.title': {
    'ru': 'Ежедневный вход',
    'en': 'Daily login',
    'ka': 'ყოველდღიური შესვლა',
  },
  'daily_login.hint': {
    'ru': 'Заходи каждый день — получай опыт и монеты. 7 дней подряд — неделя CarSpot Basic в подарок.',
    'en': 'Come back every day for XP and coins. 7 days in a row gives you a free week of CarSpot Basic.',
    'ka': 'შედი ყოველდღე — მიიღე გამოცდილება და მონეტები. 7 დღე ზედიზედ — CarSpot Basic საჩუქრად.',
  },
  'daily_login.claim_button': {
    'ru': 'Забрать награду',
    'en': 'Claim reward',
    'ka': 'ჯილდოს აღება',
  },
  'daily_login.already_claimed': {
    'ru': 'Уже получено сегодня — приходите завтра',
    'en': 'Already claimed today — come back tomorrow',
    'ka': 'დღეს უკვე აღებულია — ჩამოდი ხვალ',
  },
  'daily_login.reward_gained': {
    'ru': '+{xp} XP, +{coins} монет',
    'en': '+{xp} XP, +{coins} coins',
    'ka': '+{xp} XP, +{coins} მონეტა',
  },
  'daily_login.bonus_message': {
    'ru': '7 дней подряд! Плюс неделя CarSpot Basic в подарок',
    'en': '7 days in a row! Plus a free week of CarSpot Basic',
    'ka': '7 დღე ზედიზედ! პლუს CarSpot Basic ერთი კვირით საჩუქრად',
  },
};
