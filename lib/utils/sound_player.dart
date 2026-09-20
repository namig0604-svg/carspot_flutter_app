import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

/// Короткие звуковые эффекты интерфейса — тап, успех, ошибка, новый
/// уровень/достижение. Уважает переключатель "Звуковые эффекты" в настройках
/// и никогда не роняет приложение, даже если звук не смог воспроизвестись
/// (например, браузер блокирует автозапуск звука без явного жеста).
enum AppSound { click, success, error, levelUp }

class SoundPlayer {
  SoundPlayer._();

  static final AudioPlayer _player = AudioPlayer();

  static const Map<AppSound, String> _files = {
    AppSound.click: 'sounds/click.wav',
    AppSound.success: 'sounds/success.wav',
    AppSound.error: 'sounds/error.wav',
    AppSound.levelUp: 'sounds/levelup.wav',
  };

  static Future<void> play(BuildContext context, AppSound sound) async {
    try {
      final enabled = Provider.of<SettingsProvider>(context, listen: false).soundEffectsEnabled;
      if (!enabled) return;
      final path = _files[sound];
      if (path == null) return;
      await _player.stop();
      await _player.play(AssetSource(path), volume: 0.6);
    } catch (_) {
      // Звук не критичен — тихо игнорируем.
    }
  }
}
