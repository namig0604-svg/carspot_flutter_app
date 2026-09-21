/// Переводы для батча 6: premium_screen, car_detail_screen,
/// location_picker_screen, club_form_screen.
///
/// Подключается centrально в app_translations.dart (см. lib/l10n/app_translations.dart) —
/// этот файл сам по себе ничего не делает, пока его не смёрджат в kTranslations.
const Map<String, Map<String, String>> kBatch6Translations = {
  // ─────────────────────────── premium_screen.dart ───────────────────────────
  'premium.trial_activated_snackbar': {
    'ru': 'Пробный Premium активирован на 14 дней 🎉',
    'en': 'Your 14-day Premium trial is now active 🎉',
    'ka': 'Premium-ის 14-დღიანი საცდელი პერიოდი გააქტიურდა 🎉',
  },
  'premium.trial_activate_failed': {
    'ru': 'Не удалось активировать: {error}',
    'en': 'Could not activate: {error}',
    'ka': 'ვერ მოხერხდა გააქტიურება: {error}',
  },
  'premium.checkout_no_invoice_error': {
    'ru': 'Не удалось создать счёт на оплату',
    'en': 'Could not create a payment invoice',
    'ka': 'ვერ შეიქმნა გადახდის ინვოისი',
  },
  'premium.checkout_open_failed_error': {
    'ru': 'Не удалось открыть страницу оплаты',
    'en': 'Could not open the payment page',
    'ka': 'ვერ გაიხსნა გადახდის გვერდი',
  },
  'premium.generic_error': {
    'ru': 'Ошибка: {error}',
    'en': 'Error: {error}',
    'ka': 'შეცდომა: {error}',
  },
  'premium.payment_confirmed_snackbar': {
    'ru': 'Оплата подтверждена — Premium активирован! 🎉',
    'en': 'Payment confirmed — Premium is active! 🎉',
    'ka': 'გადახდა დადასტურდა — Premium გააქტიურდა! 🎉',
  },
  'premium.payment_failed_snackbar': {
    'ru': 'Оплата не прошла — попробуй ещё раз',
    'en': 'Payment failed — please try again',
    'ka': 'გადახდა ვერ შედგა — სცადე ხელახლა',
  },
  'premium.payment_pending_snackbar': {
    'ru': 'Пока не оплачено — оплати по открытой ссылке и попробуй снова',
    'en': 'Not paid yet — complete the payment via the opened link and try again',
    'ka': 'ჯერ არ არის გადახდილი — გადაიხადე გახსნილი ბმულით და სცადე ხელახლა',
  },
  'premium.likers_locked_snackbar': {
    'ru': 'Список тех, кто лайкнул профиль, доступен с Premium',
    'en': 'The list of everyone who liked your profile is available with Premium',
    'ka': 'პროფილის მოწონებების სია ხელმისაწვდომია Premium-ით',
  },
  'premium.likers_screen_title': {
    'ru': 'Кто лайкнул профиль',
    'en': 'Who liked your profile',
    'ka': 'ვინ მოიწონა პროფილი',
  },
  'premium.views_locked_snackbar': {
    'ru': 'Список просмотров профиля доступен с Premium',
    'en': 'The list of profile views is available with Premium',
    'ka': 'პროფილის ნახვების სია ხელმისაწვდომია Premium-ით',
  },
  'premium.viewed_on': {
    'ru': 'Смотрел {date}',
    'en': 'Viewed {date}',
    'ka': 'ნანახია {date}',
  },
  'premium.viewers_screen_title': {
    'ru': 'Кто смотрел профиль',
    'en': 'Who viewed your profile',
    'ka': 'ვინ ნახა პროფილი',
  },
  'premium.status_active': {
    'ru': 'Premium активен',
    'en': 'Premium is active',
    'ka': 'Premium აქტიურია',
  },
  'premium.status_inactive': {
    'ru': 'Premium не активен',
    'en': 'Premium is inactive',
    'ka': 'Premium არააქტიურია',
  },
  'premium.active_until': {
    'ru': 'Действует до {date}',
    'en': 'Active until {date}',
    'ka': 'მოქმედებს {date}-მდე',
  },
  'premium.hero_subtitle_inactive': {
    'ru': 'Открой автосервисы, больше машин в гараже и другие возможности',
    'en': 'Unlock auto shops, more cars in your garage, and more',
    'ka': 'გახსენი ავტოსერვისები, მეტი მანქანა გარაჟში და სხვა შესაძლებლობები',
  },
  'premium.trial_button': {
    'ru': 'Попробовать 14 дней бесплатно',
    'en': 'Try 14 days free',
    'ka': 'სცადე 14 დღე უფასოდ',
  },
  'premium.trial_used_notice': {
    'ru': 'Пробный период уже использован. Получи Premium снова через реферальную программу ниже.',
    'en': 'You have already used your free trial. Earn Premium again through the referral program below.',
    'ka': 'საცდელი პერიოდი უკვე გამოყენებულია. მიიღე Premium ისევ ქვემოთ მოცემული სარეფერალო პროგრამით.',
  },
  'premium.renew_title': {
    'ru': 'Продлить Premium',
    'en': 'Renew Premium',
    'ka': 'Premium-ის გაგრძელება',
  },
  'premium.buy_title': {
    'ru': 'Купить Premium',
    'en': 'Get Premium',
    'ka': 'Premium-ის შეძენა',
  },
  'premium.payment_method_note': {
    'ru': 'Оплата через Trybit — картой или криптовалютой, работает в любой стране СНГ',
    'en': 'Pay via Trybit — by card or crypto, works in any CIS country',
    'ka': 'გადახდა Trybit-ით — ბარათით ან კრიპტოვალუტით, მუშაობს დსთ-ის ნებისმიერ ქვეყანაში',
  },
  'premium.awaiting_payment': {
    'ru': 'Ждём подтверждения оплаты...',
    'en': 'Waiting for payment confirmation...',
    'ka': 'ველოდებით გადახდის დადასტურებას...',
  },
  'premium.check_now_button': {
    'ru': 'Проверить сейчас',
    'en': 'Check now',
    'ka': 'შემოწმება ახლავე',
  },
  'premium.referral_title': {
    'ru': 'Реферальная программа',
    'en': 'Referral program',
    'ka': 'სარეფერალო პროგრამა',
  },
  'premium.copy_code_tooltip': {
    'ru': 'Скопировать код',
    'en': 'Copy code',
    'ka': 'კოდის კოპირება',
  },
  'premium.code_copied_snackbar': {
    'ru': 'Код скопирован',
    'en': 'Code copied',
    'ka': 'კოდი დაკოპირდა',
  },
  'premium.loading_code': {
    'ru': 'Загружаем код...',
    'en': 'Loading code...',
    'ka': 'იტვირთება კოდი...',
  },
  'premium.referral_stats': {
    'ru': 'Приглашено друзей: {count} · заработано месяцев Premium: {months}',
    'en': 'Friends invited: {count} · Premium months earned: {months}',
    'ka': 'მოწვეული მეგობრები: {count} · დაგროვილი Premium თვეები: {months}',
  },
  'premium.referral_invite_prompt': {
    'ru': 'Пригласи {count} друзей — получи месяц Premium',
    'en': 'Invite {count} friends — get a month of Premium',
    'ka': 'მოიწვიე {count} მეგობარი — მიიღე Premium-ის თვე',
  },
  'premium.referral_remaining': {
    'ru': 'Ещё {count} друзей до следующего месяца Premium',
    'en': '{count} more friends until your next month of Premium',
    'ka': 'კიდევ {count} მეგობარია შემდეგ Premium თვემდე',
  },
  'premium.popularity_title': {
    'ru': 'Твоя популярность',
    'en': 'Your popularity',
    'ka': 'შენი პოპულარობა',
  },
  'premium.likes_count_label': {
    'ru': '{count} лайков профиля',
    'en': '{count} profile likes',
    'ka': 'პროფილის {count} მოწონება',
  },
  'premium.see_who_liked': {
    'ru': 'Смотри, кто лайкнул',
    'en': 'See who liked you',
    'ka': 'ნახე, ვინ მოგწონა',
  },
  'premium.subscribe_to_see_who': {
    'ru': 'Оформи Premium, чтобы увидеть кто',
    'en': 'Get Premium to see who',
    'ka': 'გააფორმე Premium რომ გაარკვიო ვინ',
  },
  'premium.views_count_label': {
    'ru': '{count} просмотров профиля',
    'en': '{count} profile views',
    'ka': 'პროფილის {count} ნახვა',
  },
  'premium.see_who_viewed': {
    'ru': 'Смотри, кто заходил',
    'en': 'See who visited',
    'ka': 'ნახე, ვინ შემოვიდა',
  },
  'premium.perks_title': {
    'ru': 'Что даёт Premium',
    'en': 'What Premium gives you',
    'ka': 'რას გაძლევს Premium',
  },
  'premium.perk_likers_title': {
    'ru': 'Кто лайкнул и кто смотрел',
    'en': 'Who liked and who viewed',
    'ka': 'ვინ მოიწონა და ვინ ნახა',
  },
  'premium.perk_likers_subtitle': {
    'ru': 'Полные списки тех, кто лайкнул профиль/машину и кто заходил к тебе в профиль',
    'en': 'Full lists of everyone who liked your profile or car, and everyone who visited your profile',
    'ka': 'სრული სიები იმათი, ვინც მოიწონა შენი პროფილი ან მანქანა და ვინც ეწვია შენს პროფილს',
  },
  'premium.perk_boost_title': {
    'ru': 'Буст сходок и заведений',
    'en': 'Boost meetups and venues',
    'ka': 'შეხვედრებისა და დაწესებულებების ბუსტი',
  },
  'premium.perk_boost_subtitle': {
    'ru': 'Поднимай свою сходку или автосервис в топ ленты и каталога на 24 часа',
    'en': 'Push your meetup or auto shop to the top of the feed and catalog for 24 hours',
    'ka': 'აწიე შენი შეხვედრა ან ავტოსერვისი ლენტისა და კატალოგის სათავეში 24 საათით',
  },
  'premium.perk_services_title': {
    'ru': 'Добавление автосервисов',
    'en': 'List your auto shop',
    'ka': 'ავტოსერვისების დამატება',
  },
  'premium.perk_services_subtitle': {
    'ru': 'Только подписчики Premium могут размещать свои автосервисы и ателье в CarSpot',
    'en': 'Only Premium subscribers can list their auto shops and tuning studios on CarSpot',
    'ka': 'მხოლოდ Premium გამომწერებს შეუძლიათ განათავსონ თავიანთი ავტოსერვისები და ატელიეები CarSpot-ში',
  },
  'premium.perk_garage_title': {
    'ru': 'Больше машин в гараже',
    'en': 'More cars in your garage',
    'ka': 'მეტი მანქანა გარაჟში',
  },
  'premium.perk_garage_subtitle': {
    'ru': 'До 25 машин вместо 10 на обычном аккаунте',
    'en': 'Up to 25 cars instead of 10 on a regular account',
    'ka': 'ჩვეულებრივ ანგარიშზე 10-ის ნაცვლად — 25 მანქანამდე',
  },
  'premium.perk_pinned_photos_title': {
    'ru': 'Закреплённые фото',
    'en': 'Pinned photos',
    'ka': 'დამაგრებული ფოტოები',
  },
  'premium.perk_pinned_photos_subtitle': {
    'ru': 'Закрепляй свои лучшие фото сверху галереи сходки или машины',
    'en': 'Pin your best photos to the top of a meetup or car gallery',
    'ka': 'დაამაგრე შენი საუკეთესო ფოტოები შეხვედრის ან მანქანის გალერეის თავში',
  },
  'premium.perk_badge_title': {
    'ru': 'Premium-значок',
    'en': 'Premium badge',
    'ka': 'Premium ნიშანი',
  },
  'premium.perk_badge_subtitle': {
    'ru': 'Золотая корона рядом с именем в профиле и на сходках',
    'en': 'A gold crown next to your name in your profile and at meetups',
    'ka': 'ოქროს გვირგვინი შენი სახელის გვერდით პროფილსა და შეხვედრებზე',
  },
  'premium.perk_achievement_title': {
    'ru': 'Эксклюзивное достижение',
    'en': 'Exclusive achievement',
    'ka': 'ექსკლუზიური მიღწევა',
  },
  'premium.perk_achievement_subtitle': {
    'ru': 'Отдельное достижение «Premium» в списке наград профиля',
    'en': 'A dedicated "Premium" achievement in your profile\'s badge list',
    'ka': 'ცალკე „Premium" მიღწევა შენი პროფილის ჯილდოების სიაში',
  },

  // ─────────────────────────── car_detail_screen.dart ───────────────────────────
  'car_detail.generic_error': {
    'ru': 'Ошибка: {error}',
    'en': 'Error: {error}',
    'ka': 'შეცდომა: {error}',
  },
  'car_detail.premium_only_title': {
    'ru': 'Только для Premium',
    'en': 'Premium only',
    'ka': 'მხოლოდ Premium-ისთვის',
  },
  'car_detail.premium_only_content': {
    'ru': 'Список тех, кто лайкнул машину, доступен только с CarSpot Premium.',
    'en': 'The list of everyone who liked this car is available only with CarSpot Premium.',
    'ka': 'მანქანის მოწონებების სია ხელმისაწვდომია მხოლოდ CarSpot Premium-ით.',
  },
  'car_detail.learn_more_button': {
    'ru': 'Узнать больше',
    'en': 'Learn more',
    'ka': 'გაიგე მეტი',
  },
  'car_detail.likers_title': {
    'ru': 'Кто лайкнул машину',
    'en': 'Who liked the car',
    'ka': 'ვინ მოიწონა მანქანა',
  },
  'car_detail.delete_confirm_title': {
    'ru': 'Удалить машину?',
    'en': 'Delete this car?',
    'ka': 'წავშალოთ მანქანა?',
  },
  'car_detail.delete_confirm_content': {
    'ru': 'Это нельзя отменить.',
    'en': 'This cannot be undone.',
    'ka': 'ამის გაუქმება შეუძლებელია.',
  },
  'car_detail.title_fallback': {
    'ru': 'Машина',
    'en': 'Car',
    'ka': 'მანქანა',
  },
  'car_detail.set_primary_tooltip': {
    'ru': 'Сделать основной',
    'en': 'Set as primary',
    'ka': 'მთავრად დაყენება',
  },
  'car_detail.not_found': {
    'ru': 'Машина не найдена',
    'en': 'Car not found',
    'ka': 'მანქანა ვერ მოიძებნა',
  },
  'car_detail.badge_primary': {
    'ru': 'Основная',
    'en': 'Primary',
    'ka': 'მთავარი',
  },
  'car_detail.badge_for_sale': {
    'ru': 'Продаётся',
    'en': 'For sale',
    'ka': 'იყიდება',
  },
  'car_detail.likes_who_label': {
    'ru': '{count} · кто?',
    'en': '{count} · who?',
    'ka': '{count} · ვინ?',
  },
  'car_detail.photo_button': {
    'ru': 'Фото',
    'en': 'Photos',
    'ka': 'ფოტოები',
  },
  'car_detail.photo_gallery_title': {
    'ru': 'Фото машины',
    'en': 'Car photos',
    'ka': 'მანქანის ფოტოები',
  },
  'car_detail.specs_title': {
    'ru': 'Характеристики',
    'en': 'Specifications',
    'ka': 'მახასიათებლები',
  },
  'car_detail.spec_engine': {
    'ru': 'Двигатель',
    'en': 'Engine',
    'ka': 'ძრავი',
  },
  'car_detail.spec_volume': {
    'ru': 'Объём',
    'en': 'Displacement',
    'ka': 'მოცულობა',
  },
  'car_detail.spec_power': {
    'ru': 'Мощность',
    'en': 'Power',
    'ka': 'სიმძლავრე',
  },
  'car_detail.spec_torque': {
    'ru': 'Крутящий момент',
    'en': 'Torque',
    'ka': 'ბრუნვის მომენტი',
  },
  'car_detail.spec_drivetrain': {
    'ru': 'Привод',
    'en': 'Drivetrain',
    'ka': 'წამყვანი',
  },
  'car_detail.spec_transmission': {
    'ru': 'Трансмиссия',
    'en': 'Transmission',
    'ka': 'ტრანსმისია',
  },
  'car_detail.spec_fuel': {
    'ru': 'Топливо',
    'en': 'Fuel',
    'ka': 'საწვავი',
  },
  'car_detail.spec_weight': {
    'ru': 'Вес',
    'en': 'Weight',
    'ka': 'წონა',
  },
  'car_detail.spec_zero_to_hundred': {
    'ru': '0-100',
    'en': '0-100',
    'ka': '0-100',
  },
  'car_detail.spec_color': {
    'ru': 'Цвет',
    'en': 'Color',
    'ka': 'ფერი',
  },
  'car_detail.spec_plate': {
    'ru': 'Госномер',
    'en': 'License plate',
    'ka': 'სახელმწიფო ნომერი',
  },
  'car_detail.unit_hp': {
    'ru': '{value} л.с.',
    'en': '{value} hp',
    'ka': '{value} ცხ.ძ.',
  },
  'car_detail.unit_nm': {
    'ru': '{value} Нм',
    'en': '{value} Nm',
    'ka': '{value} ნმ',
  },
  'car_detail.unit_kg': {
    'ru': '{value} кг',
    'en': '{value} kg',
    'ka': '{value} კგ',
  },
  'car_detail.unit_sec': {
    'ru': '{value} с',
    'en': '{value} s',
    'ka': '{value} წმ',
  },
  'car_detail.mods_title': {
    'ru': 'Доработки',
    'en': 'Modifications',
    'ka': 'გადაკეთებები',
  },
  'car_detail.description_title': {
    'ru': 'Описание',
    'en': 'Description',
    'ka': 'აღწერა',
  },

  // ─────────────────────────── location_picker_screen.dart ───────────────────────────
  'location_picker.title': {
    'ru': 'Укажи точку на карте',
    'en': 'Pick a point on the map',
    'ka': 'მონიშნე წერტილი რუკაზე',
  },
  'location_picker.tap_hint': {
    'ru': 'Нажми на карту, чтобы поставить метку',
    'en': 'Tap the map to drop a pin',
    'ka': 'შეეხე რუკას მარკერის დასადებად',
  },

  // ─────────────────────────── club_form_screen.dart ───────────────────────────
  'club_form.name_min_length_error': {
    'ru': 'Название клуба — минимум 3 символа',
    'en': 'Club name must be at least 3 characters',
    'ka': 'კლუბის სახელი — მინიმუმ 3 სიმბოლო',
  },
  'club_form.club_updated_snackbar': {
    'ru': 'Клуб обновлён',
    'en': 'Club updated',
    'ka': 'კლუბი განახლდა',
  },
  'club_form.club_created_snackbar': {
    'ru': 'Клуб создан 🏁',
    'en': 'Club created 🏁',
    'ka': 'კლუბი შეიქმნა 🏁',
  },
  'club_form.generic_error': {
    'ru': 'Ошибка: {error}',
    'en': 'Error: {error}',
    'ka': 'შეცდომა: {error}',
  },
  'club_form.field_name': {
    'ru': 'Название клуба',
    'en': 'Club name',
    'ka': 'კლუბის სახელი',
  },
  'club_form.field_description': {
    'ru': 'Описание',
    'en': 'Description',
    'ka': 'აღწერა',
  },
  'club_form.field_country': {
    'ru': 'Страна',
    'en': 'Country',
    'ka': 'ქვეყანა',
  },
  'club_form.field_city': {
    'ru': 'Город',
    'en': 'City',
    'ka': 'ქალაქი',
  },
  'club_form.field_tags': {
    'ru': 'Тематика через запятую (JDM, Drift, Stance)',
    'en': 'Topics, comma-separated (JDM, Drift, Stance)',
    'ka': 'თემატიკა მძიმით გამოყოფილი (JDM, Drift, Stance)',
  },
  'club_form.field_logo_url': {
    'ru': 'Ссылка на логотип (URL)',
    'en': 'Logo link (URL)',
    'ka': 'ლოგოს ბმული (URL)',
  },
  'club_form.field_cover_url': {
    'ru': 'Ссылка на обложку (URL)',
    'en': 'Cover link (URL)',
    'ka': 'გარეკანის ბმული (URL)',
  },
  'club_form.public_club_title': {
    'ru': 'Открытый клуб',
    'en': 'Public club',
    'ka': 'ღია კლუბი',
  },
  'club_form.public_club_subtitle': {
    'ru': 'Вступление сразу, без одобрения',
    'en': 'Join instantly, no approval needed',
    'ka': 'გაწევრიანება მაშინვე, დამტკიცების გარეშე',
  },
  'club_form.edit_title': {
    'ru': 'Изменить клуб',
    'en': 'Edit club',
    'ka': 'კლუბის რედაქტირება',
  },
  'club_form.create_title': {
    'ru': 'Создать клуб',
    'en': 'Create club',
    'ka': 'კლუბის შექმნა',
  },
};
