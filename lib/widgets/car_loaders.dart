import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Доп. набор автомобильных лоадеров — вместе с [AppLoader] (вращающееся
/// колесо из app_loader.dart, которое остаётся стандартом для мелких
/// инлайн-спиннеров в кнопках) даёт визуальное разнообразие для крупных/
/// полноэкранных загрузок: чтобы разные экраны не грузились одинаково,
/// [AppFullLoader] сам случайно выбирает один из трёх стилей ниже и держит
/// выбор фиксированным на всё время своей жизни (без "перескоков" при
/// ребилдах виджета).

/// 1) Дорога с пунктирной разметкой и подпрыгивающей машинкой.
class RoadLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const RoadLoader({Key? key, this.size = 72, this.color}) : super(key: key);

  @override
  State<RoadLoader> createState() => _RoadLoaderState();
}

class _RoadLoaderState extends State<RoadLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.blue;
    return SizedBox(
      width: widget.size,
      height: widget.size * 0.6,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.size, widget.size * 0.6),
            painter: _RoadPainter(progress: _controller.value, color: color),
          );
        },
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RoadPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final roadY = size.height * 0.78;
    final roadPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, roadY), Offset(size.width, roadY), roadPaint);

    final dashPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const dashWidth = 10.0;
    const dashGap = 8.0;
    final shift = progress * (dashWidth + dashGap);
    var x = -shift;
    while (x < size.width) {
      canvas.drawLine(Offset(x, roadY), Offset(x + dashWidth, roadY), dashPaint);
      x += dashWidth + dashGap;
    }

    final bounce = sin(progress * 2 * pi) * 2.5;
    final carCenter = Offset(size.width / 2, roadY - 12 + bounce);
    _drawCar(canvas, carCenter, size.width * 0.34, color);
  }

  void _drawCar(Canvas canvas, Offset center, double w, Color color) {
    final h = w * 0.42;
    final bodyPaint = Paint()..color = color;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      Radius.circular(h * 0.35),
    );
    canvas.drawRRect(bodyRect, bodyPaint);
    final roofRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center.dx - w * 0.05, center.dy - h * 0.55), width: w * 0.5, height: h * 0.6),
      Radius.circular(h * 0.3),
    );
    canvas.drawRRect(roofRect, bodyPaint);
    final wheelPaint = Paint()..color = Colors.black87;
    final wheelR = h * 0.28;
    canvas.drawCircle(Offset(center.dx - w * 0.28, center.dy + h * 0.42), wheelR, wheelPaint);
    canvas.drawCircle(Offset(center.dx + w * 0.28, center.dy + h * 0.42), wheelR, wheelPaint);
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) => oldDelegate.progress != progress;
}

/// 2) Спидометр со стрелкой, качающейся туда-обратно по дуге.
class SpeedometerLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const SpeedometerLoader({Key? key, this.size = 72, this.color}) : super(key: key);

  @override
  State<SpeedometerLoader> createState() => _SpeedometerLoaderState();
}

class _SpeedometerLoaderState extends State<SpeedometerLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _needle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat(reverse: true);
    _needle = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.blue;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _needle,
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _SpeedometerPainter(t: _needle.value, color: color),
          );
        },
      ),
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double t;
  final Color color;

  _SpeedometerPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    const startAngle = pi * 0.75;
    const sweepAngle = pi * 1.5;

    final arcPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, arcPaint);

    final tickPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 2;
    for (var i = 0; i <= 8; i++) {
      final a = startAngle + sweepAngle * (i / 8);
      final p1 = center + Offset(cos(a), sin(a)) * (radius - 6);
      final p2 = center + Offset(cos(a), sin(a)) * radius;
      canvas.drawLine(p1, p2, tickPaint);
    }

    final needleAngle = startAngle + sweepAngle * t;
    final needlePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final needleEnd = center + Offset(cos(needleAngle), sin(needleAngle)) * (radius - 8);
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) => oldDelegate.t != t;
}

/// 3) Светофор с бегущими по кругу огнями — компактная вариация загрузки
/// (диалоги, карточки, списки).
class TrafficLightLoader extends StatefulWidget {
  final double size;

  const TrafficLightLoader({Key? key, this.size = 56}) : super(key: key);

  @override
  State<TrafficLightLoader> createState() => _TrafficLightLoaderState();
}

class _TrafficLightLoaderState extends State<TrafficLightLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const List<Color> _colors = [AppColors.red, AppColors.amber, Color(0xFF3DDC84)];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = widget.size * 0.26;
    return SizedBox(
      width: widget.size,
      height: dotSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              var phase = _controller.value - i / 3;
              if (phase < 0) phase += 1.0;
              final pulse = (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
              final scale = 0.55 + 0.45 * pulse;
              return Opacity(
                opacity: (0.4 + 0.6 * pulse).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(color: _colors[i], shape: BoxShape.circle),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Обёртка для крупных/полноэкранных загрузок: при каждом монтировании
/// случайно выбирает один из трёх стилей выше, чтобы разные экраны
/// приложения не грузились одинаково, и держит выбор фиксированным на всё
/// время жизни виджета.
class AppFullLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const AppFullLoader({Key? key, this.size = 72, this.color}) : super(key: key);

  @override
  State<AppFullLoader> createState() => _AppFullLoaderState();
}

class _AppFullLoaderState extends State<AppFullLoader> {
  late final int _variant;

  @override
  void initState() {
    super.initState();
    _variant = Random().nextInt(3);
  }

  @override
  Widget build(BuildContext context) {
    switch (_variant) {
      case 0:
        return RoadLoader(size: widget.size, color: widget.color);
      case 1:
        return SpeedometerLoader(size: widget.size, color: widget.color);
      default:
        return TrafficLightLoader(size: widget.size);
    }
  }
}

/// Полоса загрузки в виде дороги с бегущей разметкой — для заставки
/// приложения вместо стандартного LinearProgressIndicator.
class RoadProgressBar extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final Color backgroundColor;

  const RoadProgressBar({
    Key? key,
    this.width = 120,
    this.height = 4,
    this.color = AppColors.blue,
    this.backgroundColor = AppColors.surfaceDarkAlt,
  }) : super(key: key);

  @override
  State<RoadProgressBar> createState() => _RoadProgressBarState();
}

class _RoadProgressBarState extends State<RoadProgressBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _RoadProgressPainter(
              progress: _controller.value,
              color: widget.color,
              backgroundColor: widget.backgroundColor,
            ),
          );
        },
      ),
    );
  }
}

class _RoadProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _RoadProgressPainter({required this.progress, required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(size.height / 2)),
      bgPaint,
    );

    final dashPaint = Paint()..color = color;
    const dashWidth = 8.0;
    const dashGap = 6.0;
    final shift = progress * (dashWidth + dashGap);
    var x = -shift;
    while (x < size.width) {
      final left = x.clamp(0.0, size.width);
      final right = (x + dashWidth).clamp(0.0, size.width);
      if (right > left) {
        canvas.drawRect(Rect.fromLTRB(left, 0, right, size.height), dashPaint);
      }
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _RoadProgressPainter oldDelegate) => oldDelegate.progress != progress;
}
