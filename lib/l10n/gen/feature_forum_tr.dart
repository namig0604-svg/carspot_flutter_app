/// Переводы для раздела "Форум": список категорий, темы категории, сама
/// тема с ответами, форма новой темы. Экраны: forum_categories_screen.dart,
/// forum_topics_screen.dart, forum_topic_screen.dart, forum_create_topic_screen.dart.
///
/// Подключается централизованно в lib/l10n/app_translations.dart — этот файл
/// не редактировать вручную для wiring, только для добавления/правки строк.
const Map<String, Map<String, String>> kFeatureForumTranslations = {
  'home.menu_forum': {'ru': 'Форум', 'en': 'Forum', 'ka': 'ფორუმი'},
  'chats_list.forum_tooltip': {'ru': 'Форум', 'en': 'Forum', 'ka': 'ფორუმი'},

  'forum.categories_title': {'ru': 'Форум', 'en': 'Forum', 'ka': 'ფორუმი'},
  'forum.categories_hint': {
    'ru': 'Обсуждения по темам — выберите раздел',
    'en': 'Discussions by topic — pick a section',
    'ka': 'განხილვები თემების მიხედვით — აირჩიეთ განყოფილება',
  },
  'forum.topics_word': {'ru': 'темы', 'en': 'topics', 'ka': 'თემა'},
  'forum.error_message': {'ru': 'Ошибка: {error}', 'en': 'Error: {error}', 'ka': 'შეცდომა: {error}'},

  'forum.category_events_title': {'ru': 'Встречи и события', 'en': 'Meets & Events', 'ka': 'შეხვედრები და ღონისძიებები'},
  'forum.category_events_desc': {
    'ru': 'Встречи, трек-дни, круизы и события сообщества',
    'en': 'Meetups, track days, cruises and community events',
    'ka': 'შეხვედრები, ტრეკ-დღეები, კრუიზები და საზოგადოების ღონისძიებები',
  },
  'forum.category_tuning_title': {'ru': 'Тюнинг и запчасти', 'en': 'Tuning & Parts', 'ka': 'ტიუნინგი და ნაწილები'},
  'forum.category_tuning_desc': {
    'ru': 'Улучшения, моды, обзоры и проекты',
    'en': 'Upgrades, mods, reviews and builds',
    'ka': 'გაუმჯობესებები, მოდიფიკაციები, მიმოხილვები და პროექტები',
  },
  'forum.category_questions_title': {'ru': 'Вопросы и помощь', 'en': 'Questions & Help', 'ka': 'კითხვები და დახმარება'},
  'forum.category_questions_desc': {
    'ru': 'Задавайте вопросы, получайте советы и делитесь опытом',
    'en': 'Ask questions, get advice and share experience',
    'ka': 'დასვით კითხვები, მიიღეთ რჩევები და გაუზიარეთ გამოცდილება',
  },
  'forum.category_market_title': {'ru': 'Купить / Продать', 'en': 'Buy / Sell', 'ka': 'ყიდვა / გაყიდვა'},
  'forum.category_market_desc': {
    'ru': 'Покупайте и продавайте автомобили и запчасти',
    'en': 'Buy and sell cars and parts',
    'ka': 'იყიდეთ და გაყიდეთ მანქანები და ნაწილები',
  },

  'forum.all_countries': {'ru': 'Все страны', 'en': 'All countries', 'ka': 'ყველა ქვეყანა'},
  'forum.search_topics_hint': {'ru': 'Поиск тем…', 'en': 'Search topics…', 'ka': 'თემების ძებნა…'},
  'forum.no_topics': {
    'ru': 'В этой категории пока нет тем — станьте первым',
    'en': 'No topics in this category yet — be the first',
    'ka': 'ამ კატეგორიაში ჯერ არ არის თემები — იყავით პირველი',
  },
  'forum.new_topic_button': {'ru': 'Новая тема', 'en': 'New topic', 'ka': 'ახალი თემა'},
  'forum.new_topic_title': {'ru': 'Новая тема', 'en': 'New topic', 'ka': 'ახალი თემა'},
  'forum.country_optional_label': {'ru': 'Страна (необязательно)', 'en': 'Country (optional)', 'ka': 'ქვეყანა (არასავალდებულო)'},
  'forum.title_label': {'ru': 'Заголовок темы', 'en': 'Topic title', 'ka': 'თემის სათაური'},
  'forum.body_label': {'ru': 'Текст сообщения', 'en': 'Message text', 'ka': 'შეტყობინების ტექსტი'},
  'forum.publish_button': {'ru': 'Опубликовать', 'en': 'Publish', 'ka': 'გამოქვეყნება'},
  'forum.title_too_short': {'ru': 'Заголовок слишком короткий', 'en': 'Title is too short', 'ka': 'სათაური ძალიან მოკლეა'},
  'forum.body_empty': {'ru': 'Введите текст сообщения', 'en': 'Enter the message text', 'ka': 'შეიყვანეთ შეტყობინების ტექსტი'},

  'forum.no_replies_title': {'ru': 'Ответов пока нет', 'en': 'No replies yet', 'ka': 'პასუხები ჯერ არ არის'},
  'forum.no_replies_subtitle': {
    'ru': 'Будьте первым, кто ответит в этой теме',
    'en': 'Be the first to reply in this topic',
    'ka': 'იყავით პირველი, ვინც უპასუხებს ამ თემაში',
  },
  'forum.reply_hint': {'ru': 'Ответить в теме', 'en': 'Reply in topic', 'ka': 'უპასუხეთ თემაში'},
};
