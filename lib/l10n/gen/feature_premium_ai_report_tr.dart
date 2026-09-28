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
  'premium.compare_ai_diagnosis': {
    'ru': 'ИИ-диагностика по симптомам',
    'en': 'AI symptom diagnostics',
    'ka': 'AI დიაგნოსტიკა სიმპტომებით',
  },
  'premium.compare_car_report': {
    'ru': 'PDF-отчёт об авто',
    'en': 'Car PDF report',
    'ka': 'მანქანის PDF ანგარიში',
  },
  'premium.perk_ai_diagnosis_title': {
    'ru': 'ИИ-диагностика',
    'en': 'AI diagnostics',
    'ka': 'AI დიაგნოსტიკა',
  },
  'premium.perk_ai_diagnosis_subtitle': {
    'ru': 'Опиши симптом — ИИ подскажет вероятную причину и нужный тип сервиса',
    'en': 'Describe a symptom — AI suggests a likely cause and which service to visit',
    'ka': 'აღწერე სიმპტომი — AI შემოგთავაზებს სავარაუდო მიზეზს',
  },
  'premium.perk_car_report_title': {
    'ru': 'PDF-отчёт об авто',
    'en': 'Car PDF report',
    'ka': 'მანქანის PDF ანგარიში',
  },
  'premium.perk_car_report_subtitle': {
    'ru': 'Сервисный журнал, расходы, документы и топливо машины — в одном PDF',
    'en': 'Maintenance log, expenses, documents and fuel stats in one PDF',
    'ka': 'სერვისის ჟურნალი, ხარჯები და დოკუმენტები ერთ PDF-ში',
  },
  'home.menu_maintenance_forecast': {
    'ru': 'Прогноз ТО',
    'en': 'Maintenance forecast',
    'ka': 'ტექმომსახურების პროგნოზი',
  },
  'maintenance_forecast.title': {
    'ru': 'Прогноз следующего ТО',
    'en': 'Next maintenance forecast',
    'ka': 'შემდეგი ტექმომსახურების პროგნოზი',
  },
  'maintenance_forecast.hint': {
    'ru': 'По истории «Сервисного дневника» посчитаем, когда примерно понадобится следующая замена масла, шин, фильтров и т.д. — и напомним заранее.',
    'en': 'Based on your maintenance log history, we estimate when the next oil change, tires, filters and so on will likely be due — and remind you ahead of time.',
    'ka': '«სერვისის ჟურნალის» ისტორიის მიხედვით გამოვთვლით, როდის დაგჭირდებათ შემდეგი ტექმომსახურება.',
  },
  'maintenance_forecast.empty': {
    'ru': 'Пока недостаточно данных для прогноза — добавьте больше записей в сервисный дневник (минимум 2 записи одного типа или укажите дату/пробег следующего ТО вручную).',
    'en': 'Not enough data yet for a forecast — add more entries to the maintenance log (at least 2 of the same type, or set a manual next-due date/mileage).',
    'ka': 'პროგნოზისთვის ჯერ არასაკმარისია მონაცემები — დაამატეთ ჩანაწერები სერვისის ჟურნალში.',
  },
  'maintenance_forecast.current_mileage': {
    'ru': 'Текущий пробег: {km} км',
    'en': 'Current mileage: {km} km',
    'ka': 'მიმდინარე გარბენი: {km} კმ',
  },
  'maintenance_forecast.source_manual': {
    'ru': 'по вашей дате/пробегу',
    'en': 'from your set date/mileage',
    'ka': 'თქვენი მითითებული თარიღით/გარბენით',
  },
  'maintenance_forecast.source_estimated': {
    'ru': 'оценка по истории записей',
    'en': 'estimated from your history',
    'ka': 'შეფასებულია ისტორიის მიხედვით',
  },
  'maintenance_forecast.urgency_overdue': {
    'ru': 'Просрочено',
    'en': 'Overdue',
    'ka': 'ვადაგადაცილებული',
  },
  'maintenance_forecast.urgency_soon': {
    'ru': 'Скоро',
    'en': 'Soon',
    'ka': 'მალე',
  },
  'maintenance_forecast.urgency_ok': {
    'ru': 'В порядке',
    'en': 'OK',
    'ka': 'წესრიგშია',
  },
  'maintenance_forecast.predicted_date': {
    'ru': 'Ориентировочно: {date}',
    'en': 'Estimated: {date}',
    'ka': 'სავარაუდოდ: {date}',
  },
  'maintenance_forecast.predicted_mileage': {
    'ru': 'Ориентировочно на {km} км',
    'en': 'Estimated at {km} km',
    'ka': 'სავარაუდოდ {km} კმ-ზე',
  },
  'premium.compare_maintenance_forecast': {
    'ru': 'Прогноз следующего ТО',
    'en': 'Next maintenance forecast',
    'ka': 'შემდეგი ტექმომსახურების პროგნოზი',
  },
  'premium.perk_maintenance_forecast_title': {
    'ru': 'Прогноз ТО',
    'en': 'Maintenance forecast',
    'ka': 'ტექმომსახურების პროგნოზი',
  },
  'premium.perk_maintenance_forecast_subtitle': {
    'ru': 'Считаем по истории сервисного дневника, когда понадобится следующее ТО',
    'en': 'We estimate your next service date from your maintenance log history',
    'ka': 'გამოვთვლით შემდეგ ტექმომსახურებას სერვისის ჟურნალის მიხედვით',
  },
};
