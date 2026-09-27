import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../utils/app_changelog.dart';
import '../utils/app_version.dart';
import '../l10n/l10n_extensions.dart';

/// Ключ в SharedPreferences, под которым хранится версия приложения,
/// которую пользователь уже видел (чтобы показать диалог "Что нового"
/// ровно один раз — сразу после обновления, а не при каждом запуске).
const String _kLastSeenVersionKey = 'last_seen_app_version';

/// Проверяет, обновилось ли приложение с прошлого запуска, и если да —
/// показывает диалог со списком изменений из [kAppChangelog] для текущей
/// версии [kAppVersion]. При первой установке (когда сохранённой версии
/// ещё нет) диалог не показывается — просто запоминаем текущую версию,
/// чтобы не показывать список изменений тем, кто ставит приложение впервые.
///
/// Вызывать один раз после того, как построен первый "боевой" экран
/// (после сплэш-скрина) — см. lib/screens/splash_screen.dart.
Future<void> checkAndShowWhatsNew(BuildContext context) async {
  SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    return; // Нет доступа к локальному хранилищу — не критично, просто не покажем.
  }

  final lastSeenVersion = prefs.getString(_kLastSeenVersionKey);

  if (lastSeenVersion == null) {
    // Первый запуск после установки — ничего не показываем, только запоминаем версию.
    await prefs.setString(_kLastSeenVersionKey, kAppVersion);
    return;
  }

  if (lastSeenVersion == kAppVersion) {
    return; // Уже видели список изменений для этой версии.
  }

  final changes = kAppChangelog[kAppVersion] ?? const <String>[];

  // Помечаем версию как показанную даже если для неё нет записи в
  // changelog'е — чтобы не пытаться показать диалог на каждом запуске.
  await prefs.setString(_kLastSeenVersionKey, kAppVersion);

  if (changes.isEmpty) return;
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _WhatsNewDialog(version: kAppVersion, changes: changes),
  );
}

class _WhatsNewDialog extends StatelessWidget {
  final String version;
  final List<String> changes;

  const _WhatsNewDialog({required this.version, required this.changes});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                    child: const Icon(Icons.rocket_launch, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('whats_new.title'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          context.tArgs('whats_new.version', {'version': version}),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                context.t('whats_new.header'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final change in changes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.check_circle, size: 16, color: AppColors.blue),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(change, style: const TextStyle(fontSize: 14, height: 1.35)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(context.t('whats_new.button'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
