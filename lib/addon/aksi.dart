// lib/addon/aksi.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/appearance.dart';
import '../data.dart';
import '../firebase/firestore_service.dart';
import '../helpers/sound_helper.dart';
import '../helpers/theme_helper.dart';
import '../features/ai_assistant.dart';
import '../simulation/FAB_helper.dart';
import '../l10n/translations.dart';

class AksiHelper {
  // -------- Callback refresh untuk dashboard --------
  static VoidCallback? _refreshCallback;

  static void setRefreshCallback(VoidCallback? callback) {
    _refreshCallback = callback;
  }

  // ============================================================
  // ======================= MENU FAB ===========================
  // ============================================================

  static void showFABMenu(BuildContext parentContext, VoidCallback onUpdate) {
    if (!parentContext.mounted) return;

    final translations = ProviderScope.containerOf(
      parentContext,
    ).read(translationsProvider);

    final themeMode = ProviderScope.containerOf(
      parentContext,
    ).read(themeModeProvider);

    final colors = Theme.of(parentContext).colorScheme;

    final accentColor = ThemeHelper.getAccentColor(themeMode, colors);

    final bool isGlass = ThemeHelper.isGlass(themeMode);
    final bool isNeo = ThemeHelper.isNeo(themeMode);

    // ------------------------------------------------------------
    // BACKGROUND BOTTOM SHEET
    // ------------------------------------------------------------

    final Color sheetBackground = isGlass
        ? AppColors.glassBg1
        : isNeo
        ? AppColors.neoBase
        : colors.surface;

    // ------------------------------------------------------------
    // TEXT
    // ------------------------------------------------------------

    final Color primaryText = isGlass
        ? Colors.white
        : isNeo
        ? AppColors.neoTextPrimary
        : colors.onSurface;

    final Color handleColor = isGlass
        ? Colors.white.withValues(alpha: 0.7)
        : isNeo
        ? AppColors.neoShadow
        : colors.onSurfaceVariant.withValues(alpha: 0.4);

    showModalBottomSheet(
      context: parentContext,
      backgroundColor: sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HANDLE
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 20),

                // TITLE
                Text(
                  translations.t('quick_menu'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),

                const SizedBox(height: 20),

                // ACTIONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // ================= TAMBAH TRANSAKSI =================
                    _buildQuickAction(
                      icon: Icons.add_card,
                      label: translations.t('add_transaction'),
                      accentColor: accentColor,
                      textColor: primaryText,
                      isGlass: isGlass,
                      onTap: () {
                        SoundHelper().playClick();

                        Navigator.of(sheetContext).pop();

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!parentContext.mounted) return;
                          showAddTransactionDialog(parentContext, onUpdate);
                        });
                      },
                    ),

                    // ================= KALKULATOR =================
                    _buildQuickAction(
                      icon: Icons.calculate,
                      label: translations.t('calculator'),
                      accentColor: accentColor,
                      textColor: primaryText,
                      isGlass: isGlass,
                      onTap: () {
                        SoundHelper().playClick();
                        Navigator.of(sheetContext).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!parentContext.mounted) return;
                          showCalculatorDialog(parentContext);
                        });
                      },
                    ),

                    // ================= SIMULASI =================
                    // Saat ditekan, akan otomatis mengarsipkan
                    // transaksi bulan ini ke Firebase terlebih
                    // dahulu, baru kemudian menampilkan dialog
                    // simulasi pergantian bulan.
                    _buildQuickAction(
                      icon: Icons.developer_mode,
                      label: translations.t('simulation_data'),
                      accentColor: accentColor,
                      textColor: primaryText,
                      isGlass: isGlass,
                      onTap: () async {
                        SoundHelper().playClick();

                        Navigator.of(sheetContext).pop();

                        // ===== ARSIPKAN TRANSAKSI BULAN INI KE FIREBASE =====
                        // Sebelum simulasi pergantian bulan, simpan
                        // terlebih dahulu transaksi bulan ini ke koleksi
                        // archived_transactions agar dapat dibandingkan
                        // di laporan.dart.
                        try {
                          await archiveCurrentMonthData();
                        } catch (e) {
                          debugPrint('Archive error: $e');
                        }

                        // ===== TAMPILKAN DIALOG SIMULASI =====
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!parentContext.mounted) return;

                          SimulasiHelper.showSimulationDialog(
                            parentContext,
                            onUpdate,
                            _refreshCallback,
                          );
                        });
                      },
                    ),

                    // ================= AI =================
                    _buildQuickAction(
                      icon: Icons.auto_awesome,
                      label: translations.t('ai_assistant'),
                      accentColor: accentColor,
                      textColor: primaryText,
                      isGlass: isGlass,
                      onTap: () {
                        SoundHelper().playClick();
                        Navigator.of(sheetContext).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!parentContext.mounted) return;
                          Navigator.of(parentContext).push(
                            MaterialPageRoute(
                              builder: (_) => const AIAssistantPage(),
                            ),
                          );
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ===================== QUICK ACTION =========================
  // ============================================================

  static Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color accentColor,
    required Color textColor,
    required bool isGlass,
    required VoidCallback onTap,
  }) {
    final Color circleBackground = isGlass
        ? Colors.white.withValues(alpha: 0.18)
        : accentColor.withValues(alpha: 0.10);

    final Color iconColor = isGlass ? Colors.white : accentColor;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: circleBackground,
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ================== TAMBAH TRANSAKSI ========================
  // ============================================================

  static void showAddTransactionDialog(
    BuildContext parentContext,
    VoidCallback onUpdate,
  ) {
    if (!parentContext.mounted) return;

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return _AddTransactionDialog(
          onUpdate: onUpdate,
          onRefresh: _refreshCallback,
        );
      },
    );
  }

  // ============================================================
  // ================== KALKULATOR ==============================
  // ============================================================

  static void showCalculatorDialog(BuildContext parentContext) {
    if (!parentContext.mounted) return;
    showDialog(
      context: parentContext,
      builder: (_) => const CalculatorDialog(),
    );
  }
}

// ============================================================
// ============ STATEFUL WIDGET UNTUK DIALOG TRANSAKSI =========
// ============================================================

class _AddTransactionDialog extends StatefulWidget {
  final VoidCallback onUpdate;
  final VoidCallback? onRefresh;

  const _AddTransactionDialog({required this.onUpdate, this.onRefresh});

  @override
  State<_AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<_AddTransactionDialog> {
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  TransType _selectedType = TransType.pemasukan;
  bool _isSaving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    SoundHelper().playClick();

    if (_descCtrl.text.trim().isEmpty || _amountCtrl.text.trim().isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final description = _descCtrl.text.trim();
    final now = DateTime.now();

    final newTransaction = Transaction(
      id: 'TRX${now.millisecondsSinceEpoch}',
      type: _selectedType,
      amount: amount,
      description: description,
      date: now,
      category: _selectedType == TransType.pemasukan
          ? 'Pemasukan'
          : 'Pengeluaran',
    );

    final newLog = ActivityLog(
      user: 'Admin',
      action: ActivityAction.tambah,
      detail: 'Tambah transaksi $description',
      timestamp: now,
    );

    try {
      await addTransaction(newTransaction);
      await addActivityLog(newLog);

      localTransactions.insert(0, newTransaction);
      localLogs.insert(0, newLog);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onUpdate();
        widget.onRefresh?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);

        final translations = ProviderScope.containerOf(
          context,
        ).read(translationsProvider);

        final colors = Theme.of(context).colorScheme;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${translations.t('failed_add_transaction')}: $e'),
            backgroundColor: colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = ProviderScope.containerOf(
      context,
    ).read(translationsProvider);

    final themeMode = ProviderScope.containerOf(
      context,
    ).read(themeModeProvider);

    final colors = Theme.of(context).colorScheme;

    final bool isGlass = ThemeHelper.isGlass(themeMode);
    final bool isNeo = ThemeHelper.isNeo(themeMode);

    final Color accentColor = ThemeHelper.getAccentColor(themeMode, colors);

    final Color dialogBackground = isGlass
        ? AppColors.glassBg1
        : isNeo
        ? AppColors.neoBase
        : colors.surface;

    final Color primaryText = isGlass
        ? Colors.white
        : isNeo
        ? AppColors.neoTextPrimary
        : colors.onSurface;

    final Color secondaryText = isGlass
        ? AppColors.glassTextSecondary
        : isNeo
        ? AppColors.neoTextSecondary
        : colors.onSurfaceVariant;

    return AlertDialog(
      backgroundColor: dialogBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        translations.t('add_transaction'),
        style: TextStyle(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<TransType>(
            value: _selectedType,
            dropdownColor: dialogBackground,
            style: TextStyle(color: primaryText),
            iconEnabledColor: primaryText,
            items: [
              DropdownMenuItem(
                value: TransType.pemasukan,
                child: Text(translations.t('income')),
              ),
              DropdownMenuItem(
                value: TransType.pengeluaran,
                child: Text(translations.t('expense')),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedType = value);
            },
            decoration: InputDecoration(
              labelText: translations.t('transaction_type'),
              labelStyle: TextStyle(color: secondaryText),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isGlass
                      ? Colors.white.withValues(alpha: 0.3)
                      : isNeo
                      ? AppColors.neoShadow.withValues(alpha: 0.25)
                      : colors.outlineVariant,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            style: TextStyle(color: primaryText),
            decoration: InputDecoration(
              labelText: translations.t('description'),
              labelStyle: TextStyle(color: secondaryText),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isGlass
                      ? Colors.white.withValues(alpha: 0.3)
                      : isNeo
                      ? AppColors.neoShadow.withValues(alpha: 0.25)
                      : colors.outlineVariant,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(color: primaryText),
            decoration: InputDecoration(
              labelText: translations.t('amount_rupiah'),
              labelStyle: TextStyle(color: secondaryText),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isGlass
                      ? Colors.white.withValues(alpha: 0.3)
                      : isNeo
                      ? AppColors.neoShadow.withValues(alpha: 0.25)
                      : colors.outlineVariant,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  SoundHelper().playClick();
                  Navigator.of(context).pop();
                },
          child: Text(
            translations.t('cancel'),
            style: TextStyle(color: isGlass ? Colors.white : accentColor),
          ),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveTransaction,
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: isGlass ? AppColors.glassBg1 : colors.onPrimary,
          ),
          child: _isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: isGlass ? AppColors.glassBg1 : colors.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : Text(translations.t('save')),
        ),
      ],
    );
  }
}

// ============================================================
// ================== KALKULATOR DIALOG =======================
// ============================================================

class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _display = '0';
  String _expression = '';
  String _operator = '';
  double _firstOperand = 0;
  bool _newNumber = true;
  bool _isResult = false;

  void _pressDigit(String digit) {
    SoundHelper().playClick();
    setState(() {
      if (_isResult) {
        _display = digit;
        _expression = '';
        _isResult = false;
        _newNumber = false;
        return;
      }
      if (digit == '.' && _display.contains('.')) return;
      if (_newNumber) {
        _display = digit == '.' ? '0.' : digit;
        _newNumber = false;
      } else {
        if (_display.length < 15) _display += digit;
      }
    });
  }

  void _pressOperator(String op) {
    SoundHelper().playClick();
    if (_operator.isNotEmpty && !_newNumber) _calculateResult();
    setState(() {
      _firstOperand = double.tryParse(_display) ?? 0;
      _operator = op;
      _expression = '$_display $op ';
      _newNumber = true;
      _isResult = false;
    });
  }

  void _calculateResult() {
    final second = double.tryParse(_display) ?? 0;
    double result = 0;
    String resultStr = '';

    switch (_operator) {
      case '+':
        result = _firstOperand + second;
        resultStr = '${_firstOperand.toStringAsFixed(0)} + ${second.toStringAsFixed(0)} =';
        break;
      case '-':
        result = _firstOperand - second;
        resultStr = '${_firstOperand.toStringAsFixed(0)} - ${second.toStringAsFixed(0)} =';
        break;
      case '×':
        result = _firstOperand * second;
        resultStr = '${_firstOperand.toStringAsFixed(0)} × ${second.toStringAsFixed(0)} =';
        break;
      case '÷':
        if (second == 0) {
          setState(() {
            _display = 'Error';
            _operator = '';
            _newNumber = true;
            _isResult = true;
          });
          return;
        }
        result = _firstOperand / second;
        resultStr = '${_firstOperand.toStringAsFixed(0)} ÷ ${second.toStringAsFixed(0)} =';
        break;
      default:
        return;
    }

    String displayResult = result.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    if (displayResult.length > 15) {
      displayResult = result.toStringAsExponential(2);
    }

    setState(() {
      _display = displayResult;
      _expression = resultStr;
      _operator = '';
      _newNumber = true;
      _isResult = true;
    });
  }

  void _pressEquals() {
    if (_operator.isEmpty) return;
    SoundHelper().playClick();
    _calculateResult();
  }

  void _pressClear() {
    SoundHelper().playClick();
    setState(() {
      _display = '0';
      _expression = '';
      _operator = '';
      _firstOperand = 0;
      _newNumber = true;
      _isResult = false;
    });
  }

  void _pressDelete() {
    SoundHelper().playClick();
    if (_isResult) {
      _pressClear();
      return;
    }
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
        _newNumber = true;
      }
    });
  }

  void _pressPercent() {
    SoundHelper().playClick();
    setState(() {
      final value = double.tryParse(_display) ?? 0;
      final result = value / 100;
      _display = result.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
      _isResult = true;
    });
  }

  void _pressPlusMinus() {
    SoundHelper().playClick();
    setState(() {
      final value = double.tryParse(_display) ?? 0;
      final result = value * -1;
      _display = result.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final translations = ProviderScope.containerOf(context).read(translationsProvider);
    final themeMode = ProviderScope.containerOf(context).read(themeModeProvider);
    final colors = Theme.of(context).colorScheme;

    final bool isGlass = ThemeHelper.isGlass(themeMode);
    final bool isNeo = ThemeHelper.isNeo(themeMode);

    final Color accentColor = ThemeHelper.getAccentColor(themeMode, colors);

    final Color dialogBackground = isGlass
        ? AppColors.glassBg1
        : isNeo
        ? AppColors.neoBase
        : colors.surface;

    final Color primaryText = isGlass
        ? Colors.white
        : isNeo
        ? AppColors.neoTextPrimary
        : colors.onSurface;

    final Color secondaryText = isGlass
        ? AppColors.glassTextSecondary
        : isNeo
        ? AppColors.neoTextSecondary
        : colors.onSurfaceVariant;

    final Color displayBackground = isGlass
        ? Colors.white.withValues(alpha: 0.12)
        : isNeo
        ? Color.lerp(AppColors.neoBase, AppColors.neoHighlight, 0.08)!
        : colors.surfaceContainerHighest;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: dialogBackground,
      surfaceTintColor: Colors.transparent,
      elevation: isGlass || isNeo ? 0 : 8,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        decoration: isGlass
            ? glassmorphismDecoration(borderRadius: 20)
            : isNeo
            ? neumorphismDecoration(borderRadius: 20, isPressed: false)
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  translations.t('calculator'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: secondaryText),
                  onPressed: () {
                    SoundHelper().playClick();
                    Navigator.of(context).pop();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: displayBackground,
                gradient: isGlass
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.white.withValues(alpha: 0.07),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isGlass
                      ? Colors.white.withValues(alpha: 0.25)
                      : isNeo
                      ? AppColors.neoShadow.withValues(alpha: 0.25)
                      : colors.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_expression.isNotEmpty)
                    Text(
                      _expression,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryText,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _display,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _display == 'Error' ? AppColors.error : primaryText,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    _calcButton('AC', _pressClear,
                        color: _getFunctionButtonColor(themeMode, colors),
                        textColor: primaryText),
                    _calcButton('⌫', _pressDelete,
                        color: _getFunctionButtonColor(themeMode, colors),
                        textColor: primaryText),
                    _calcButton('%', _pressPercent,
                        color: _getFunctionButtonColor(themeMode, colors),
                        textColor: primaryText),
                    _calcButton('÷', () => _pressOperator('÷'),
                        color: accentColor,
                        textColor: isGlass ? AppColors.glassBg1 : colors.onPrimary),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _calcButton('7', () => _pressDigit('7'),
                        textColor: primaryText,
                        buttonColor: dialogBackground,
                        borderColor: secondaryText.withValues(alpha: 0.2)),
                    _calcButton('8', () => _pressDigit('8'),
                        textColor: primaryText,
                        buttonColor: dialogBackground,
                        borderColor: secondaryText.withValues(alpha: 0.2)),
                    _calcButton('9', () => _pressDigit('9'),
                        textColor: primaryText,
                        buttonColor: dialogBackground,
                        borderColor: secondaryText.withValues(alpha: 0.2)),
                    _calcButton('×', () => _pressOperator('×'),
                        color: accentColor,
                        textColor: isGlass ? AppColors.glassBg1 : colors.onPrimary),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _calcButton('4', () => _pressDigit('4'),
                        textColor: primaryText,
                        buttonColor: dialogBackground,
                        borderColor: secondaryText.withValues(alpha: 0.2)),
                    _calcButton('5', () => _pressDigit('5'),
                        textColor: primaryText,
                        buttonColor: dialogBackground,
                        borderColor: secondaryText.withValues(alpha: 0.2)),
                    _calcButton('6', () => _pressDigit('6'),
                        textColor: primaryText,
                        buttonColor: dialogBackground,
                        borderColor: secondaryText.withValues(alpha: 0.2)),
                    _calcButton('-', () => _pressOperator('-'),
                        color: accentColor,
                        textColor: isGlass ? AppColors.glassBg1 : colors.onPrimary),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _calcButton('1', () => _pressDigit('1'),
                        textColor: primaryText,
                        buttonColor: dialogBackground,
                        borderColor: secondaryText.withValues(alpha: 0.2)),
                    _calcButton('2', () => _pressDigit('2'),
                        textColor: primaryText,
                        buttonColor: dialogBackground,
                        borderColor: secondaryText.withValues(alpha: 0.2)),
                    _calcButton('3', () => _pressDigit('3'),
                        textColor: primaryText,
                        buttonColor: dialogBackground,
                        borderColor: secondaryText.withValues(alpha: 0.2)),
                    _calcButton('+', () => _pressOperator('+'),
                        color: accentColor,
                        textColor: isGlass ? AppColors.glassBg1 : colors.onPrimary),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _calcButton('0', () => _pressDigit('0'),
                        flex: 2,
                        textColor: primaryText,
                        buttonColor: dialogBackground,
                        borderColor: secondaryText.withValues(alpha: 0.2)),
                    _calcButton('.', () => _pressDigit('.'),
                        textColor: primaryText,
                        buttonColor: dialogBackground,
                        borderColor: secondaryText.withValues(alpha: 0.2)),
                    _calcButton('±', _pressPlusMinus,
                        textColor: primaryText,
                        buttonColor: dialogBackground,
                        borderColor: secondaryText.withValues(alpha: 0.2)),
                    _calcButton('=', _pressEquals,
                        color: accentColor,
                        textColor: isGlass ? AppColors.glassBg1 : colors.onPrimary),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getFunctionButtonColor(AppThemeMode themeMode, ColorScheme colors) {
    if (ThemeHelper.isGlass(themeMode)) {
      return Colors.white.withValues(alpha: 0.16);
    }
    if (ThemeHelper.isNeo(themeMode)) {
      return Color.lerp(AppColors.neoBase, AppColors.neoShadow, 0.05)!;
    }
    return colors.surfaceContainerHighest;
  }

  Widget _calcButton(
    String label,
    VoidCallback onTap, {
    Color? color,
    Color? textColor,
    int flex = 1,
    Color? buttonColor,
    Color? borderColor,
  }) {
    final themeMode = ProviderScope.containerOf(context).read(themeModeProvider);
    final colors = Theme.of(context).colorScheme;

    final bool isOperator =
        color != null && color == ThemeHelper.getAccentColor(themeMode, colors);
    final bool isFunction = color != null && !isOperator;
    final bool isGlass = ThemeHelper.isGlass(themeMode);
    final bool isNeo = ThemeHelper.isNeo(themeMode);

    final Color background = color ??
        buttonColor ??
        (isGlass
            ? Colors.white.withValues(alpha: 0.08)
            : isNeo
            ? AppColors.neoBase
            : colors.surface);

    final Color effectiveText = textColor ??
        (isOperator
            ? (isGlass ? AppColors.glassBg1 : colors.onPrimary)
            : isGlass
            ? Colors.white
            : isNeo
            ? AppColors.neoTextPrimary
            : colors.onSurface);

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(12),
          elevation: isOperator || isFunction
              ? 0
              : isNeo
              ? 0
              : 1,
          shadowColor: isGlass
              ? Colors.black.withValues(alpha: 0.12)
              : isNeo
              ? AppColors.neoShadow.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.05),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: isOperator
                ? Colors.white.withValues(alpha: 0.25)
                : ThemeHelper.getAccentColor(themeMode, colors).withValues(alpha: 0.10),
            highlightColor: isOperator
                ? Colors.white.withValues(alpha: 0.15)
                : isNeo
                ? AppColors.neoShadow.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: borderColor != null
                    ? Border.all(color: borderColor, width: 1)
                    : null,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: isOperator ? FontWeight.bold : FontWeight.w500,
                  color: effectiveText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}