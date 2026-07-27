// templates/sound_helper.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Manajer suara global (Singleton)
/// 
/// Hanya ada satu instance AudioPlayer untuk seluruh aplikasi.
/// Panggil SoundHelper().playClick() dari mana saja.
class SoundHelper {
  // Singleton instance
  static final SoundHelper _instance = SoundHelper._internal();
  factory SoundHelper() => _instance;
  SoundHelper._internal();

  // AudioPlayer tunggal
  late final AudioPlayer _player;
  bool _isInitialized = false;

  // Volume default (0.0 - 1.0), default 1.0 (100%)
  double _currentVolume = 1.0;

  /// Inisialisasi (panggil di main.dart sebelum digunakan)
  void init() {
    if (!_isInitialized) {
      _player = AudioPlayer();
      _isInitialized = true;
      debugPrint('🔊 SoundHelper initialized');
    }
  }

  /// Putar suara klik dengan volume yang sudah diset
  Future<void> playClick() async {
    if (!_isInitialized) {
      debugPrint('⚠️ SoundHelper belum diinisialisasi!');
      return;
    }
    try {
      await _player.stop();
      // Terapkan volume sebelum play
      await _player.setVolume(_currentVolume);
      await _player.play(AssetSource('sound/click.ogg'));
    } catch (e) {
      debugPrint('🔊 Error play sound: $e');
    }
  }

  /// Set volume global (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    _currentVolume = volume.clamp(0.0, 1.0);
    if (_isInitialized) {
      await _player.setVolume(_currentVolume);
    }
    debugPrint('🔊 Volume set to $_currentVolume');
  }

  /// Dapatkan volume saat ini
  double getVolume() => _currentVolume;

  /// Bersihkan resource (panggil di main.dart saat app ditutup)
  void dispose() {
    if (_isInitialized) {
      _player.dispose();
      _isInitialized = false;
      debugPrint('🔊 SoundHelper disposed');
    }
  }

  /// Cek status
  bool get isInitialized => _isInitialized;
}