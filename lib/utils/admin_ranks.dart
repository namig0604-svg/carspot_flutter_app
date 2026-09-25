/// Иерархия рангов администрации CarSpot — зеркалит app/ranks.py на бэкенде.
/// Порядок по возрастанию прав: модератор < администратор < тех.администратор < разработчик.
const List<String> kAdminRanks = ['moderator', 'administrator', 'tech_admin', 'developer'];

const Map<String, String> kAdminRankTitles = {
  'moderator': 'Модератор',
  'administrator': 'Администратор',
  'tech_admin': 'Тех.администратор',
  'developer': 'Разработчик',
};

const Map<String, int> kAdminRankLevel = {
  'moderator': 1,
  'administrator': 2,
  'tech_admin': 3,
  'developer': 4,
};

int adminRankLevel(String? rank) => rank == null ? 0 : (kAdminRankLevel[rank] ?? 0);

String adminRankTitle(String? rank) => rank == null ? 'Нет ранга' : (kAdminRankTitles[rank] ?? rank);

const int kTechAdminLevel = 3;
const int kDeveloperLevel = 4;
