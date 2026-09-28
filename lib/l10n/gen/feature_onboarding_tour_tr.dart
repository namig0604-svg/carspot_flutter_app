/// Интерактивный тур по приложению (lib/widgets/onboarding_tour.dart) и
/// плитка "Тур по приложению" в профиле, которая запускает его повторно.
/// Только ru/en/ka — остальные языки (az/hy/kk/uk) откатываются на русский.
/// Подключается централизованно в lib/l10n/app_translations.dart.
const Map<String, Map<String, String>> kFeatureOnboardingTourTranslations = {
  'onboarding_tour.skip': {'ru': 'Пропустить', 'en': 'Skip', 'ka': 'გამოტოვება'},
  'onboarding_tour.next': {'ru': 'Далее', 'en': 'Next', 'ka': 'შემდეგი'},
  'onboarding_tour.done': {'ru': 'Понятно', 'en': 'Got it', 'ka': 'გასაგებია'},
  'home.menu_tour': {'ru': 'Тур по приложению', 'en': 'App tour', 'ka': 'აპის ტური'},
  'onboarding_tour.step_welcome_title': {
    'ru': 'Добро пожаловать в CarSpot!',
    'en': 'Welcome to CarSpot!',
    'ka': 'კეთილი იყოს თქვენი მობრძანება CarSpot-ში!',
  },
  'onboarding_tour.step_welcome_body': {
    'ru': 'Покажем за полминуты, где что находится. Это можно пропустить в любой момент, а позже — пройти заново из профиля.',
    'en': "We'll show you where everything is in half a minute. You can skip this at any time, and go through it again later from your profile.",
    'ka': 'ნახევარ წუთში გაჩვენებთ, სად რა არის. ეს ნებისმიერ დროს შეგიძლიათ გამოტოვოთ, მოგვიანებით კი პროფილიდან ხელახლა გაიაროთ.',
  },
  'onboarding_tour.step_feed_title': {'ru': 'Лента сходок', 'en': 'Meetup feed', 'ka': 'შეხვედრების ლენტა'},
  'onboarding_tour.step_feed_body': {
    'ru': 'Здесь список автомобильных сходок рядом с вами — с поиском, сортировкой и категориями сверху.',
    'en': 'Here is the list of car meetups near you — with search, sorting and categories at the top.',
    'ka': 'აქ არის საავტომობილო შეხვედრების სია თქვენს მახლობლად — ძებნით, სორტირებითა და კატეგორიებით ზემოთ.',
  },
  'onboarding_tour.step_map_title': {'ru': 'Карта', 'en': 'Map', 'ka': 'რუკა'},
  'onboarding_tour.step_map_body': {
    'ru': 'Все сходки на карте — удобно, чтобы увидеть, что происходит поблизости прямо сейчас.',
    'en': "All meetups on the map — handy to see what's happening nearby right now.",
    'ka': 'ყველა შეხვედრა რუკაზე — მოსახერხებელია, რომ ნახოთ, რა ხდება ახლოს ახლა.',
  },
  'onboarding_tour.step_add_title': {'ru': 'Добавить', 'en': 'Add', 'ka': 'დამატება'},
  'onboarding_tour.step_add_body': {
    'ru': 'Создайте свою сходку или добавьте автосервис в каталог — одной кнопкой.',
    'en': 'Create your own meetup or add a car service to the catalog — with one button.',
    'ka': 'შექმენით საკუთარი შეხვედრა ან დაამატეთ ავტოსერვისი კატალოგში — ერთი ღილაკით.',
  },
  'onboarding_tour.step_chats_title': {'ru': 'Чаты', 'en': 'Chats', 'ka': 'ჩატები'},
  'onboarding_tour.step_chats_body': {
    'ru': 'Личные переписки, а также чаты сходок и клубов, в которых вы участвуете.',
    'en': "Personal conversations, as well as chats for the meetups and clubs you're part of.",
    'ka': 'პირადი მიმოწერები, ასევე იმ შეხვედრებისა და კლუბების ჩატები, რომლებშიც მონაწილეობთ.',
  },
  'onboarding_tour.step_profile_title': {'ru': 'Профиль', 'en': 'Profile', 'ka': 'პროფილი'},
  'onboarding_tour.step_profile_body': {
    'ru': 'Гараж, клубы, достижения, сезонные челленджи, настройки и справка — всё остальное найдётся здесь.',
    'en': 'Garage, clubs, achievements, seasonal challenges, settings and help — everything else is here.',
    'ka': 'გარაჟი, კლუბები, მიღწევები, სეზონური გამოწვევები, პარამეტრები და დახმარება — ყველაფერი დანარჩენი აქ არის.',
  },
  'onboarding_tour.step_notifications_title': {'ru': 'Уведомления', 'en': 'Notifications', 'ka': 'შეტყობინებები'},
  'onboarding_tour.step_notifications_body': {
    'ru': 'Здесь — новые лайки, комментарии, приглашения в друзья и другие уведомления.',
    'en': 'Here are new likes, comments, friend invitations and other notifications.',
    'ka': 'აქ არის ახალი მოწონებები, კომენტარები, მეგობრობის მოწვევები და სხვა შეტყობინებები.',
  },
  'onboarding_tour.step_final_title': {'ru': 'Готово!', 'en': "You're all set!", 'ka': 'მზადაა!'},
  'onboarding_tour.step_final_body': {
    'ru': 'Если что-то забудете — в Профиль → «Помощь» есть подробный гид по всем разделам и частые вопросы. Хорошей дороги!',
    'en': 'If you forget something — Profile → “Help” has a detailed guide to every section and frequent questions. Have a good drive!',
    'ka': 'თუ რამე დაგავიწყდებათ — პროფილი → „დახმარება“-ში არის დეტალური გზამკვლევი ყველა განყოფილებაზე და ხშირი კითხვები. კარგი გზა!',
  },
};
