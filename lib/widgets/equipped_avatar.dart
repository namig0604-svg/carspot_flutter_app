import 'package:flutter/material.dart';

import '../utils/cosmetics.dart';
import '../utils/image_url.dart';

/// Аватар с учётом купленной за монеты косметики — цветная рамка (frame) и
/// маленький значок (badge) поверх. Используется везде, где показывается
/// крупный аватар профиля.
class EquippedAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String fallbackLetter;
  final double radius;
  final String? equippedFrame;
  final String? equippedBadge;
  final bool isOnline;

  const EquippedAvatar({
    Key? key,
    required this.avatarUrl,
    required this.fallbackLetter,
    required this.radius,
    this.equippedFrame,
    this.equippedBadge,
    this.isOnline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final frameColor = frameColorFor(equippedFrame);
    final badgeIcon = badgeIconFor(equippedBadge);

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty) ? NetworkImage(resolveImageUrl(avatarUrl!)) : null,
      child: (avatarUrl == null || avatarUrl!.isEmpty)
          ? Text(fallbackLetter, style: TextStyle(fontSize: radius * 0.7))
          : null,
    );

    if (frameColor != null) {
      avatar = Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: frameColor, width: 3),
          boxShadow: [BoxShadow(color: frameColor.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)],
        ),
        child: avatar,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (isOnline)
          Positioned(
            right: frameColor != null ? 3 : 0,
            bottom: frameColor != null ? 3 : 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
        if (badgeIcon != null)
          Positioned(
            left: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(badgeIcon, size: radius * 0.35, color: Colors.amber),
            ),
          ),
      ],
    );
  }
}
