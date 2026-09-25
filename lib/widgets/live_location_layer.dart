import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/location_helper.dart';

/// Живая геолокация на карте: "поделиться позицией" + метки других
/// пользователей с ником над меткой. Общая логика для экрана сходок и
/// экрана автосервисов — оба используют один и тот же контроллер.
///
/// Как и чат (см. chat_room_screen.dart), работает на REST-поллинге, а не
/// на WebSocket — в приложении сознательно нет web_socket_channel.
class LiveLocationController extends ChangeNotifier {
  final String? Function() getToken;

  LiveLocationController({required this.getToken});

  bool sharing = false;
  String visibility = 'everyone';
  List<dynamic> peers = [];
  double? myLat;
  double? myLng;
  bool _started = false;

  Timer? _nearbyTimer;
  Timer? _selfTimer;

  static const _nearbyInterval = Duration(seconds: 8);
  static const _selfInterval = Duration(seconds: 15);

  Future<void> start() async {
    if (_started) return;
    _started = true;

    await _loadSettings();
    unawaited(_refreshNearby());
    _nearbyTimer = Timer.periodic(_nearbyInterval, (_) => _refreshNearby());

    unawaited(_refreshSelfPosition());
    _selfTimer = Timer.periodic(_selfInterval, (_) => _refreshSelfPosition());
  }

  void disposeController() {
    _nearbyTimer?.cancel();
    _selfTimer?.cancel();
  }

  Future<void> _loadSettings() async {
    try {
      final res = await ApiService.get('/api/location/settings', token: getToken());
      if (res is Map) {
        sharing = res['share_location'] == true;
        visibility = (res['location_visibility'] as String?) ?? 'everyone';
        notifyListeners();
      }
    } catch (_) {
      // Тихо — карта работает и без этого.
    }
  }

  Future<void> _refreshNearby() async {
    try {
      final res = await ApiService.get('/api/location/nearby', token: getToken());
      if (res is List) {
        peers = res;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Своя позиция — берём с устройства всегда (чтобы показать "вы здесь"
  /// на карте), но на сервер отправляем только если включён шаринг.
  Future<void> _refreshSelfPosition() async {
    final pos = await determineCurrentPosition();
    if (pos == null) return;
    myLat = pos.latitude;
    myLng = pos.longitude;
    notifyListeners();

    if (sharing) {
      try {
        await ApiService.post(
          '/api/location/update',
          {'lat': pos.latitude, 'lng': pos.longitude},
          token: getToken(),
        );
      } catch (_) {}
    }
  }

  Future<void> setSharing(bool enabled, {String? newVisibility}) async {
    final res = await ApiService.post(
      '/api/location/share',
      {
        'enabled': enabled,
        if (newVisibility != null) 'visibility': newVisibility,
      },
      token: getToken(),
    );
    if (res is Map) {
      sharing = res['share_location'] == true;
      visibility = (res['location_visibility'] as String?) ?? visibility;
    }
    notifyListeners();

    if (sharing) {
      unawaited(_refreshSelfPosition());
    } else {
      unawaited(_refreshNearby());
    }
  }

  /// Маркеры чужих живых меток — с ником над точкой.
  List<Marker> buildPeerMarkers({required void Function(Map<String, dynamic> peer) onTap}) {
    return peers.whereType<Map>().map<Marker?>((raw) {
      final peer = raw.cast<String, dynamic>();
      final lat = (peer['lat'] as num?)?.toDouble();
      final lng = (peer['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) {
        return null;
      }
      return Marker(
        point: LatLng(lat, lng),
        width: 110,
        height: 62,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () => onTap(peer),
          child: _PeerMarker(username: (peer['username'] ?? '').toString(), avatarUrl: peer['avatar_url'] as String?),
        ),
      );
    }).whereType<Marker>().toList();
  }

  Marker? buildSelfMarker() {
    if (myLat == null || myLng == null) return null;
    return Marker(
      point: LatLng(myLat!, myLng!),
      width: 26,
      height: 26,
      alignment: Alignment.center,
      child: const _SelfDot(),
    );
  }
}

class _PeerMarker extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  const _PeerMarker({required this.username, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.blue, width: 1),
          ),
          constraints: const BoxConstraints(maxWidth: 100),
          child: Text(
            username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          clipBehavior: Clip.antiAlias,
          child: (avatarUrl != null && avatarUrl!.isNotEmpty)
              ? Image.network(avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 16))
              : const Icon(Icons.person, color: Colors.white, size: 16),
        ),
      ],
    );
  }
}

/// Точка "вы здесь" — синий пульсирующий кружок, как в большинстве карт.
class _SelfDot extends StatelessWidget {
  const _SelfDot();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.25), shape: BoxShape.circle),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }
}

/// Кнопка-иконка "поделиться геопозицией" рядом с переключателем темы карты
/// и фильтрами — стиль тот же (тёмный квадрат с рамкой), синяя точка активна.
class LiveLocationToggleButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const LiveLocationToggleButton({Key? key, required this.active, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(child: Icon(active ? Icons.my_location : Icons.location_disabled, size: 18, color: active ? AppColors.blue : Colors.white)),
            if (active)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const Map<String, String> _visibilityLabels = {
  'everyone': 'Все',
  'friends': 'Только друзья',
  'club': 'Только соклубники',
};

const Map<String, IconData> _visibilityIcons = {
  'everyone': Icons.public,
  'friends': Icons.people,
  'club': Icons.groups,
};

/// Bottom-sheet настроек живой геолокации: включить/выключить трансляцию
/// своей метки + кому она видна (все / друзья / соклубники). Открывается
/// той же кнопкой, что и включает шаринг. Настройка видимости лежит
/// в том же месте, что и сам переключатель "делиться позицией".
Future<void> showLiveLocationSheet(BuildContext context, LiveLocationController controller) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          bool isSaving = false;

          Future<void> apply(bool enabled, {String? visibility}) async {
            setSheetState(() => isSaving = true);
            try {
              await controller.setSharing(enabled, newVisibility: visibility);
            } catch (e) {
              if (sheetContext.mounted) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text('$e')));
              }
            } finally {
              setSheetState(() => isSaving = false);
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppColors.steelStrong,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Живая геолокация', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetContext)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Покажите своим друзьям, соклубникам или всем в приложении, где вы сейчас находитесь.',
                      style: TextStyle(color: AppColors.textMutedDark, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDarkAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.steel),
                      ),
                      child: SwitchListTile(
                        value: controller.sharing,
                        activeColor: AppColors.blue,
                        title: const Text('Делиться своей меткой', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          controller.sharing ? 'Транслируется сейчас' : 'Сейчас выключено',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMutedDark),
                        ),
                        onChanged: isSaving ? null : (v) => apply(v),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Кто видит мою метку', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 8),
                    ..._visibilityLabels.entries.map((entry) {
                      final selected = controller.visibility == entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: isSaving
                              ? null
                              : () => apply(true, visibility: entry.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.blue.withOpacity(0.16) : AppColors.surfaceDarkAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? AppColors.blue : AppColors.steel, width: selected ? 1.2 : 1),
                            ),
                            child: Row(
                              children: [
                                Icon(_visibilityIcons[entry.key], size: 18, color: selected ? AppColors.blue : AppColors.textMutedDark),
                                const SizedBox(width: 10),
                                Expanded(child: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w600))),
                                if (selected) const Icon(Icons.check_circle, color: AppColors.blue, size: 18),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
