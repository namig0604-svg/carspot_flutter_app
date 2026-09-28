import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_loader.dart';
import '../l10n/l10n_extensions.dart';

const List<List<int>> _dailyRewardTable = [
  [20, 10],
  [25, 12],
  [30, 15],
  [40, 20],
  [50, 25],
  [60, 30],
  [100, 50],
];

/// Показывает диалог ежедневного входа. Если [onlyIfClaimable] — молча ничего
/// не делает, когда сегодняшняя награда уже забрана (для автопоказа при
/// открытии приложения, чтобы не мешать пользователю, который уже забрал).
Future<void> showDailyLoginDialog(BuildContext context, {bool onlyIfClaimable = false}) async {
  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final status = await ApiService.get('/api/daily-login/status', token: authProvider.accessToken);
    final canClaim = status is Map && status['can_claim'] == true;
    if (onlyIfClaimable && !canClaim) return;
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (_) => DailyLoginDialogContent(
        initialStreak: status is Map ? (status['current_streak'] as int?) ?? 0 : 0,
        initialNextDay: status is Map ? (status['next_day'] as int?) ?? 1 : 1,
        initialCanClaim: canClaim,
      ),
    );
  } catch (_) {
    // Тихо игнорируем — это необязательный бонус, не должен мешать основному экрану.
  }
}

class DailyLoginDialogContent extends StatefulWidget {
  final int initialStreak;
  final int initialNextDay;
  final bool initialCanClaim;

  const DailyLoginDialogContent({
    Key? key,
    required this.initialStreak,
    required this.initialNextDay,
    required this.initialCanClaim,
  }) : super(key: key);

  @override
  State<DailyLoginDialogContent> createState() => _DailyLoginDialogContentState();
}

class _DailyLoginDialogContentState extends State<DailyLoginDialogContent> {
  late int _streak;
  late int _nextDay;
  late bool _canClaim;
  bool _isClaiming = false;
  Map<String, dynamic>? _lastResult;

  @override
  void initState() {
    super.initState();
    _streak = widget.initialStreak;
    _nextDay = widget.initialNextDay;
    _canClaim = widget.initialCanClaim;
  }

  Future<void> _claim() async {
    if (_isClaiming || !_canClaim) return;
    setState(() => _isClaiming = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await ApiService.post('/api/daily-login/claim', {}, token: authProvider.accessToken);
      setState(() {
        _lastResult = response is Map ? Map<String, dynamic>.from(response) : null;
        _streak = _lastResult?['day'] as int? ?? _streak;
        _nextDay = _lastResult?['next_streak_day'] as int? ?? _nextDay;
        _canClaim = false;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardText = isDark ? AppColors.textOnDark : AppColors.textOnLight;
    final gotBonus = _lastResult != null && _lastResult!['bonus_premium_days'] != null;

    return Dialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard, size: 40, color: Colors.amber),
            const SizedBox(height: 8),
            Text(
              context.t('daily_login.title'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cardText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              context.t('daily_login.hint'),
              style: TextStyle(fontSize: 12.5, color: cardText.withOpacity(0.65)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) => _dayDot(context, i + 1, cardText)),
            ),
            const SizedBox(height: 18),
            if (_lastResult != null) ...[
              Text(
                context.tArgs('daily_login.reward_gained', {
                  'xp': '${_lastResult!['xp_reward']}',
                  'coins': '${_lastResult!['coin_reward']}',
                }),
                style: TextStyle(color: cardText, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              if (gotBonus) ...[
                const SizedBox(height: 6),
                Text(
                  context.t('daily_login.bonus_message'),
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.t('common.close')),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _canClaim && !_isClaiming ? _claim : null,
                child: _isClaiming
                    ? const SizedBox(width: 18, height: 18, child: AppLoader(size: 18, color: Colors.white))
                    : Text(_canClaim ? context.t('daily_login.claim_button') : context.t('daily_login.already_claimed')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dayDot(BuildContext context, int day, Color cardText) {
    final done = day <= _streak;
    final isCurrent = day == _nextDay && _canClaim;
    final isBonusDay = day == 7;
    Color bg;
    Color fg;
    if (done) {
      bg = Colors.green;
      fg = Colors.white;
    } else if (isCurrent) {
      bg = isBonusDay ? Colors.amber : AppColors.blue;
      fg = Colors.white;
    } else {
      bg = Colors.transparent;
      fg = cardText.withOpacity(0.5);
    }
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: done || isCurrent ? bg : cardText.withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : isBonusDay
                  ? Icon(Icons.workspace_premium, size: 15, color: fg)
                  : Text('$day', style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 3),
        Text('+${_dailyRewardTable[day - 1][0]}', style: TextStyle(fontSize: 9, color: cardText.withOpacity(0.55))),
      ],
    );
  }
}
