import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/whats_new_dialog.dart';

/// Показывает анимированную заставку CarSpot при старте приложения, затем
/// плавно (кросс-фейдом) переключается на переданный экран (логин/домашний).
class SplashGate extends StatefulWidget {
  final Widget child;

  const SplashGate({Key? key, required this.child}) : super(key: key);

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _showSplash = false);
      // Диалог "Что нового" показываем после первого кадра с реальным
      // экраном (логин/домашний) — там уже точно есть Navigator/Overlay.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) checkAndShowWhatsNew(context);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _showSplash
          ? const _SplashContent(key: ValueKey('splash'))
          : KeyedSubtree(key: const ValueKey('app'), child: widget.child),
    );
  }
}

class _SplashContent extends StatefulWidget {
  const _SplashContent({Key? key}) : super(key: key);

  @override
  State<_SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<_SplashContent> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scale = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn));
    _slide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.black, AppColors.blueDark, AppColors.black],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: FadeTransition(
                  opacity: _fade,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: AppColors.red.withOpacity(0.55), blurRadius: 30, spreadRadius: 4),
                      ],
                    ),
                    child: const Icon(Icons.directions_car, size: 56, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _fade,
                  child: const Text(
                    'CARSPOT',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeTransition(
                opacity: _fade,
                child: Container(width: 50, height: 3, color: AppColors.blue),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 120,
                child: FadeTransition(
                  opacity: _fade,
                  child: const LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: AppColors.surfaceDarkAlt,
                    valueColor: AlwaysStoppedAnimation(AppColors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
