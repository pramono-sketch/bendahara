// lib/features/log_aktivitas.dart
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/appearance.dart';
import '../data.dart';
import '../helpers/scroll_reveal.dart';
import '../helpers/sound_helper.dart';
import '../helpers/theme_helper.dart';
import '../l10n/translations.dart';

/// Menampilkan seluruh riwayat aktivitas yang tersimpan di Firestore.
/// Collection canonical: log_aktivitas.
class LogAktivitasPage extends ConsumerStatefulWidget {
  const LogAktivitasPage({super.key});

  @override
  ConsumerState<LogAktivitasPage> createState() => _LogAktivitasPageState();
}

class _LogAktivitasPageState extends ConsumerState<LogAktivitasPage> {
  // Filter disimpan sebagai key (bukan label localized)
  // supaya pencarian & kategori konsisten lintas bahasa.
  String _selectedFilterKey = 'all';

  final List<String> _filterKeys = [
    'all',
    'students',
    'transactions',
    'digital_account',
    'payment',
    // 'login_logout',
    'system',
  ];

  String _searchQuery = '';

  Stream<QuerySnapshot<Map<String, dynamic>>> _getLogStream() {
    // Tidak memakai limit agar halaman benar-benar merekap seluruh log.
    return FirebaseFirestore.instance
        .collection('log_aktivitas')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ============================================================
  // SOUND
  // ============================================================

  void _playClick() {
    SoundHelper().playClick();
  }

  // ============================================================
  // COLOR BY ACTION
  // ============================================================

  Color _logColor(ActivityAction action, Color accentColor) {
    switch (action) {
      case ActivityAction.tambah:
        return AppColors.success;
      case ActivityAction.edit:
        return AppColors.warning;
      case ActivityAction.hapus:
        return AppColors.error;
      case ActivityAction.login:
        return accentColor;
      case ActivityAction.logout:
        return AppColors.textSecondary;
      case ActivityAction.bayar:
        return accentColor;
    }
  }

  // ============================================================
  // CATEGORY KEY (lintas bahasa)
  // ============================================================

  String _getCategoryKey(ActivityLog log) {
    final detail = log.detail.toLowerCase();
    final action = log.action;

    if (action == ActivityAction.bayar) {
      return 'payment';
    }

    if (action == ActivityAction.login || action == ActivityAction.logout) {
      return 'login_logout';
    }

    if (detail.contains('siswa') ||
        detail.contains('guru') ||
        detail.contains('kenaikan kelas') ||
        detail.contains('arsip siswa')) {
      return 'students';
    }

    if (detail.contains('pemasukan') ||
        detail.contains('pengeluaran') ||
        detail.contains('transaksi') ||
        detail.contains('arsip transaksi')) {
      return 'transactions';
    }

    if (detail.contains('akun digital') ||
        detail.contains('akun pengguna') ||
        detail.contains('akun')) {
      return 'digital_account';
    }

    if (detail.contains('pembayaran') ||
        detail.contains('spp') ||
        detail.contains('gedung')) {
      return 'payment';
    }

    return 'system';
  }

  String _categoryLabel(String key, Translations t) {
    switch (key) {
      case 'all':
        return t.t('cat_all');
      case 'students':
        return t.t('cat_students');
      case 'transactions':
        return t.t('cat_transactions');
      case 'digital_account':
        return t.t('cat_digital_account');
      case 'payment':
        return t.t('cat_payment');
      case 'login_logout':
        return t.t('cat_login_logout');
      case 'system':
        return t.t('cat_system');
      default:
        return key;
    }
  }

  bool _matchesFilter(ActivityLog log) {
    if (_selectedFilterKey == 'all') return true;
    return _getCategoryKey(log) == _selectedFilterKey;
  }

  bool _matchesSearch(ActivityLog log, Translations t) {
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery.toLowerCase().trim();

    final categoryLabel =
        _categoryLabel(_getCategoryKey(log), t).toLowerCase();

    return log.user.toLowerCase().contains(query) ||
        log.actionText.toLowerCase().contains(query) ||
        log.detail.toLowerCase().contains(query) ||
        categoryLabel.contains(query);
  }

  // ============================================================
  // TIMESTAMP
  // ============================================================

  String _formatTimestamp(DateTime timestamp, Translations t) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.isNegative) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} '
          '${timestamp.hour.toString().padLeft(2, '0')}:'
          '${timestamp.minute.toString().padLeft(2, '0')}';
    }

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} '
          '${timestamp.hour.toString().padLeft(2, '0')}:'
          '${timestamp.minute.toString().padLeft(2, '0')}';
    }

    if (difference.inDays > 0) {
      return t
          .t('days_ago')
          .replaceAll('{days}', '${difference.inDays}');
    }

    if (difference.inHours > 0) {
      return t
          .t('hours_ago')
          .replaceAll('{hours}', '${difference.inHours}');
    }

    if (difference.inMinutes > 0) {
      return t
          .t('minutes_ago')
          .replaceAll('{minutes}', '${difference.inMinutes}');
    }

    return t.t('just_now');
  }

  // ============================================================
  // HELPERS FOR TEXT COLOR BY THEME
  // ============================================================

  Color _primaryTextColor(AppThemeMode themeMode, ColorScheme colors) {
    if (ThemeHelper.isGlass(themeMode)) return AppColors.glassTextPrimary;
    if (ThemeHelper.isAurora(themeMode)) return AppColors.auroraTextPrimary;
    if (ThemeHelper.isCyber(themeMode)) return AppColors.cyberTextPrimary;
    return colors.onSurface;
  }

  Color _secondaryTextColor(AppThemeMode themeMode) {
    if (ThemeHelper.isGlass(themeMode)) return AppColors.glassTextSecondary;
    if (ThemeHelper.isAurora(themeMode)) return AppColors.auroraTextSecondary;
    if (ThemeHelper.isCyber(themeMode)) return AppColors.cyberTextSecondary;
    return AppColors.textSecondary;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final translations = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accentColor = ThemeHelper.getAccentColor(themeMode, colors);

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _playClick();
              Navigator.pop(context);
            },
          ),
          title: Text(translations.t('log_activity_title')),
        ),
        body: Column(
          children: [
            // ==================================================
            // FILTER + SEARCH (THEMED SECTION GROUP)
            // ==================================================
            ScrollReveal(
              delay: const Duration(milliseconds: 50),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: ThemeHelper.buildSectionGroup(
                  themeMode,
                  [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list_outlined,
                            color: accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            translations.t('category'),
                            style: theme.textTheme.titleMedium,
                          ),
                          const Spacer(),
                          DropdownButton<String>(
                            value: _selectedFilterKey,
                            underline: const SizedBox(),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            items: _filterKeys.map((key) {
                              return DropdownMenuItem<String>(
                                value: key,
                                child: Text(_categoryLabel(key, translations)),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue == null) return;
                              _playClick();
                              setState(() {
                                _selectedFilterKey = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: ThemeHelper.dividerColor(themeMode),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: translations.t('search_activity_hint'),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ==================================================
            // STREAM BUILDER
            // ==================================================
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getLogStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '${translations.t('log_read_error')}:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _secondaryTextColor(themeMode),
                          ),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        translations.t('no_activity_logs'),
                        style: TextStyle(
                          fontSize: 16,
                          color: _secondaryTextColor(themeMode),
                        ),
                      ),
                    );
                  }

                  final allLogs = snapshot.data!.docs
                      .map((doc) => ActivityLog.fromMap(doc.data()))
                      .toList();

                  final filteredLogs = allLogs.where((log) {
                    return _matchesFilter(log) &&
                        _matchesSearch(log, translations);
                  }).toList();

                  if (filteredLogs.isEmpty) {
                    return Center(
                      child: Text(
                        translations.t('no_matching_logs'),
                        style: TextStyle(
                          fontSize: 16,
                          color: _secondaryTextColor(themeMode),
                        ),
                      ),
                    );
                  }

                  final countText = translations
                      .t('showing_count')
                      .replaceAll('{shown}', '${filteredLogs.length}')
                      .replaceAll('{total}', '${allLogs.length}');

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            countText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _secondaryTextColor(themeMode),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredLogs.length,
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          itemBuilder: (context, index) {
                            final log = filteredLogs[index];
                            final logColor = _logColor(log.action, accentColor);
                            final catKey = _getCategoryKey(log);
                            final catLabel =
                                _categoryLabel(catKey, translations);

                            // Stagger reveal per item (capped).
                            final delay = Duration(
                              milliseconds: 80 + (index.clamp(0, 8) * 40),
                            );

                            return ScrollReveal(
                              delay: delay,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                child: _buildLogCard(
                                  log: log,
                                  logColor: logColor,
                                  categoryLabel: catLabel,
                                  themeMode: themeMode,
                                  translations: translations,
                                  theme: theme,
                                  colors: colors,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOG CARD (PER-THEME)
  // ============================================================

  Widget _buildLogCard({
    required ActivityLog log,
    required Color logColor,
    required String categoryLabel,
    required AppThemeMode themeMode,
    required Translations translations,
    required ThemeData theme,
    required ColorScheme colors,
  }) {
    if (ThemeHelper.isNeo(themeMode)) {
      return Container(
        decoration: neumorphismDecoration(
          borderRadius: 18,
          isPressed: false,
        ),
        child: _buildCardContent(
          log: log,
          logColor: logColor,
          categoryLabel: categoryLabel,
          themeMode: themeMode,
          translations: translations,
          theme: theme,
          colors: colors,
        ),
      );
    }

    if (ThemeHelper.isGlass(themeMode)) {
      return Container(
        decoration: glassmorphismDecoration(borderRadius: 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: _buildCardContent(
              log: log,
              logColor: logColor,
              categoryLabel: categoryLabel,
              themeMode: themeMode,
              translations: translations,
              theme: theme,
              colors: colors,
            ),
          ),
        ),
      );
    }

    if (ThemeHelper.isModern(themeMode)) {
      return Container(
        decoration: modernDecoration(borderRadius: 18),
        child: _buildCardContent(
          log: log,
          logColor: logColor,
          categoryLabel: categoryLabel,
          themeMode: themeMode,
          translations: translations,
          theme: theme,
          colors: colors,
        ),
      );
    }

    if (ThemeHelper.isAurora(themeMode)) {
      return Container(
        decoration: auroraDecoration(borderRadius: 18),
        child: _buildCardContent(
          log: log,
          logColor: logColor,
          categoryLabel: categoryLabel,
          themeMode: themeMode,
          translations: translations,
          theme: theme,
          colors: colors,
        ),
      );
    }

    if (ThemeHelper.isCyber(themeMode)) {
      return Container(
        decoration: cyberpunkDecoration(borderRadius: 10),
        child: _buildCardContent(
          log: log,
          logColor: logColor,
          categoryLabel: categoryLabel,
          themeMode: themeMode,
          translations: translations,
          theme: theme,
          colors: colors,
        ),
      );
    }

    // Default Material
    return Card(
      margin: EdgeInsets.zero,
      child: _buildCardContent(
        log: log,
        logColor: logColor,
        categoryLabel: categoryLabel,
        themeMode: themeMode,
        translations: translations,
        theme: theme,
        colors: colors,
      ),
    );
  }

  // ============================================================
  // LOG CARD CONTENT
  // ============================================================

  Widget _buildCardContent({
    required ActivityLog log,
    required Color logColor,
    required String categoryLabel,
    required AppThemeMode themeMode,
    required Translations translations,
    required ThemeData theme,
    required ColorScheme colors,
  }) {
    final textPrimary = _primaryTextColor(themeMode, colors);
    final textSecondary = _secondaryTextColor(themeMode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leading avatar
          CircleAvatar(
            backgroundColor: logColor.withValues(alpha: 0.15),
            child: Icon(
              log.actionIcon,
              color: logColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + category badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.actionText,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: logColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: logColor.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        categoryLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: logColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  log.detail,
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_outline,
                            size: 12, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          log.user,
                          style: TextStyle(
                              fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time,
                            size: 12, color: textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(log.timestamp, translations),
                          style: TextStyle(
                              fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}