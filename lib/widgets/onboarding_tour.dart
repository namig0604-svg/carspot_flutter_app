import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../utils/onboarding_flags.dart';
import '../l10n/l10n_extensions.dart';

/// Один шаг интерактивного тура по приложению. Шаг либо привязан к
/// реальному виджету на экране через [targetKey] (тогда вокруг него рисуется
/// подсветка-вырез в затемнении), либо не имеет цели вовсе — в этом случае
/// показывается просто центрированная карточка (вступительный/финальный шаг).
class TourStep {
  /// Виджет-цель. Null — шаг без подсветки конкретного элемента.
  final GlobalKey? targetKey;

  /// Если цель — один из нескольких одинаковых по ширине сегментов внутри
  /// виджета под [targetKey] (например, конкретный пункт нижней навигации
  /// среди пяти), здесь номер сегмента (с нуля) и их общее количество.
  /// Иначе (оба null) подсвечивается вся область виджета целиком.
  final int? segmentIndex;
  final int? segmentCount;

  final String titleKey;
  final String bodyKey;

  const TourStep({
    this.targetKey,
    this.segmentIndex,
    this.segmentCount,
    required this.titleKey,
    required this.bodyKey,
  });
}

/// Проверяет флаг "показать тур" (взводится один раз при самой первой
/// установке приложения — см. onboarding_flags.dart и whats_new_dialog.dart)
/// и, если он взведён, сразу сбрасывает его и запускает тур. Вызывать один
/// раз после первого кадра с реальным домашним экраном — когда виджеты под
/// ключами из [steps] уже точно отрисованы.
Future<void> maybeShowOnboardingTour(BuildContext context, List<TourStep> steps) async {
  SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    return; // Нет доступа к локальному хранилищу — не критично, просто не покажем.
  }

  final shouldShow = prefs.getBool(kShouldShowOnboardingTourPrefsKey) ?? false;
  if (!shouldShow) return;

  // Сбрасываем сразу, а не после прохождения — если пользователь закроет
  // приложение посреди тура, повторно он сам себя не покажет (как и другие
  // one-shot диалоги в проекте, см. whats_new_dialog.dart).
  await prefs.setBool(kShouldShowOnboardingTourPrefsKey, false);

  if (!context.mounted) return;
  await showOnboardingTour(context, steps);
}

/// Запускает тур прямо сейчас, независимо от флага — используется также
/// пунктом меню "Тур по приложению" в профиле, чтобы пройти его повторно.
Future<void> showOnboardingTour(BuildContext context, List<TourStep> steps) {
  if (steps.isEmpty) return Future<void>.value();

  final completer = Completer<void>();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _TourOverlay(
      steps: steps,
      onFinished: () {
        entry.remove();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
  return completer.future;
}

class _TourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback onFinished;

  const _TourOverlay({required this.steps, required this.onFinished});

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> {
  int _index = 0;

  Rect? _targetRect(TourStep step) {
    final key = step.targetKey;
    if (key == null) return null;
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return null;

    final topLeft = renderObject.localToGlobal(Offset.zero);
    final size = renderObject.size;
    var rect = topLeft & size;

    final segmentCount = step.segmentCount;
    final segmentIndex = step.segmentIndex;
    if (segmentCount != null && segmentCount > 0 && segmentIndex != null) {
      final segmentWidth = rect.width / segmentCount;
      rect = Rect.fromLTWH(rect.left + segmentWidth * segmentIndex, rect.top, segmentWidth, rect.height);
    }
    return rect;
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      widget.onFinished();
      return;
    }
    setState(() => _index++);
  }

  void _skip() => widget.onFinished();

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final rect = _targetRect(step);
    final screenSize = MediaQuery.of(context).size;
    final isLast = _index == widget.steps.length - 1;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
              child: CustomPaint(
                painter: _SpotlightPainter(rect: rect),
                size: Size.infinite,
              ),
            ),
          ),
          _buildTooltip(context, step, rect, screenSize, isLast),
        ],
      ),
    );
  }

  Widget _buildTooltip(BuildContext context, TourStep step, Rect? rect, Size screenSize, bool isLast) {
    const cardWidth = 300.0;
    var left = (screenSize.width - cardWidth) / 2;
    left = left.clamp(16.0, screenSize.width - cardWidth - 16.0);

    double top;
    if (rect == null) {
      top = screenSize.height / 2 - 110;
    } else {
      final spaceBelow = screenSize.height - rect.bottom;
      final spaceAbove = rect.top;
      if (spaceBelow >= 210 || spaceBelow >= spaceAbove) {
        top = rect.bottom + 16;
      } else {
        top = (rect.top - 16 - 210).clamp(48.0, screenSize.height - 230.0);
      }
    }
    top = top.clamp(24.0, screenSize.height - 60.0);

    return Positioned(
      left: left,
      top: top,
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 6))],
          border: Border.all(color: Colors.deepOrange.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(widget.steps.length, (i) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i <= _index ? Colors.deepOrange : Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              context.t(step.titleKey),
              style: TextStyle(color: AppColors.onSurface(context), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              context.t(step.bodyKey),
              style: TextStyle(color: AppColors.textMuted(context), fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _skip,
                  child: Text(context.t('onboarding_tour.skip')),
                ),
                ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                  child: Text(isLast ? context.t('onboarding_tour.done') : context.t('onboarding_tour.next')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? rect;

  const _SpotlightPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.72);
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final targetRect = rect;
    if (targetRect == null) {
      canvas.drawPath(full, overlayPaint);
      return;
    }

    final padded = targetRect.inflate(8);
    final hole = Path()..addRRect(RRect.fromRectAndRadius(padded, const Radius.circular(16)));
    final combined = Path.combine(PathOperation.difference, full, hole);
    canvas.drawPath(combined, overlayPaint);

    final borderPaint = Paint()
      ..color = Colors.deepOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(RRect.fromRectAndRadius(padded, const Radius.circular(16)), borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) => oldDelegate.rect != rect;
}
