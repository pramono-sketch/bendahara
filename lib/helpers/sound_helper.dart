// lib/helpers/sound_helper.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Manajer suara global (Singleton).
///
/// Digunakan oleh seluruh halaman aplikasi.
///
/// Suara:
/// - click.ogg
/// - notification.mp3
///
/// Tetap menggunakan SATU AudioPlayer agar kompatibel
/// dengan implementasi SoundHelper lama.
///
/// Sistem audio dibuat serial:
/// - operasi audio tidak berjalan bersamaan
/// - spam klik tidak membuat banyak operasi play/stop bertumpuk
/// - request terbaru akan menjadi prioritas
class SoundHelper {
  // ==========================================================
  // SINGLETON
  // ==========================================================

  static final SoundHelper _instance = SoundHelper._internal();

  factory SoundHelper() => _instance;

  SoundHelper._internal();

  // ==========================================================
  // AUDIO PLAYER
  // ==========================================================

  AudioPlayer? _player;

  bool _isInitialized = false;

  // ==========================================================
  // VOLUME
  // ==========================================================

  double _currentVolume = 1.0;

  // ==========================================================
  // AUDIO QUEUE
  // ==========================================================

  /// Semua operasi audio diserialkan melalui Future ini.
  ///
  /// Tujuannya supaya stop / setVolume / play tidak saling
  /// bertabrakan ketika user menekan tombol dengan cepat.
  Future<void> _audioChain = Future<void>.value();

  /// Nomor request audio terbaru.
  ///
  /// Jika banyak klik datang berturut-turut:
  ///
  /// click 1
  /// click 2
  /// click 3
  /// click 4
  ///
  /// hanya request terbaru yang akan diprioritaskan.
  int _audioRequestId = 0;

  /// Versi perubahan volume terbaru.
  ///
  /// Berguna terutama ketika slider digeser sangat cepat.
  int _volumeRequestId = 0;

  // ==========================================================
  // INIT
  // ==========================================================

  /// Inisialisasi SoundHelper.
  ///
  /// Panggil satu kali dari main.dart sebelum runApp().
  void init() {
    if (_isInitialized) {
      return;
    }

    _player = AudioPlayer();

    _isInitialized = true;

    debugPrint(
      '🔊 SoundHelper initialized',
    );
  }

  // ==========================================================
  // INTERNAL AUDIO QUEUE
  // ==========================================================

  Future<void> _enqueueAudio(
    Future<void> Function(int requestId) action,
  ) {
    final requestId = ++_audioRequestId;

    _audioChain = _audioChain
        .catchError(
          (
            Object error,
            StackTrace stackTrace,
          ) {
            debugPrint(
              '🔊 Previous audio operation error: $error',
            );
          },
        )
        .then<void>(
          (_) => action(requestId),
        )
        .catchError(
          (
            Object error,
            StackTrace stackTrace,
          ) {
            debugPrint(
              '🔊 Audio operation error: $error',
            );
          },
        );

    return _audioChain;
  }

  // ==========================================================
  // CLICK SOUND
  // ==========================================================

  /// Memutar:
  ///
  /// assets/sound/click.ogg
  ///
  /// Digunakan untuk tombol dan kontrol interaktif.
  Future<void> playClick() {
    if (!_isInitialized || _player == null) {
      debugPrint(
        '⚠️ SoundHelper belum diinisialisasi!',
      );

      return Future<void>.value();
    }

    return _enqueueAudio(
      (requestId) async {
        final player = _player;

        if (!_isInitialized || player == null) {
          return;
        }

        try {
          // Hentikan suara sebelumnya.
          await player.stop();

          // Jika ada request baru setelah stop,
          // request lama tidak perlu dilanjutkan.
          if (requestId != _audioRequestId) {
            return;
          }

          await player.setVolume(
            _currentVolume,
          );

          if (requestId != _audioRequestId) {
            return;
          }

          await player.play(
            AssetSource(
              'sound/click.ogg',
            ),
          );
        } catch (e) {
          debugPrint(
            '🔊 Error play click sound: $e',
          );
        }
      },
    );
  }

  // ==========================================================
  // NOTIFICATION SOUND
  // ==========================================================

  /// Memutar:
  ///
  /// assets/sound/notification.mp3
  ///
  /// Digunakan untuk AwesomeDialog / popup.
  Future<void> playNotification() {
    if (!_isInitialized || _player == null) {
      debugPrint(
        '⚠️ SoundHelper belum diinisialisasi!',
      );

      return Future<void>.value();
    }

    return _enqueueAudio(
      (requestId) async {
        final player = _player;

        if (!_isInitialized || player == null) {
          return;
        }

        try {
          // Hentikan suara sebelumnya.
          await player.stop();

          if (requestId != _audioRequestId) {
            return;
          }

          await player.setVolume(
            _currentVolume,
          );

          if (requestId != _audioRequestId) {
            return;
          }

          await player.play(
            AssetSource(
              'sound/notification.mp3',
            ),
          );
        } catch (e) {
          debugPrint(
            '🔊 Error play notification sound: $e',
          );
        }
      },
    );
  }

  // ==========================================================
  // SET VOLUME
  // ==========================================================

  /// Mengatur volume global.
  ///
  /// Nilai otomatis dibatasi:
  ///
  /// 0.0 = mute
  /// 1.0 = 100%
  Future<void> setVolume(
    double volume,
  ) {
    _currentVolume = volume.clamp(
      0.0,
      1.0,
    );

    final volumeRequestId =
        ++_volumeRequestId;

    if (!_isInitialized || _player == null) {
      debugPrint(
        '🔊 Volume set to $_currentVolume',
      );

      return Future<void>.value();
    }

    _audioChain = _audioChain
        .catchError(
          (
            Object error,
            StackTrace stackTrace,
          ) {
            debugPrint(
              '🔊 Previous audio operation error: $error',
            );
          },
        )
        .then<void>(
          (_) async {
            final player = _player;

            if (!_isInitialized || player == null) {
              return;
            }

            // Bila slider sudah berubah lagi,
            // tidak perlu menerapkan nilai volume lama.
            if (volumeRequestId != _volumeRequestId) {
              return;
            }

            try {
              await player.setVolume(
                _currentVolume,
              );
            } catch (e) {
              debugPrint(
                '🔊 Error set volume: $e',
              );
            }
          },
        )
        .catchError(
          (
            Object error,
            StackTrace stackTrace,
          ) {
            debugPrint(
              '🔊 Volume operation error: $error',
            );
          },
        );

    debugPrint(
      '🔊 Volume set to $_currentVolume',
    );

    return _audioChain;
  }

  // ==========================================================
  // GET VOLUME
  // ==========================================================

  /// Mendapatkan volume saat ini.
  double getVolume() {
    return _currentVolume;
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  /// Membersihkan resource audio.
  ///
  /// Tidak mengubah API lama:
  /// tetap bisa dipanggil dengan:
  ///
  /// SoundHelper().dispose();
  void dispose() {
    if (!_isInitialized) {
      return;
    }

    // Batalkan prioritas request lama.
    _audioRequestId++;

    _volumeRequestId++;

    final player = _player;

    _player = null;

    _isInitialized = false;

    if (player != null) {
      player.dispose();
    }

    debugPrint(
      '🔊 SoundHelper disposed',
    );
  }

  // ==========================================================
  // STATUS
  // ==========================================================

  bool get isInitialized {
    return _isInitialized;
  }
}