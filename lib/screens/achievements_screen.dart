import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/gamification.dart';
import '../widgets/section_background.dart';
import '../l10n/l10n_extensions.dart';

/// Полный экран достижений — вынесен из профиля, чтобы не растягивать его
/// длинной простынёй из 28 плиток. Для незалоченных достижений показывает
/// прогресс ("7/10 сходок") вместо просто серой иконки.
class AchievementsScreen extends StatelessWidget {
  final List<Achievement> achievements;
  final int level;
  final String levelTitle;

  const AchievementsScreen({
    Key? key,
    required this.achievements,
    required this.level,
    required this.levelTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unlockedCount = achievements.where((a) => a.unlocked).length;
    // Открытые — впереди, дальше по возрастанию прогресса до цели.
    final sorted = [...achievements]
      ..sort((a, b) {
        if (a.unlocked != b.unlocked) return a.unlocked ? -1 : 1;
        return b.progress.compareTo(a.progress);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('achievements.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        elevation: 0,
        backgroundColor: AppColors.black,
      ),
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const SectionBackground(
            accent: Colors.amber,
            glowAlignment: Alignment.topRight,
            imageAsset: 'assets/backgrounds/profile.jpg',
          ),
          Theme(
            data: AppTheme.dark,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(Colors.amber.withOpacity(0.18), AppColors.surfaceDark),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tArgs('achievements.unlocked_count', {'unlocked': '$unlockedCount', 'total': '${achievements.length}'}),
                                style: const TextStyle(
                                  color: AppColors.textOnDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.tArgs('achievements.level_title', {'level': '$level', 'title': levelTitle}),
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(
                              value: achievements.isEmpty ? 0 : unlockedCount / achievements.length,
                              strokeWidth: 5,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation(Colors.amber),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.86,
                    ),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) => _achievementCard(sorted[index]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievementCard(Achievement a) {
    return Opacity(
      opacity: a.unlocked ? 1.0 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: a.unlocked
              ? Color.alphaBlend(Colors.amber.withOpacity(0.20), AppColors.surfaceDark)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: a.unlocked ? Colors.amber : AppColors.steel),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(a.emoji, style: const TextStyle(fontSize: 26)),
                const Spacer(),
                if (a.unlocked) const Icon(Icons.check_circle, color: Colors.amber, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.t(a.titleKey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              context.t(a.descriptionKey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const Spacer(),
            if (!a.unlocked) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: a.progress,
                  minHeight: 5,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(AppColors.blue),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${a.clampedCurrent}/${a.targetValue}',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
