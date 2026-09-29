import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/challenge_goal.dart';
import '../screens/challenges_screen.dart';
import '../l10n/l10n_extensions.dart';

/// Компактный баннер текущего сезонного челленджа на главном экране —
/// показывает самый актуальный из активных (см. _pickFeatured): готовый к
/// получению награды в приоритете, иначе — тот, где прогресс дальше всего.
/// Полный список — на отдельном экране (ChallengesScreen), сюда выведен
/// только один, чтобы не перегружать главный экран. Если активных
/// челленджей нет вообще — баннер схлопывается в SizedBox.shrink().
class ChallengesBanner extends StatefulWidget {
  const ChallengesBanner({Key? key}) : super(key: key);

  @override
  State<ChallengesBanner> createState() => _ChallengesBannerState();
}

class _ChallengesBannerState extends State<ChallengesBanner> {
  Map<String, dynamic>? _featured;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/challenges/active', token: authProvider.accessToken);
      final items = (response is Map ? response['items'] : null) as List<dynamic>?;
      if (mounted) setState(() => _featured = _pickFeatured(items ?? []));
    } catch (_) {
      // Тихо игнорируем — это необязательный акцент на главном экране, не
      // должен мешать основному контенту при сетевой ошибке.
    }
  }

  Map<String, dynamic>? _pickFeatured(List<dynamic> items) {
    if (items.isEmpty) return null;
    final typed = items.cast<Map<String, dynamic>>();

    final readyToClaim = typed.where((c) => c['completed_at'] != null && c['reward_claimed_at'] == null);
    if (readyToClaim.isNotEmpty) return readyToClaim.first;

    final inProgress = typed.where((c) => c['reward_claimed_at'] == null).toList();
    final pool = inProgress.isNotEmpty ? inProgress : typed;
    pool.sort((a, b) {
      final ra = _ratio(a);
      final rb = _ratio(b);
      return rb.compareTo(ra);
    });
    return pool.first;
  }

  double _ratio(Map<String, dynamic> c) {
    final target = (c['target'] as num?)?.toInt() ?? 1;
    final progress = (c['progress'] as num?)?.toInt() ?? 0;
    return target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
  }

  Future<void> _claim() async {
    final challenge = _featured;
    if (challenge == null || _isClaiming) return;
    setState(() => _isClaiming = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.post(
        '/api/challenges/${challenge['id']}/claim',
        {},
        token: authProvider.accessToken,
      );
      if (!mounted) return;
      final xp = (response is Map ? response['xp_reward'] : null) ?? 0;
      final coins = (response is Map ? response['coin_reward'] : null) ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tArgs('challenges.claim_success', {'xp': '$xp', 'coins': '$coins'}))),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tArgs('challenges.error_message', {'error': '$e'}))),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _featured;
    if (challenge == null) return const SizedBox.shrink();

    final cardText = AppColors.onSurface(context);
    final goalType = challenge['goal_type'] as String?;
    final title = (challenge['title'] as String?)?.trim();
    final target = (challenge['target'] as num?)?.toInt() ?? 1;
    final progress = (challenge['progress'] as num?)?.toInt() ?? 0;
    final ratio = _ratio(challenge);
    final readyToClaim = challenge['completed_at'] != null && challenge['reward_claimed_at'] == null;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengesScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: readyToClaim
              ? Color.alphaBlend(Colors.deepOrange.withOpacity(0.16), AppColors.surface(context))
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: readyToClaim ? Colors.deepOrange.withOpacity(0.6) : AppColors.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(challengeGoalIcon(goalType), color: Colors.deepOrange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.t('home.challenges_banner_label'),
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: cardText.withOpacity(0.6), letterSpacing: 0.3),
                  ),
                ),
                Text(
                  context.t('home.challenges_banner_view_all'),
                  style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Icon(Icons.chevron_right, size: 16, color: Colors.deepOrange),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title != null && title.isNotEmpty ? title : challengeGoalLabel(context, goalType),
              style: TextStyle(color: cardText, fontWeight: FontWeight.bold, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(readyToClaim ? Colors.green : Colors.deepOrange),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$progress/$target', style: TextStyle(color: cardText.withOpacity(0.7), fontSize: 12)),
              ],
            ),
            if (readyToClaim) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isClaiming ? null : _claim,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                  child: _isClaiming
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(context.t('challenges.claim_button')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
