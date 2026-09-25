import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/section_background.dart';

class _GuideItem {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _GuideItem(this.icon, this.color, this.title, this.description);
}

class _GuideSection {
  final String title;
  final List<_GuideItem> items;
  const _GuideSection(this.title, this.items);
}

const List<_GuideSection> _guideSections = [
  _GuideSection('Основная навигация', [
    _GuideItem(Icons.calendar_today, AppColors.blue, 'Сходки',
        'Главная лента: список автомобильных встреч рядом с вами. Фильтры «Ближайшие / Популярные / Новые» и категории (Тусовка, Гонки, Дрифт, Драг, Офф-роуд и т.д.) сверху.'),
    _GuideItem(Icons.map, AppColors.blue, 'Карта',
        'Все сходки на карте — удобно, если планируете маршрут или хотите увидеть, что происходит поблизости прямо сейчас.'),
    _GuideItem(Icons.add_circle, AppColors.red, 'Добавить',
        'Кнопка в центре нижней навигации: быстрое создание новой сходки или добавление автосервиса в каталог.'),
    _GuideItem(Icons.chat_bubble, Colors.deepOrange, 'Чаты',
        'Личные переписки, а также чаты сходок и клубов, в которых вы участвуете.'),
    _GuideItem(Icons.person, Colors.cyan, 'Профиль',
        'Ваша страница: уровень и опыт, статистика, и меню со всеми остальными разделами приложения — сгруппированы по темам ниже.'),
  ]),
  _GuideSection('Моё авто', [
    _GuideItem(Icons.directions_car, Colors.cyan, 'Гараж',
        'Добавляйте свои машины с фото — они появятся у вас в профиле и будут видны другим на сходках.'),
    _GuideItem(Icons.local_parking, Colors.indigo, 'Парковка',
        '«Я здесь припарковался» запоминает точку на карте, чтобы не забыть, где оставили машину.'),
    _GuideItem(Icons.build, Colors.brown, 'Сервисный дневник',
        'История ТО и ремонтов по каждой машине из гаража.'),
    _GuideItem(Icons.description, Colors.blueGrey, 'Документы',
        'Фото документов на машину (СТС, страховка) со сроком действия под рукой.'),
    _GuideItem(Icons.attach_money, Colors.green, 'Расходы',
        'Учёт трат на машину — топливо, ремонт, мойка и прочее.'),
    _GuideItem(Icons.qr_code_scanner, Colors.purple, 'Проверка VIN',
        'Быстрая офлайн-расшифровка VIN: страна производства и вероятный бренд по номеру.'),
  ]),
  _GuideSection('Сообщество', [
    _GuideItem(Icons.people, AppColors.blue, 'Друзья',
        'Добавляйте других пользователей в друзья, чтобы видеть их активность и было проще списаться.'),
    _GuideItem(Icons.groups, AppColors.blue, 'Клубы',
        'Сообщества по интересам со своими сходками и общим чатом — создавайте свой клуб или вступайте в существующий.'),
    _GuideItem(Icons.forum, Colors.deepOrange, 'Форум',
        'Обсуждения по темам, не привязанные к конкретной сходке.'),
    _GuideItem(Icons.storefront, Colors.deepPurple, 'Барахолка',
        'Площадка объявлений о продаже и поиске автозапчастей.'),
    _GuideItem(Icons.emoji_events, Colors.amber, 'Лидеры',
        'Рейтинг участников по опыту (XP) — соревнуйтесь за место в топе.'),
  ]),
  _GuideSection('Моя активность', [
    _GuideItem(Icons.event_available, Colors.tealAccent, 'Мои записи',
        'Список сходок, в которых вы записаны участвовать.'),
    _GuideItem(Icons.bookmark, AppColors.red, 'Избранное',
        'Сходки, которые вы отметили сердечком, чтобы не потерять.'),
    _GuideItem(Icons.military_tech, Colors.amber, 'Достижения',
        'Награды за активность в приложении — от первой сходки до статуса лидера клуба.'),
  ]),
  _GuideSection('Безопасность и сервисы', [
    _GuideItem(Icons.sos, Colors.red, 'SOS',
        'Экстренная помощь на дороге: поделиться геопозицией и найти ближайшие эвакуаторы/шиномонтажи.'),
    _GuideItem(Icons.warning_amber_rounded, Colors.orange, 'Опасности на дороге',
        'Отмечайте на карте ямы, засады, гололёд и другие опасности — долгим нажатием по месту.'),
    _GuideItem(Icons.car_repair, AppColors.red, 'Сервисы',
        'Каталог автосервисов с рейтингом и отзывами.'),
    _GuideItem(Icons.pin_drop, Colors.teal, 'Мои точки',
        'Личные сохранённые места — например, проверенная мойка или шиномонтаж.'),
  ]),
  _GuideSection('Прочее', [
    _GuideItem(Icons.settings, Colors.grey, 'Настройки',
        'Тема оформления, язык интерфейса, страна, уведомления и звуки. Быстрый доступ — иконка-шестерёнка в шапке вкладки «Профиль».'),
    _GuideItem(Icons.workspace_premium, Colors.amber, 'CarSpot Premium',
        'Расширенные возможности профиля и гаража. 14 дней бесплатно для новых пользователей, а дальше можно получить месяц бесплатно за 10 приглашённых друзей.'),
  ]),
];

class AppGuideScreen extends StatelessWidget {
  const AppGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Как пользоваться CarSpot', overflow: TextOverflow.ellipsis, maxLines: 1),
        elevation: 0,
        backgroundColor: AppColors.black,
      ),
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const SectionBackground(accent: AppColors.red, glowAlignment: Alignment.topLeft, imageAsset: 'assets/backgrounds/events.jpg'),
          Theme(
            data: AppTheme.dark,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDarkAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.steel),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Что такое CarSpot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      SizedBox(height: 8),
                      Text(
                        'CarSpot — приложение для автомобильного сообщества: находите и создавайте сходки, '
                        'общайтесь в клубах и на форуме, ведите свой гараж и историю обслуживания машины, '
                        'получайте помощь на дороге и находите нужные автосервисы и запчасти — всё в одном месте.',
                        style: TextStyle(fontSize: 14, color: AppColors.textMutedDark, height: 1.5),
                      ),
                    ],
                  ),
                ),
                for (final section in _guideSections) ...[
                  const SizedBox(height: 22),
                  Text(section.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  for (final item in section.items)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDarkAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.steel),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: item.color.withOpacity(0.18), borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                            child: Icon(item.icon, color: item.color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                const SizedBox(height: 3),
                                Text(item.description, style: const TextStyle(fontSize: 12.5, color: AppColors.textMutedDark, height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
