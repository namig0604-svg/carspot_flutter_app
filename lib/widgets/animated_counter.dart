import 'package:flutter/material.dart';

/// Число, которое "прокручивается" от нуля до итогового значения при
/// появлении на экране — вместо того, чтобы просто сразу отображаться.
/// [formatter] превращает промежуточное значение анимации в готовую строку
/// (например, добавляет суффикс "XP всего" или округляет рейтинг до десятых).
class AnimatedCountText extends StatelessWidget {
  final num end;
  final String Function(num value) formatter;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration duration;

  const AnimatedCountText({
    Key? key,
    required this.end,
    required this.formatter,
    this.style,
    this.textAlign,
    this.duration = const Duration(milliseconds: 900),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: end.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(formatter(value), style: style, textAlign: textAlign);
      },
    );
  }
}
