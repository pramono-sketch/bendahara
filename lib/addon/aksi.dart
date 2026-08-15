// addon/aksi.dart
import 'package:flutter/material.dart';

import '../constants/appearance.dart'; // 🔥 import warna
import '../data.dart';
import '../templates/sound_helper.dart';
import '../features/ai_assistant.dart'; // 🔥 Import halaman AI

class AksiHelper {
  // -------- Callback refresh untuk dashboard --------
  static VoidCallback? _refreshCallback;

  static void setRefreshCallback(VoidCallback? callback) {
    _refreshCallback = callback;
  }

  // -------- Menu FAB (dengan tombol AI) --------
  static void showFABMenu(BuildContext context, VoidCallback onUpdate) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Menu Cepat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(
                  icon: Icons.add_card,
                  label: 'Tambah\nTransaksi',
                  onTap: () {
                    SoundHelper().playClick();
                    Navigator.pop(context);
                    showAddTransactionDialog(context, onUpdate);
                  },
                ),
                _buildQuickAction(
                  icon: Icons.calculate,
                  label: 'Kalkulator',
                  onTap: () {
                    SoundHelper().playClick();
                    Navigator.pop(context);
                    showCalculatorDialog(context);
                  },
                ),
                _buildQuickAction(
                  icon: Icons.document_scanner,
                  label: 'Scan\nBukti',
                  onTap: () {
                    SoundHelper().playClick();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur Scan Bukti dalam pengembangan'),
                      ),
                    );
                  },
                ),
                // 🔥 TOMBAI AI Assistant (baru)
                _buildQuickAction(
                  icon: Icons.auto_awesome,
                  label: 'AI\nAssistant',
                  onTap: () {
                    SoundHelper().playClick();
                    Navigator.pop(context);
                    // Navigasi ke halaman AI Assistant
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AIAssistantPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(icon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // -------- Dialog Tambah Transaksi --------
  static void showAddTransactionDialog(BuildContext context, VoidCallback onUpdate) {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    TransType selectedType = TransType.pemasukan;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Transaksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<TransType>(
              value: selectedType,
              items: const [
                DropdownMenuItem(
                  value: TransType.pemasukan,
                  child: Text('Pemasukan'),
                ),
                DropdownMenuItem(
                  value: TransType.pengeluaran,
                  child: Text('Pengeluaran'),
                ),
              ],
              onChanged: (val) {
                if (val != null) selectedType = val;
              },
              decoration: const InputDecoration(labelText: 'Jenis'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              SoundHelper().playClick();
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              SoundHelper().playClick();
              if (descCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                dummyTransactions.insert(
                  0,
                  Transaction(
                    id: 'TRX${dummyTransactions.length + 1}',
                    type: selectedType,
                    amount: amount,
                    description: descCtrl.text,
                    date: DateTime.now(),
                  ),
                );
                dummyLogs.insert(
                  0,
                  ActivityLog(
                    user: 'Admin',
                    action: ActivityAction.tambah,
                    detail: 'Tambah transaksi ${descCtrl.text}',
                    timestamp: DateTime.now(),
                  ),
                );
                onUpdate();
                _refreshCallback?.call();
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // -------- Kalkulator --------
  static void showCalculatorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CalculatorDialog(),
    );
  }
}

// ================== KALKULATOR DIALOG ==================
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
      if (_newNumber) {
        _display = digit;
        _newNumber = false;
      } else {
        if (_display.length < 15) {
          _display += digit;
        }
      }
    });
  }

  void _pressOperator(String op) {
    SoundHelper().playClick();
    setState(() {
      if (_operator.isNotEmpty && !_newNumber) {
        _calculateResult();
      }
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
          _display = 'Error';
          _operator = '';
          _newNumber = true;
          _isResult = true;
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
    setState(() {
      if (_isResult) {
        _pressClear();
        return;
      }
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      elevation: 8,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kalkulator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    SoundHelper().playClick();
                    Navigator.pop(context);
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surface,
                    Colors.grey.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
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
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _display,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _display == 'Error' ? AppColors.error : AppColors.textPrimary,
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
                    _calcButton('AC', _pressClear, color: Colors.grey.shade200, textColor: AppColors.textPrimary),
                    _calcButton('⌫', _pressDelete, color: Colors.grey.shade200, textColor: AppColors.textPrimary),
                    _calcButton('%', _pressPercent, color: Colors.grey.shade200, textColor: AppColors.textPrimary),
                    _calcButton('÷', () => _pressOperator('÷'), color: AppColors.primary, textColor: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _calcButton('7', () => _pressDigit('7')),
                    _calcButton('8', () => _pressDigit('8')),
                    _calcButton('9', () => _pressDigit('9')),
                    _calcButton('×', () => _pressOperator('×'), color: AppColors.primary, textColor: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _calcButton('4', () => _pressDigit('4')),
                    _calcButton('5', () => _pressDigit('5')),
                    _calcButton('6', () => _pressDigit('6')),
                    _calcButton('-', () => _pressOperator('-'), color: AppColors.primary, textColor: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _calcButton('1', () => _pressDigit('1')),
                    _calcButton('2', () => _pressDigit('2')),
                    _calcButton('3', () => _pressDigit('3')),
                    _calcButton('+', () => _pressOperator('+'), color: AppColors.primary, textColor: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _calcButton('0', () => _pressDigit('0'), flex: 2),
                    _calcButton('.', () => _pressDigit('.')),
                    _calcButton('±', _pressPlusMinus),
                    _calcButton('=', _pressEquals, color: AppColors.primary, textColor: Colors.white),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _calcButton(
    String label,
    VoidCallback onTap, {
    Color? color,
    Color? textColor,
    int flex = 1,
  }) {
    final bool isOperator = color == AppColors.primary;
    final bool isFunction = color == Colors.grey.shade200;
    
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Material(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: isOperator || isFunction ? 0 : 1,
          shadowColor: Colors.black.withOpacity(0.05),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: isOperator ? Colors.white.withOpacity(0.3) : AppColors.primary.withOpacity(0.1),
            highlightColor: isOperator ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isFunction || isOperator ? null : Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: isOperator ? FontWeight.bold : FontWeight.w500,
                  color: textColor ?? AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}