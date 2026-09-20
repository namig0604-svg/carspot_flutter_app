import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Анимированный лоадер CarSpot — вращающееся колесо вместо стандартного
/// системного спиннера. Используется по всему приложению вместо
/// CircularProgressIndicator(), чтобы даже загрузка была в стиле гонок.
class AppLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const AppLoader({Key? key, this.size = 32, this.color}) : super(key: key);

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.blue;
    return RotationTransition(
      turns: _controller,
      child: Icon(Icons.tire_repair, size: widget.size, color: color),
    );
  }
}
