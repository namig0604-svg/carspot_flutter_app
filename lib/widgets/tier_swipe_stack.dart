import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n_extensions.dart';

/// Одна строка-привилегия внутри карточки тарифа свайп-стека.
class TierPerk {
  final IconData icon;
  final String label;
  final String? note;
  const TierPerk(this.icon, this.label, [this.note]);
}

/// Данные одной карточки тарифа для [TierSwipeStack].
class TierCardData {
  final String tier; // 'basic' | 'pro' | 'max'
  final String title;
  final Color color;
  final String? badgeLabel;
  final String? leadInLabel; // "Всё из Basic, плюс:" — для Pro/Max
  final List<Map<String, dynamic>> plans; // варианты длительности этого тарифа
  final List<TierPerk> perks;

  const TierCardData({
    required this.tier,
    required this.title,
    required this.color,
    required this.plans,
    required this.perks,
    this.badgeLabel,
    this.leadInLabel,
  });
}

/// Свайп-стек выбора тарифа в стиле Tinder: карточки Basic → Pro → Max,
/// свайп влево переключает на более дорогой тариф, свайп вправо — назад на
/// более дешёвый. Используется на экране Premium вместо плоского списка
/// кнопок тарифов — так на глаз проще выбрать и сравнить, не держа в голове
/// сразу все три колонки таблицы.
class TierSwipeStack extends StatefulWidget {
  final List<TierCardData> cards; // порядок: от дешёвого к дорогому
  final bool isCheckingOut;
  final void Function(String planId) onBuy;

  const TierSwipeStack({
    Key? key,
    required this.cards,
    required this.isCheckingOut,
    required this.onBuy,
  }) : super(key: key);

  @override
  State<TierSwipeStack> createState() => _TierSwipeStackState();
}

class _TierSwipeStackState extends State<TierSwipeStack> with SingleTickerProviderStateMixin {
  int _index = 0;
  double _dragX = 0;
  late final AnimationController _controller;
  Animation<double>? _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _settleTo(double target, {VoidCallback? onDone}) {
    _controller.stop();
    _anim = Tween<double>(begin: _dragX, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )..addListener(() => setState(() => _dragX = _anim!.value));
    _controller.forward(from: 0).whenComplete(() {
      if (onDone != null) onDone();
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_controller.isAnimating) _controller.stop();
    setState(() => _dragX += details.delta.dx);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    const threshold = 90.0;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final canGoNext = _index < widget.cards.length - 1; // более дорогой тариф
    final canGoPrev = _index > 0; // более дешёвый тариф

    if ((_dragX < -threshold || velocity < -650) && canGoNext) {
      _settleTo(-520, onDone: () {
        setState(() {
          _index++;
          _dragX = 0;
        });
      });
    } else if ((_dragX > threshold || velocity > 650) && canGoPrev) {
      _settleTo(520, onDone: () {
        setState(() {
          _index--;
          _dragX = 0;
        });
      });
    } else {
      _settleTo(0);
    }
  }

  Widget _buyButton(BuildContext context, Map<String, dynamic> plan, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.isCheckingOut ? null : () => widget.onBuy(plan['id'] as String),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  plan['title'] as String? ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('\$${plan['amount_usd']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, TierCardData data) {
    final cardText = AppColors.onSurface(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: data.color.withOpacity(0.55), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: data.color.withOpacity(0.18),
                child: Icon(Icons.workspace_premium, color: data.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21, color: cardText),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (data.badgeLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: data.color, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    data.badgeLabel!,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (data.leadInLabel != null) ...[
            Text(
              data.leadInLabel!,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: data.color),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              children: [
                for (final perk in data.perks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Icon(perk.icon, size: 18, color: data.color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(perk.label, style: TextStyle(fontSize: 13.5, color: cardText)),
                        ),
                        if (perk.note != null)
                          Text(
                            perk.note!,
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: data.color),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          for (final plan in data.plans) _buyButton(context, plan, data.color),
        ],
      ),
    );
  }

  Widget _dots(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < widget.cards.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == _index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == _index ? widget.cards[i].color : AppColors.border(context),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();
    final current = widget.cards[_index];
    final hasNext = _index < widget.cards.length - 1;
    final next = hasNext ? widget.cards[_index + 1] : null;
    final angle = (_dragX / 280).clamp(-0.3, 0.3);
    final progress = (_dragX.abs() / 140).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          height: 430,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (next != null)
                Transform.scale(
                  scale: 0.93 + 0.07 * progress,
                  child: Opacity(
                    opacity: 0.55 + 0.45 * progress,
                    child: _buildCard(context, next),
                  ),
                ),
              GestureDetector(
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                child: Transform.translate(
                  offset: Offset(_dragX, 0),
                  child: Transform.rotate(
                    angle: angle,
                    child: _buildCard(context, current),
                  ),
                ),
              ),
              if (_dragX < -18)
                Positioned(
                  top: 14,
                  right: 14,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: progress,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.purple.shade700, borderRadius: BorderRadius.circular(8)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.trending_up, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Дороже', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  ),
                ),
              if (_dragX > 18)
                Positioned(
                  top: 14,
                  left: 14,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: progress,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.teal.shade700, borderRadius: BorderRadius.circular(8)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.trending_down, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Дешевле', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _dots(context),
        const SizedBox(height: 8),
        Text(
          context.t('premium.swipe_hint'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted(context)),
        ),
      ],
    );
  }
}
