/// Переводы для новых Premium-фич: ИИ-диагностика по симптомам
/// (ai_diagnosis_screen.dart, бэкенд app/api/ai_diagnosis.py) и PDF-отчёт об
/// авто (car_report_screen.dart). Плюс два пункта меню профиля.
///
/// Подключается централизованно в lib/l10n/app_translations.dart — этот файл
/// не редактировать вручную для wiring, только для добавления/правки строк.
const Map<String, Map<String, String>> kFeaturePremiumAiReportTranslations = {
  'home.menu_ai_diagnosis': {
    'ru': 'ИИ-диагностика',
    'en': 'AI diagnostics',
    'ka': 'AI დიაგნოსტიკა',
  },
  'home.menu_car_report': {
    'ru': 'PDF-отчёт',
    'en': 'PDF report',
    'ka': 'PDF ანგარიში',
  },
  'ai_diagnosis.title': {
    'ru': 'ИИ-диагностика',
    'en': 'AI diagnostics',
    'ka': 'AI დიაგნოსტიკა',
  },
  'ai_diagnosis.disclaimer': {
    'ru': 'Предварительное предположение по описанию, не диагноз. Точную причину определит осмотр в сервисе.',
    'en': 'A preliminary guess based on your description, not a diagnosis. Only an in-person inspection can confirm the cause.',
    'ka': 'წინასწარი ვარაუდი აღწერის მიხედვით, არა დიაგნოზი. ზუსტ მიზეზს დაადგენს მხოლოდ სერვისში დათვალიერება.',
  },
  'ai_diagnosis.empty_hint': {
    'ru': 'Опиши, что не так с машиной — например: "стук спереди при повороте руля"',
    'en': 'Describe what\'s wrong with your car — e.g. "clunking sound up front when turning the wheel"',
    'ka': 'აღწერე რა არასწორია მანქანაში — მაგ.: "წინიდან ხმაური საჭის შემობრუნებისას"',
  },
  'ai_diagnosis.input_hint': {
    'ru': 'Опишите симптом...',
    'en': 'Describe the symptom...',
    'ka': 'აღწერეთ სიმპტომი...',
  },
  'ai_diagnosis.open_businesses_cta': {
    'ru': 'Найти: {category}',
    'en': 'Find: {category}',
    'ka': 'ძებნა: {category}',
  },
  'car_report.title': {
    'ru': 'PDF-отчёт об авто',
    'en': 'Car PDF report',
    'ka': 'მანქანის PDF ანგარიში',
  },
  'car_report.hint': {
    'ru': 'Соберём сервисный журнал, расходы, документы и топливную статистику машины в один PDF-файл — удобно приложить к объявлению о продаже.',
    'en': 'We\'ll gather the maintenance log, expenses, documents and fuel stats into one PDF file — handy to attach to a sale listing.',
    'ka': 'შევკრებთ სერვისის ჟურნალს, ხარჯებს, დოკუმენტებს და საწვავის სტატისტიკას ერთ PDF ფაილში.',
  },
  'car_report.count_maintenance': {
    'ru': '{n} записей в сервисном журнале',
    'en': '{n} maintenance log entries',
    'ka': '{n} ჩანაწერი სერვისის ჟურნალში',
  },
  'car_report.count_expenses': {
    'ru': '{n} расходов на сумму {sum} ₽',
    'en': '{n} expenses totaling {sum}',
    'ka': '{n} ხარჯი, ჯამში {sum}',
  },
  'car_report.count_documents': {
    'ru': '{n} документов',
    'en': '{n} documents',
    'ka': '{n} დოკუმენტი',
  },
  'car_report.count_fuel': {
    'ru': '{n} заправок',
    'en': '{n} fuel entries',
    'ka': '{n} გასამართი',
  },
  'car_report.generate_button': {
    'ru': 'Сформировать и поделиться PDF',
    'en': 'Generate and share PDF',
    'ka': 'PDF-ის შექმნა და გაზიარება',
  },
};
