import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../data/recommendation_engine.dart';
import '../utils/trial.dart';
import 'home_screen.dart';
import 'code_generator_screen.dart';

class TrialExpiredScreen extends StatefulWidget {
  final TrialStatus trial;
  final List<Product> products;
  final RecommendationEngine engine;
  const TrialExpiredScreen({
    super.key,
    required this.trial,
    required this.products,
    required this.engine,
  });

  @override
  State<TrialExpiredScreen> createState() => _TrialExpiredScreenState();
}

class _TrialExpiredScreenState extends State<TrialExpiredScreen> {
  int _logoTaps = 0;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  void _onLogoTap() {
    _logoTaps++;
    if (_logoTaps >= 5) {
      _logoTaps = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CodeGeneratorScreen()),
      );
    }
  }

  Future<void> _showActivationDialog() async {
    final ctrl = TextEditingController();
    String? error;
    bool loading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Активация полной версии'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Введите код активации,\nполученный от консультанта:',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'SVL001-62277',
                  labelText: 'Код активации',
                  errorText: error,
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                maxLength: 15,
                onSubmitted: (_) async {
                  setLocal(() { loading = true; error = null; });
                  final ok = await Trial.activate(ctrl.text);
                  if (!ctx.mounted) return;
                  if (ok) {
                    Navigator.pop(ctx, true);
                  } else {
                    setLocal(() { loading = false; error = 'Неверный код'; });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setLocal(() { loading = true; error = null; });
                      final ok = await Trial.activate(ctrl.text);
                      if (!ctx.mounted) return;
                      if (ok) {
                        Navigator.pop(ctx, true);
                      } else {
                        setLocal(() { loading = false; error = 'Неверный код. Проверьте правильность ввода.'; });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Активировать'),
            ),
          ],
        ),
      ),
    );

    // После закрытия диалога — проверяем, активировано ли
    if (!mounted) return;
    final newTrial = await Trial.check();
    if (!mounted) return;
    if (newTrial.isActivated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            products: widget.products,
            engine: widget.engine,
            trial: newTrial,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Логотип — 5 нажатий → генератор кодов (для консультанта)
                GestureDetector(
                  onTap: _onLogoTap,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.health_and_safety_outlined,
                        size: 52, color: Color(0xFF2E7D32)),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Sibvaleo',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Демо-версия',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Блок истечения
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.lock_clock, size: 40, color: Colors.red.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Пробный период завершён',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Демо-версия была активна с ${_fmt(widget.trial.firstLaunch)}\nпо ${_fmt(widget.trial.expireDate)} ($kTrialDays дня).',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Кнопка активации
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showActivationDialog,
                    icon: const Icon(Icons.vpn_key_outlined),
                    label: const Text('Ввести код активации'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Блок контактов
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Для получения кода активации:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      _contactRow(Icons.telegram, 'Telegram', '@sibvaleo'),
                      const SizedBox(height: 8),
                      _contactRow(Icons.email_outlined, 'Email', 'info@sibvaleo.ru'),
                      const SizedBox(height: 8),
                      _contactRow(Icons.phone_outlined, 'Телефон', '+7 (999) 000-00-00'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Кнопка выхода
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => exit(0),
                    icon: const Icon(Icons.close),
                    label: const Text('Закрыть приложение'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      );
}
