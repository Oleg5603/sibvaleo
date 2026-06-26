import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/client.dart';
import '../data/recommendation_engine.dart';
import '../data/app_storage.dart';
import 'client_form_screen.dart';
import 'program_view_screen.dart';
import 'catalog_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Product> products;
  final RecommendationEngine engine;
  const HomeScreen({super.key, required this.products, required this.engine});

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _clients.isEmpty
              ? _empty()
              : _clientList(),
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
