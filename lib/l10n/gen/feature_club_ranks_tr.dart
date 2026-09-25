/// Переводы для расширенной системы ролей в клубах (модератор, смена
/// роли, кастомные звания участников) — club_detail_screen.dart.
///
/// Подключается централизованно в lib/l10n/app_translations.dart — этот файл
/// не редактировать вручную для wiring, только для добавления/правки строк.
const Map<String, Map<String, String>> kFeatureClubRanksTranslations = {
  'club_detail.moderator': {
    'ru': 'Модератор',
    'en': 'Moderator',
    'ka': 'მოდერატორი',
  },
  'club_detail.member_role_label': {
    'ru': 'Участник',
    'en': 'Member',
    'ka': 'წევრი',
  },
  'club_detail.change_role_action': {
    'ru': 'Изменить роль',
    'en': 'Change role',
    'ka': 'როლის შეცვლა',
  },
  'club_detail.set_title_action': {
    'ru': 'Задать звание',
    'en': 'Set title',
    'ka': 'წოდების მინიჭება',
  },
  'club_detail.role_picker_title': {
    'ru': 'Роль для {username}',
    'en': 'Role for {username}',
    'ka': 'როლი {username}-სთვის',
  },
  'club_detail.role_updated': {
    'ru': 'Роль обновлена',
    'en': 'Role updated',
    'ka': 'როლი განახლდა',
  },
  'club_detail.title_dialog_title': {
    'ru': 'Звание для {username}',
    'en': 'Title for {username}',
    'ka': 'წოდება {username}-სთვის',
  },
  'club_detail.title_label': {
    'ru': 'Например: Ветеран',
    'en': 'E.g.: Veteran',
    'ka': 'მაგ: ვეტერანი',
  },
  'club_detail.title_updated': {
    'ru': 'Звание обновлено',
    'en': 'Title updated',
    'ka': 'წოდება განახლდა',
  },
};
