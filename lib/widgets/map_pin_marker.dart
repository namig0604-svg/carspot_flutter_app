import 'package:flutter/material.dart';

/// Маркер на карте в виде цветного "пина" с иконкой внутри — вместо голой
/// иконки поверх тайлов (плохо видна на некоторых участках карты). У формы
/// смысл: она отличает тип метки на глаз ещё до того, как видна иконка —
/// автосервисы рисуются скруглённым квадратом, сходки — кругом.
class MapPinMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  /// true — скруглённый квадрат (автосервисы и т.п.), false — круг (сходки).
  final bool square;

  const MapPinMarker({
    Key? key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.square = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(size * 0.28) : null,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.55),
    );
  }
}
