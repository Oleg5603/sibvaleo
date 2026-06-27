import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/activation.dart';

class CodeGeneratorScreen extends StatefulWidget {
  const CodeGeneratorScreen({super.key});

  @override
  State<CodeGeneratorScreen> createState() => _CodeGeneratorScreenState();
}

class _CodeGeneratorScreenState extends State<CodeGeneratorScreen> {
  final _ctrl = TextEditingController(text: '1');
  int _client = 1;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _copy(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Скопировано: $code'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pair = Activation.generatePair(_client);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Генератор кодов активации'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                'Формат кода: SVLnnn-mmmmm\n'
                'Каждому клиенту — два кода:\n'
                '  Слот 1 — ПК / Windows\n'
                '  Слот 2 — Смартфон / Android/iOS\n\n'
                'Один код работает на одном устройстве навсегда.',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),

            // Client number input
            const Text('Номер клиента', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '1 — 999',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 1;
                      setState(() => _client = n.clamp(1, 999));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    _stepBtn(Icons.remove, () {
                      if (_client > 1) {
                        setState(() => _client--);
                        _ctrl.text = _client.toString();
                      }
                    }),
                    const SizedBox(width: 4),
                    _stepBtn(Icons.add, () {
                      if (_client < 999) {
                        setState(() => _client++);
                        _ctrl.text = _client.toString();
                      }
                    }),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            const Text('Коды активации', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            _codeCard('Слот 1 — ПК / Windows', pair[0], Icons.computer, Colors.blue),
            const SizedBox(height: 12),
            _codeCard('Слот 2 — Смартфон', pair[1], Icons.phone_android, Colors.purple),

            const SizedBox(height: 24),
            // Copy both
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final both = 'Клиент #$_client\nПК:     ${pair[0]}\nТелефон: ${pair[1]}';
                  Clipboard.setData(ClipboardData(text: both));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Оба кода скопированы'), duration: Duration(seconds: 2)),
                  );
                },
                icon: const Icon(Icons.copy_all),
                label: const Text('Скопировать оба кода'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: Colors.grey.shade700),
        ),
      );

  Widget _codeCard(String label, String code, IconData icon, MaterialColor color) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color.shade600),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 13, color: color.shade700, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _copy(code),
                  icon: Icon(Icons.copy, color: color.shade600),
                  tooltip: 'Копировать',
                ),
              ],
            ),
          ],
        ),
      );
}
