import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/challenge_goal.dart';
import '../widgets/app_loader.dart';
import '../widgets/section_background.dart';
import '../l10n/l10n_extensions.dart';

/// Сезонные челленджи — ограниченные по времени задания (GET
/// /api/challenges/active) с наградой XP/монет/косметики за выполнение.
/// Прогресс считает сервер сам при обычных действиях (участие в сходке,
/// её создании, добавлении машины, оценке) — здесь только показ и claim.
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({Key? key}) : super(key: key);

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  List<dynamic> _challenges = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _claiming = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.get('/api/challenges/active', token: authProvider.accessToken);
      final items = (response is Map ? response['items'] : null) as List<dynamic>?;
      if (mounted) setState(() => _challenges = items ?? []);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = context.tArgs('challenges.error_message', {'error': '$e'}));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _claim(Map<String, dynamic> challenge) async {
    final id = challenge['id'] as String;
    setState(() => _claiming.add(id));
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.post('/api/challenges/$id/claim', {}, token: authProvider.accessToken);
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
      if (mounted) setState(() => _claiming.remove(id));
    }
  }

  int _daysLeft(String? endsAtRaw) {
    if (endsAtRaw == null) return 0;
    final endsAt = DateTime.tryParse(endsAtRaw);
    if (endsAt == null) return 0;
    final diff = endsAt.difference(DateTime.now());
    if (diff.isNegative) return 0;
    return diff.inHours < 24 ? 1 : diff.inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('challenges.title'), overflow: TextOverflow.ellipsis, maxLines: 1),
        elevation: 0,
        backgroundColor: AppColors.black,
      ),
      backgroundColor: AppColors.scaffoldBg(context),
      body: Stack(
        children: [
          const SectionBackground(
            accent: Colors.deepOrange,
            glowAlignment: Alignment.topLeft,
            imageAsset: 'assets/backgrounds/events.jpg',
          ),
          _isLoading
              ? Center(child: AppLoader())
              : RefreshIndicator(
                  color: Colors.deepOrange,
                  backgroundColor: AppColors.surface(context),
                  onRefresh: _load,
                  child: _errorMessage != null
                      ? _buildError(_errorMessage!)
                      : _challenges.isEmpty
                          ? _buildEmpty()
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _challenges.length,
                              itemBuilder: (context, index) => _challengeCard(
                                context,
                                _challenges[index] as Map<String, dynamic>,
                              ),
                            ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Icon(Icons.flag_outlined, size: 64, color: AppColors.textMuted(context)),
        const SizedBox(height: 14),
        Center(
          child: Text(
            context.t('challenges.empty_title'),
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    // ListView (не Center) — нужно, чтобы жест "потянуть вниз" у обёртывающего
    // RefreshIndicator работал и в состоянии ошибки, не только на списке.
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: Text(context.t('common.retry'))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _challengeCard(BuildContext context, Map<String, dynamic> challenge) {
    final id = challenge['id'] as String;
    final goalType = challenge['goal_type'] as String?;
    final title = (challenge['title'] as String?)?.trim();
    final target = (challenge['target'] as num?)?.toInt() ?? 1;
    final progress = (challenge['progress'] as num?)?.toInt() ?? 0;
    final xpReward = (challenge['xp_reward'] as num?)?.toInt() ?? 0;
    final coinReward = (challenge['coin_reward'] as num?)?.toInt() ?? 0;
    final badgeKey = challenge['badge_key'] as String?;
    final completed = challenge['completed_at'] != null;
    final claimed = challenge['reward_claimed_at'] != null;
    final ratio = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
    final daysLeft = _daysLeft(challenge['ends_at'] as String?);
    final isClaiming = _claiming.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: completed && !claimed
            ? Color.alphaBlend(Colors.deepOrange.withOpacity(0.16), AppColors.surface(context))
            : AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed && !claimed ? Colors.deepOrange.withOpacity(0.6) : AppColors.border(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(challengeGoalIcon(goalType), color: Colors.deepOrange, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title != null && title.isNotEmpty ? title : challengeGoalLabel(context, goalType),
                  style: TextStyle(color: AppColors.onSurface(context), fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!completed && daysLeft > 0)
                Text(
                  context.tArgs('challenges.ends_in_days', {'days': '$daysLeft'}),
                  style: TextStyle(color: AppColors.textMuted(context), fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(completed ? Colors.green : Colors.deepOrange),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '$progress/$target',
                style: TextStyle(color: AppColors.textMuted(context), fontSize: 12),
              ),
              const Spacer(),
              if (xpReward > 0) ...[
                const Icon(Icons.bolt, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text('+$xpReward XP', style: const TextStyle(fontSize: 12, color: Colors.amber)),
                const SizedBox(width: 8),
              ],
              if (coinReward > 0) ...[
                const Icon(Icons.monetization_on, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text('+$coinReward', style: const TextStyle(fontSize: 12, color: Colors.amber)),
                const SizedBox(width: 8),
              ],
              if (badgeKey != null) const Icon(Icons.emoji_events, size: 16, color: Colors.deepOrange),
            ],
          ),
          if (completed) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: claimed
                  ? OutlinedButton(
                      onPressed: null,
                      child: Text(context.t('challenges.claimed_label')),
                    )
                  : ElevatedButton(
                      onPressed: isClaiming ? null : () => _claim(challenge),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                      child: isClaiming
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(context.t('challenges.claim_button')),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
