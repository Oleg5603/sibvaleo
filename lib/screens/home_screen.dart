import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/client.dart';
import '../data/recommendation_engine.dart';
import '../data/app_storage.dart';
import '../utils/trial.dart';
import 'client_form_screen.dart';
import 'program_view_screen.dart';
import 'catalog_screen.dart';
import 'code_generator_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Product> products;
  final RecommendationEngine engine;
  final TrialStatus trial;
  const HomeScreen({super.key, required this.products, required this.engine, required this.trial});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Client> _clients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final clients = await AppStorage.loadClients();
    setState(() { _clients = clients; _loading = false; });
  }

  Future<void> _handleActivate() async {
    final ctrl = TextEditingController();
    String? err;
    bool busy = false;

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
              const Text('Введите код активации,\nполученный от консультанта:',
                  style: TextStyle(fontSize: 13, height: 1.5)),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 15,
                decoration: InputDecoration(
                  hintText: 'SVL001-62277',
                  labelText: 'Код активации',
                  errorText: err,
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                onSubmitted: (_) async {
                  setLocal(() { busy = true; err = null; });
                  final ok = await Trial.activate(ctrl.text);
                  if (!ctx.mounted) return;
                  ok ? Navigator.pop(ctx) : setLocal(() { busy = false; err = 'Неверный код'; });
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            ElevatedButton(
              onPressed: busy ? null : () async {
                setLocal(() { busy = true; err = null; });
                final ok = await Trial.activate(ctrl.text);
                if (!ctx.mounted) return;
                ok ? Navigator.pop(ctx) : setLocal(() { busy = false; err = 'Неверный код. Проверьте ввод.'; });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
              child: busy
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Активировать'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    final newTrial = await Trial.check();
    if (!mounted) return;
    if (newTrial.isActivated) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => HomeScreen(products: widget.products, engine: widget.engine, trial: newTrial),
      ));
    }
  }

  Future<void> _openClientForm([Client? existing]) async {
    final result = await Navigator.push<Client>(
      context,
      MaterialPageRoute(
        builder: (_) => ClientFormScreen(
          client: existing,
          products: widget.products,
          engine: widget.engine,
        ),
      ),
    );
    if (result != null) {
      await AppStorage.upsertClient(result);
      await _load();
    }
  }

  Future<void> _deleteClient(Client c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить клиента?'),
        content: Text('${c.name} будет удалён безвозвратно.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await AppStorage.deleteClient(c.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sibvaleo — Программы здоровья'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Каталог препаратов',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => CatalogScreen(products: widget.products),
            )),
          ),
        ],
      ),
      body: Column(
        children: [
          _TrialBanner(trial: widget.trial, onActivate: _handleActivate),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _clients.isEmpty
                    ? _empty()
                    : _clientList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openClientForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Новый клиент'),
      ),
    );
  }

  Widget _empty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.health_and_safety_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Нет клиентов', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey)),
        const SizedBox(height: 8),
        const Text('Нажмите + чтобы добавить первого клиента', style: TextStyle(color: Colors.grey)),
      ],
    ),
  );

  Widget _clientList() => ListView.builder(
    padding: const EdgeInsets.all(12),
    itemCount: _clients.length,
    itemBuilder: (_, i) {
      final c = _clients[i];
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: c.gender == 'М'
                ? Colors.blue.shade100
                : Colors.pink.shade100,
            child: Text(
              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: c.gender == 'М' ? Colors.blue.shade800 : Colors.pink.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${c.age} лет · ${c.gender} · ${c.symptoms.length + c.diagnoses.length} симптомов',
            style: const TextStyle(fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined),
                tooltip: 'Программа',
                onPressed: () async {
                  final prog = await AppStorage.latestProgramForClient(c.id);
                  if (!mounted) return;
                  if (prog != null) {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ProgramViewScreen(program: prog, products: widget.products),
                    ));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Сначала составьте программу для клиента')),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _openClientForm(c),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteClient(c),
              ),
            ],
          ),
          onTap: () => _openClientForm(c),
        ),
      );
    },
  );
}

// ─── Баннер демо / активирован ───────────────────────────────────────────────
class _TrialBanner extends StatelessWidget {
  final TrialStatus trial;
  final VoidCallback? onActivate;
  const _TrialBanner({required this.trial, this.onActivate});

  @override
  Widget build(BuildContext context) {
    // Полная версия — тихий зелёный чип
    if (trial.isActivated) {
      return Material(
        color: const Color(0xFFE8F5E9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.verified, size: 15, color: Color(0xFF2E7D32)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Полная версия активирована',
                    style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500)),
              ),
              // 5 тапов → генератор кодов (для консультанта)
              _SecretTap(child: const SizedBox(width: 40, height: 24)),
            ],
          ),
        ),
      );
    }

    final days = trial.daysLeft;
    final Color bg;
    final Color fg;
    final String text;
    final IconData icon;

    if (days >= 3) {
      bg = Colors.green.shade50; fg = Colors.green.shade800;
      icon = Icons.timer_outlined;
      text = 'Демо · осталось $days дня';
    } else if (days >= 2) {
      bg = Colors.orange.shade50; fg = Colors.orange.shade800;
      icon = Icons.timer_outlined;
      text = 'Демо · осталось $days дня';
    } else {
      bg = Colors.red.shade50; fg = Colors.red.shade800;
      icon = Icons.warning_amber_outlined;
      text = days == 1 ? 'Демо · последний день!' : 'Демо · заканчивается сегодня!';
    }

    final expire = trial.expireDate;
    final expStr =
        '${expire.day.toString().padLeft(2, '0')}.${expire.month.toString().padLeft(2, '0')}.${expire.year}';

    return Material(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
            ),
            Text('до $expStr',
                style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.7))),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onActivate,
              style: TextButton.styleFrom(
                foregroundColor: fg,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: const Text('Активировать'),
            ),
          ],
        ),
      ),
    );
  }
}

// Невидимый виджет — 5 тапов открывают генератор кодов
class _SecretTap extends StatefulWidget {
  final Widget child;
  const _SecretTap({required this.child});
  @override
  State<_SecretTap> createState() => _SecretTapState();
}

class _SecretTapState extends State<_SecretTap> {
  int _taps = 0;
  void _onTap() {
    _taps++;
    if (_taps >= 5) {
      _taps = 0;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CodeGeneratorScreen()));
    }
  }
  @override
  Widget build(BuildContext context) =>
      GestureDetector(onTap: _onTap, child: widget.child);
}
