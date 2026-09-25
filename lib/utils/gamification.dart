/// Геймификация: уровень/опыт и достижения считаются на основе уже
/// существующей статистики пользователя (машины, сходки, клубы, отзывы,
/// рефералы, верификация, премиум, возраст аккаунта) — без отдельных полей
/// в базе, поэтому не может "разъехаться" с реальными данными.
library gamification;

const int xpPerLevel = 150;

const List<String> _levelTitles = [
  'Новичок',
  'Новичок',
  'Любитель',
  'Любитель',
  'Любитель',
  'Знаток',
  'Знаток',
  'Знаток',
  'Знаток',
  'Профи',
  'Профи',
  'Профи',
  'Профи',
  'Профи',
  'Мастер',
  'Мастер',
  'Мастер',
  'Мастер',
  'Мастер',
];

const String _maxLevelTitle = 'Легенда трассы';

class GamificationStats {
  final int xp;
  final int level;
  final String levelTitle;
  final int xpIntoLevel;
  final int xpForNextLevel;
  final double progress; // 0..1

  GamificationStats({
    required this.xp,
    required this.level,
    required this.levelTitle,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    required this.progress,
  });
}

class Achievement {
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;
  // Прогресс к разблокировке — не влияет на старые места использования
  // (значения по умолчанию), но позволяет новому экрану «Достижения»
  // показывать «7/10» вместо просто серой иконки.
  final int currentValue;
  final int targetValue;

  const Achievement({
    required this.emoji,
    required this.title,
    required this.description,
    required this.unlocked,
    this.currentValue = 0,
    this.targetValue = 1,
  });

  double get progress {
    if (unlocked) return 1.0;
    if (targetValue <= 0) return 0.0;
    final v = currentValue / targetValue;
    if (v < 0) return 0.0;
    if (v > 1) return 1.0;
    return v;
  }

  int get clampedCurrent {
    if (currentValue < 0) return 0;
    if (currentValue > targetValue) return targetValue;
    return currentValue;
  }
}

/// Начисление XP:
/// - 20 XP за каждую посещённую сходку
/// - 40 XP за каждую созданную сходку (организатор вкладывается больше)
/// - 10 XP за каждую машину в гараже
/// - 5 XP за каждый полученный отзыв (кто-то оценил тебя после сходки)
/// - 15 XP за каждый клуб, в котором состоишь
/// - 50 XP за каждого приглашённого по реферальному коду друга
/// - +30 XP бонус за хороший рейтинг (4.5+ от 5+ человек)
/// - +50 XP бонус за отличный рейтинг (5.0 от 10+ человек)
/// - +50 XP за верификацию аккаунта, +100 XP за премиум
int computeXp({
  required int eventsAttended,
  required int eventsCreated,
  required int carsCount,
  required int ratingsCount,
  required double averageRating,
  required int clubsCount,
  required int referralsCount,
  int likesCount = 0,
  bool isVerified = false,
  bool isPremium = false,
  // Бонусный XP, купленный за монеты CarSpot Coins (поле `xp` в ответе
  // API у пользователя) — прибавляется поверх честно посчитанной статистики,
  // а не подменяет её, поэтому уровень не может "разъехаться": без покупок
  // bonusXp = 0 и ничего не меняется.
  int bonusXp = 0,
}) {
  int xp = eventsAttended * 20 +
      eventsCreated * 40 +
      carsCount * 10 +
      ratingsCount * 5 +
      clubsCount * 15 +
      referralsCount * 50 +
      likesCount * 2;
  if (averageRating >= 4.5 && ratingsCount >= 5) xp += 30;
  if (averageRating >= 5.0 && ratingsCount >= 10) xp += 50;
  if (isVerified) xp += 50;
  if (isPremium) xp += 100;
  return xp + bonusXp;
}

GamificationStats computeStats(int xp) {
  final level = (xp / xpPerLevel).floor() + 1;
  final xpIntoLevel = xp % xpPerLevel;
  final title = level - 1 < _levelTitles.length ? _levelTitles[level - 1] : _maxLevelTitle;
  return GamificationStats(
    xp: xp,
    level: level,
    levelTitle: title,
    xpIntoLevel: xpIntoLevel,
    xpForNextLevel: xpPerLevel,
    progress: xpIntoLevel / xpPerLevel,
  );
}

List<Achievement> buildAchievements({
  required int eventsAttended,
  required int eventsCreated,
  required int carsCount,
  required int ratingsCount,
  required double averageRating,
  required int clubsCount,
  required bool isClubLeader,
  required int referralsCount,
  int likesCount = 0,
  bool isVerified = false,
  bool isPremium = false,
  int accountAgeDays = 0,
}) {
  return [
    Achievement(
      emoji: '🚗',
      title: 'Первая тачка',
      description: 'Добавь машину в гараж',
      unlocked: carsCount >= 1,
      currentValue: carsCount,
      targetValue: 1,
    ),
    Achievement(
      emoji: '🛠',
      title: 'Гараж мечты',
      description: '3 машины в гараже',
      unlocked: carsCount >= 3,
      currentValue: carsCount,
      targetValue: 3,
    ),
    Achievement(
      emoji: '🏆',
      title: 'Автопарк',
      description: '5 машин в гараже',
      unlocked: carsCount >= 5,
      currentValue: carsCount,
      targetValue: 5,
    ),
    Achievement(
      emoji: '🚙',
      title: 'Дилер',
      description: '10 машин в гараже',
      unlocked: carsCount >= 10,
      currentValue: carsCount,
      targetValue: 10,
    ),
    Achievement(
      emoji: '🏁',
      title: 'Первая сходка',
      description: 'Посети первую сходку',
      unlocked: eventsAttended >= 1,
      currentValue: eventsAttended,
      targetValue: 1,
    ),
    Achievement(
      emoji: '🚦',
      title: 'Вошёл во вкус',
      description: '3 посещённых сходки',
      unlocked: eventsAttended >= 3,
      currentValue: eventsAttended,
      targetValue: 3,
    ),
    Achievement(
      emoji: '🔥',
      title: 'Завсегдатай',
      description: '10 посещённых сходок',
      unlocked: eventsAttended >= 10,
      currentValue: eventsAttended,
      targetValue: 10,
    ),
    Achievement(
      emoji: '🏆',
      title: 'Марафонец',
      description: '50 посещённых сходок',
      unlocked: eventsAttended >= 50,
      currentValue: eventsAttended,
      targetValue: 50,
    ),
    Achievement(
      emoji: '🌟',
      title: 'Легенда трасс',
      description: '100 посещённых сходок',
      unlocked: eventsAttended >= 100,
      currentValue: eventsAttended,
      targetValue: 100,
    ),
    Achievement(
      emoji: '👑',
      title: 'Организатор',
      description: 'Создай свою сходку',
      unlocked: eventsCreated >= 1,
      currentValue: eventsCreated,
      targetValue: 1,
    ),
    Achievement(
      emoji: '🎬',
      title: 'Постоянный организатор',
      description: 'Создай 10 сходок',
      unlocked: eventsCreated >= 10,
      currentValue: eventsCreated,
      targetValue: 10,
    ),
    Achievement(
      emoji: '🎪',
      title: 'Ивент-мастер',
      description: 'Создай 25 сходок',
      unlocked: eventsCreated >= 25,
      currentValue: eventsCreated,
      targetValue: 25,
    ),
    Achievement(
      emoji: '⭐',
      title: 'Любимец публики',
      description: 'Рейтинг 4.5+ от 5 и более человек',
      unlocked: averageRating >= 4.5 && ratingsCount >= 5,
      currentValue: ratingsCount,
      targetValue: 5,
    ),
    Achievement(
      emoji: '💎',
      title: 'Идеальный рейтинг',
      description: 'Рейтинг 5.0 от 10 и более человек',
      unlocked: averageRating >= 5.0 && ratingsCount >= 10,
      currentValue: ratingsCount,
      targetValue: 10,
    ),
    Achievement(
      emoji: '🏅',
      title: 'Клубный',
      description: 'Вступи в клуб',
      unlocked: clubsCount >= 1,
      currentValue: clubsCount,
      targetValue: 1,
    ),
    Achievement(
      emoji: '🌐',
      title: 'Мультиклубник',
      description: 'Состой в 3 и более клубах',
      unlocked: clubsCount >= 3,
      currentValue: clubsCount,
      targetValue: 3,
    ),
    Achievement(
      emoji: '🏛',
      title: 'Клубная элита',
      description: 'Состой в 5 и более клубах',
      unlocked: clubsCount >= 5,
      currentValue: clubsCount,
      targetValue: 5,
    ),
    Achievement(
      emoji: '🎖',
      title: 'Лидер клуба',
      description: 'Стань владельцем или админом клуба',
      unlocked: isClubLeader,
      currentValue: isClubLeader ? 1 : 0,
      targetValue: 1,
    ),
    Achievement(
      emoji: '🤝',
      title: 'Амбассадор',
      description: 'Пригласи друга по реферальному коду',
      unlocked: referralsCount >= 1,
      currentValue: referralsCount,
      targetValue: 1,
    ),
    Achievement(
      emoji: '🚀',
      title: 'Суперамбассадор',
      description: '5 приглашённых друзей',
      unlocked: referralsCount >= 5,
      currentValue: referralsCount,
      targetValue: 5,
    ),
    Achievement(
      emoji: '🎁',
      title: 'Посол бренда',
      description: '10 приглашённых друзей (открывает месяц Premium)',
      unlocked: referralsCount >= 10,
      currentValue: referralsCount,
      targetValue: 10,
    ),
    Achievement(
      emoji: '👑',
      title: 'Легендарный амбассадор',
      description: '20 приглашённых друзей',
      unlocked: referralsCount >= 20,
      currentValue: referralsCount,
      targetValue: 20,
    ),
    Achievement(
      emoji: '✅',
      title: 'Проверенный',
      description: 'Аккаунт подтверждён верификацией',
      unlocked: isVerified,
      currentValue: isVerified ? 1 : 0,
      targetValue: 1,
    ),
    Achievement(
      emoji: '💠',
      title: 'Premium',
      description: 'Есть подписка CarSpot Premium',
      unlocked: isPremium,
      currentValue: isPremium ? 1 : 0,
      targetValue: 1,
    ),
    Achievement(
      emoji: '📅',
      title: 'Первый месяц',
      description: '30 дней в CarSpot',
      unlocked: accountAgeDays >= 30,
      currentValue: accountAgeDays,
      targetValue: 30,
    ),
    Achievement(
      emoji: '🕰',
      title: 'Ветеран сообщества',
      description: 'Год в CarSpot',
      unlocked: accountAgeDays >= 365,
      currentValue: accountAgeDays,
      targetValue: 365,
    ),
    Achievement(
      emoji: '❤️',
      title: 'Народный любимец',
      description: '10 лайков от других участников',
      unlocked: likesCount >= 10,
      currentValue: likesCount,
      targetValue: 10,
    ),
    Achievement(
      emoji: '💯',
      title: 'Звезда сообщества',
      description: '50 лайков от других участников',
      unlocked: likesCount >= 50,
      currentValue: likesCount,
      targetValue: 50,
    ),
    Achievement(
      emoji: '🔮',
      title: 'Икона стиля',
      description: '100 лайков от других участников',
      unlocked: likesCount >= 100,
      currentValue: likesCount,
      targetValue: 100,
    ),
  ];
}
