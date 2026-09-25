import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/section_background.dart';
import 'app_guide_screen.dart';

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}

class _FaqSection {
  final String title;
  final IconData icon;
  final List<_FaqItem> items;
  const _FaqSection(this.title, this.icon, this.items);
}

const List<_FaqSection> _faqSections = [
  _FaqSection('Аккаунт и профиль', Icons.person_outline, [
    _FaqItem(
      'Как изменить данные профиля?',
      'На вкладке «Профиль» нажмите «Редактировать профиль» под именем — там можно поменять фото, имя, город и другие данные.',
    ),
    _FaqItem(
      'Что такое уровень и опыт (XP)?',
      'За активность в приложении (посещение сходок, создание сходок, добавление машин в гараж, отзывы, рейтинг, друзья) начисляется опыт. По мере накопления опыта растёт уровень — прогресс виден на вкладке «Профиль».',
    ),
    _FaqItem(
      'Где посмотреть достижения?',
      'Профиль → раздел «Моя активность» → плитка «Достижения». Там же указано, что нужно сделать, чтобы получить очередное достижение.',
    ),
    _FaqItem(
      'Забыл пароль — что делать?',
      'На экране входа нажмите «Забыли пароль?» и следуйте инструкции.',
    ),
  ]),
  _FaqSection('Сходки и карта', Icons.calendar_today_outlined, [
    _FaqItem(
      'Как создать сходку?',
      'Нажмите на кнопку «+» в нижней навигации и выберите «Новая сходка». Укажите название, тип, страну/город, место на карте, дату, время и продолжительность.',
    ),
    _FaqItem(
      'Как найти сходки рядом?',
      'На вкладке «Сходки» есть фильтры «Ближайшие» (по геолокации), «Популярные» и «Новые», а также категории (Тусовка, Гонки, Дрифт и т.д.). Все сходки на карте видно на вкладке «Карта».',
    ),
    _FaqItem(
      'Как присоединиться или покинуть сходку?',
      'Откройте сходку и нажмите «Участвовать». Чтобы отменить участие — кнопка «Покинуть сходку» внизу того же экрана.',
    ),
    _FaqItem(
      'Что такое Карпулинг?',
      'На экране деталей сходки, если вы в ней участвуете, появляется иконка машинки в шапке — это Карпулинг: там можно предложить свободные места в своей машине по пути на сходку или забронировать место у другого участника.',
    ),
    _FaqItem(
      'Можно ли добавить сходку в избранное?',
      'Да, иконка сердечка в шапке экрана сходки. Все избранные сходки собраны в Профиль → «Моя активность» → «Избранное».',
    ),
  ]),
  _FaqSection('Моё авто', Icons.directions_car_outlined, [
    _FaqItem(
      'Как добавить машину в гараж?',
      'Профиль → «Моё авто» → «Гараж» → кнопка добавления. Укажите марку, модель, год и фото — машина появится в вашем профиле и в чате/на сходках рядом с именем.',
    ),
    _FaqItem(
      'Для чего «Парковка»?',
      'Чтобы не забыть, где оставили машину. Нажмите «Я здесь припарковался» — приложение запомнит точку на карте, можно добавить заметку (например, этаж или сектор).',
    ),
    _FaqItem(
      'Что такое «Сервисный дневник»?',
      'Журнал ТО и ремонтов по каждой машине из гаража — записывайте, что и когда делали, чтобы не потерять историю обслуживания.',
    ),
    _FaqItem(
      'Зачем раздел «Документы»?',
      'Хранит фото документов на машину (СТС, страховка и т.д.) со сроком действия — удобно, чтобы не искать бумаги и не пропустить продление.',
    ),
    _FaqItem(
      'Что считает «Расходы»?',
      'Все траты на конкретную машину (топливо, ремонт, мойка и т.д.), которые вы вносите вручную — экран показывает сумму трат по машине.',
    ),
    _FaqItem(
      'Как работает «Проверка VIN»?',
      'Это офлайн-расшифровка VIN-номера: страна производства, вероятный бренд и корректность формата. Полную историю (пробег, ДТП, залоги) так проверить нельзя — нужен платный сервис вроде Автотеки или Автокода.',
    ),
  ]),
  _FaqSection('Сообщество', Icons.groups_outlined, [
    _FaqItem(
      'Чем «Клубы» отличаются от «Друзей»?',
      '«Друзья» — это личные связи с другими пользователями. «Клубы» — это группы по интересам (марка, город, стиль вождения) со своими сходками, чатом и участниками.',
    ),
    _FaqItem(
      'Как создать клуб?',
      'Профиль → «Сообщество» → «Клубы» → кнопка создания. Вы автоматически станете владельцем клуба.',
    ),
    _FaqItem(
      'Что такое «Форум»?',
      'Раздел с обсуждениями по темам (не привязан к конкретной сходке или клубу) — можно создавать темы и отвечать в них.',
    ),
    _FaqItem(
      'Как продать или найти запчасти?',
      'Профиль → «Сообщество» → «Барахолка». Можно выставить своё объявление (фото, цена, категория, марка/модель авто) или найти нужную запчасть через поиск и фильтр по категориям.',
    ),
    _FaqItem(
      'Что даёт таблица «Лидеры»?',
      'Рейтинг пользователей по опыту (XP) — можно увидеть, кто активнее всех в сообществе.',
    ),
  ]),
  _FaqSection('Безопасность и сервисы', Icons.shield_outlined, [
    _FaqItem(
      'Что делает кнопка SOS?',
      'Экран экстренной помощи: можно поделиться живой геопозицией с другом или соклубниками и сразу увидеть ближайшие эвакуаторы и шиномонтажи с телефонами для звонка.',
    ),
    _FaqItem(
      'Как отметить опасность на дороге?',
      'Профиль → «Безопасность и сервисы» → «Опасности на дороге» → долгое нажатие на нужном месте карты. Другие пользователи увидят отметку.',
    ),
    _FaqItem(
      'Чем «Сервисы» отличаются от «Моих точек»?',
      '«Сервисы» — каталог автосервисов, шиномонтажей и т.д. с отзывами и рейтингом. «Мои точки» — личные места, которые сохранили именно вы (например, любимая мойка).',
    ),
  ]),
  _FaqSection('Premium и приглашения', Icons.workspace_premium_outlined, [
    _FaqItem(
      'Что даёт CarSpot Premium?',
      'Больше машин в гараже, список тех, кто лайкнул и кто смотрел ваш профиль, и другие расширенные возможности. Новым пользователям доступен бесплатный пробный период на 14 дней (Настройки → CarSpot Premium).',
    ),
    _FaqItem(
      'Как получить Premium бесплатно?',
      'Через реферальную программу: пригласите друзей по своему коду — когда наберётся 10 приглашённых друзей, вы получаете месяц Premium бесплатно. Код и статистика приглашений — на экране Premium.',
    ),
  ]),
  _FaqSection('Настройки и технические вопросы', Icons.settings_outlined, [
    _FaqItem(
      'Как поменять язык приложения?',
      'Настройки → «Язык интерфейса» — доступны русский, английский и грузинский.',
    ),
    _FaqItem(
      'Как включить тёмную/светлую тему?',
      'Настройки → раздел «Оформление»: системная, светлая или тёмная тема.',
    ),
    _FaqItem(
      'Приложение разлогинило после перезагрузки страницы — это нормально?',
      'Нет, это была ошибка, её уже исправили: теперь вход сохраняется автоматически, и повторно логиниться после обновления страницы не нужно.',
    ),
    _FaqItem(
      'Не нашли ответ на свой вопрос?',
      'Напишите в поддержку через форум или задайте вопрос в чате клуба/сходки — сообщество и админы CarSpot всегда помогают.',
    ),
  ]),
];

class FaqScreen extends StatelessWidget {
  const FaqScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Помощь', overflow: TextOverflow.ellipsis, maxLines: 1),
        elevation: 0,
        backgroundColor: AppColors.black,
      ),
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.blue, glowAlignment: Alignment.topRight, imageAsset: 'assets/backgrounds/settings.jpg'),
          Theme(
            data: AppTheme.dark,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: AppColors.blue.withOpacity(0.14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined, color: AppColors.blue),
                    title: const Text('Как пользоваться CarSpot', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Короткий гид по всем разделам приложения'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppGuideScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Частые вопросы',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                for (final section in _faqSections) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: Icon(section.icon, color: AppColors.blue),
                        title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        children: [
                          for (final item in section.items)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(item.answer, style: const TextStyle(fontSize: 13, color: AppColors.textMutedDark, height: 1.4)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
