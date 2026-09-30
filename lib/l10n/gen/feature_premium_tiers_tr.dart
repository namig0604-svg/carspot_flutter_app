/// Переводы для уровней CarSpot Premium (Basic/Pro): экран Premium
/// (premium_screen.dart), экран управления подпиской
/// (subscription_management_screen.dart) и выдача Premium через
/// admin_ranks_screen.dart.
///
/// Подключается централизованно в lib/l10n/app_translations.dart — этот файл
/// не редактировать вручную для wiring, только для добавления/правки строк.
const Map<String, Map<String, String>> kFeaturePremiumTiersTranslations = {
  'premium.status_active_basic': {
    'ru': 'CarSpot Basic активен',
    'en': 'CarSpot Basic active',
    'ka': 'CarSpot Basic აქტიურია',
  },
  'premium.status_active_pro': {
    'ru': 'CarSpot Pro активен',
    'en': 'CarSpot Pro active',
    'ka': 'CarSpot Pro აქტიურია',
  },
  'premium.subscription_management_tooltip': {
    'ru': 'Управление подпиской',
    'en': 'Manage subscription',
    'ka': 'გამოწერის მართვა',
  },
  'premium.best_value_badge': {
    'ru': 'Выбор большинства',
    'en': 'Most popular',
    'ka': 'ყველაზე პოპულარული',
  },
  'premium.top_tier_badge': {
    'ru': 'Топ-уровень',
    'en': 'Top tier',
    'ka': 'უმაღლესი დონე',
  },
  'premium.status_active_max': {
    'ru': 'CarSpot Max активен',
    'en': 'CarSpot Max active',
    'ka': 'CarSpot Max აქტიურია',
  },
  'premium.compare_bonus_xp': {
    'ru': 'Бонус XP за покупку',
    'en': 'Bonus XP on purchase',
    'ka': 'ბონუს XP შეძენისას',
  },
  'premium.compare_bonus_coins': {
    'ru': 'Бонус монет за покупку',
    'en': 'Bonus coins on purchase',
    'ka': 'ბონუს მონეტები შეძენისას',
  },
  'premium.compare_status_name': {
    'ru': 'Статусный цвет ника',
    'en': 'Status name color',
    'ka': 'სტატუსური ფერის ნიკი',
  },
  'premium.compare_priority': {
    'ru': 'Приоритет в участниках',
    'en': 'Priority in participants',
    'ka': 'პრიორიტეტი მონაწილეებში',
  },
  'premium.compare_title': {
    'ru': 'Сравнение уровней',
    'en': 'Compare tiers',
    'ka': 'დონეების შედარება',
  },
  'premium.compare_garage': {
    'ru': 'Машин в гараже',
    'en': 'Cars in garage',
    'ka': 'მანქანები გარაჟში',
  },
  'premium.compare_insights': {
    'ru': 'Кто лайкнул / смотрел',
    'en': 'Who liked / viewed',
    'ka': 'ვინ მოიწონა / ნახა',
  },
  'premium.compare_business': {
    'ru': 'Автосервисов/ателье',
    'en': 'Businesses',
    'ka': 'ავტოსერვისები',
  },
  'premium.compare_free_boost': {
    'ru': 'Бесплатный буст в топ',
    'en': 'Free top boost',
    'ka': 'უფასო ბუსტი',
  },
  'premium.compare_pinned_photos': {
    'ru': 'Закреплённые фото',
    'en': 'Pinned photos',
    'ka': 'დამაგრებული ფოტოები',
  },

  // Свайп-стек выбора тарифа на экране Premium (редизайн в стиле Tinder:
  // свайп влево — тариф дороже, вправо — дешевле).
  'premium.swipe_hint': {
    'ru': 'Смахните карточку: влево — тариф дороже, вправо — дешевле',
    'en': 'Swipe the card: left for a pricier tier, right for a cheaper one',
    'ka': 'გადაფურცლეთ ბარათი: მარცხნივ — უფრო ძვირი, მარჯვნივ — იაფი',
  },
  'premium.includes_basic_plus': {
    'ru': 'Всё из Basic, плюс:',
    'en': 'Everything in Basic, plus:',
    'ka': 'ყველაფერი Basic-დან, პლუს:',
  },
  'premium.includes_pro_plus': {
    'ru': 'Всё из Pro, плюс:',
    'en': 'Everything in Pro, plus:',
    'ka': 'ყველაფერი Pro-დან, პლუს:',
  },
  'premium.detailed_compare_title': {
    'ru': 'Подробное сравнение тарифов',
    'en': 'Detailed tier comparison',
    'ka': 'დონეების დეტალური შედარება',
  },
  'premium.detailed_perks_title': {
    'ru': 'Все привилегии по отдельности',
    'en': 'All perks in detail',
    'ka': 'ყველა პრივილეგია დეტალურად',
  },
  'subscription_mgmt.title': {
    'ru': 'Управление подпиской',
    'en': 'Manage subscription',
    'ka': 'გამოწერის მართვა',
  },
  'subscription_mgmt.no_active_plan': {
    'ru': 'Подписка не активна',
    'en': 'No active plan',
    'ka': 'გამოწერა არააქტიურია',
  },
  'subscription_mgmt.active_until': {
    'ru': 'Активна до {date}',
    'en': 'Active until {date}',
    'ka': 'აქტიურია {date}-მდე',
  },
  'subscription_mgmt.manage_in_play_store': {
    'ru': 'Управлять в Google Play',
    'en': 'Manage in Google Play',
    'ka': 'მართვა Google Play-ში',
  },
  'subscription_mgmt.trybit_note': {
    'ru': 'Оплата картой/крипто — разовая, без автопродления. Подписки через Google Play управляются и отменяются в Play Store.',
    'en': 'Card/crypto payment is one-time, no auto-renewal. Google Play subscriptions are managed and canceled in the Play Store.',
    'ka': 'ბარათით/კრიპტოთი გადახდა ერთჯერადია, ავტომატური განახლების გარეშე. Google Play გამოწერები იმართება Play Store-ში.',
  },
  'subscription_mgmt.history_title': {
    'ru': 'История платежей',
    'en': 'Payment history',
    'ka': 'გადახდების ისტორია',
  },
  'subscription_mgmt.status_paid': {
    'ru': 'Оплачено',
    'en': 'Paid',
    'ka': 'გადახდილი',
  },
  'subscription_mgmt.status_pending': {
    'ru': 'Ожидает оплаты',
    'en': 'Pending',
    'ka': 'მოლოდინში',
  },
  'subscription_mgmt.status_failed': {
    'ru': 'Не оплачено',
    'en': 'Not paid',
    'ka': 'გადაუხდელი',
  },
  'subscription_mgmt.load_error': {
    'ru': 'Не удалось загрузить: {error}',
    'en': 'Failed to load: {error}',
    'ka': 'ჩატვირთვა ვერ მოხერხდა: {error}',
  },
  'subscription_mgmt.no_payments': {
    'ru': 'Платежей пока нет',
    'en': 'No payments yet',
    'ka': 'ჯერ არ არის გადახდები',
  },
  'subscription_mgmt.days_suffix': {
    'ru': 'дн.',
    'en': 'days',
    'ka': 'დღე',
  },
  'subscription_mgmt.play_store_open_failed': {
    'ru': 'Не удалось открыть Google Play',
    'en': 'Failed to open Google Play',
    'ka': 'Google Play ვერ გაიხსნა',
  },
  'admin_ranks.grant_premium_title': {
    'ru': 'Выдать Premium {username}',
    'en': 'Grant Premium to {username}',
    'ka': 'Premium-ის მინიჭება {username}-ს',
  },
  'admin_ranks.days_label': {
    'ru': 'Количество дней',
    'en': 'Number of days',
    'ka': 'დღეების რაოდენობა',
  },
  'admin_ranks.invalid_days': {
    'ru': 'Введите корректное число дней',
    'en': 'Enter a valid number of days',
    'ka': 'შეიყვანეთ დღეების სწორი რაოდენობა',
  },
  'admin_ranks.grant_premium_success': {
    'ru': 'Premium ({tier}) выдан',
    'en': 'Premium ({tier}) granted',
    'ka': 'Premium ({tier}) მინიჭებულია',
  },
  'admin_ranks.grant_premium_action': {
    'ru': 'Выдать Premium',
    'en': 'Grant Premium',
    'ka': 'Premium-ის მინიჭება',
  },
};
