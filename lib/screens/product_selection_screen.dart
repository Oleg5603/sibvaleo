import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../models/client.dart';
import '../data/recommendation_engine.dart';
import '../data/app_storage.dart';
import 'program_view_screen.dart';

class ProductSelectionScreen extends StatefulWidget {
  final Client client;
  final RecommendationEngine engine;
  final List<Product> products;
  const ProductSelectionScreen({super.key, required this.client, required this.engine, required this.products});

  @override
  State<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  late List<ScoredProduct> _scored;
  final Set<String> _selectedIds = {};

  static const _stageColors = {
    1: Color(0xFF8D6E63), // ОЧИЩЕНИЕ — коричневый
    2: Color(0xFF1976D2), // ЗАЩИТА — синий
    3: Color(0xFF388E3C), // ПИТАНИЕ — зелёный
    4: Color(0xFF7B1FA2), // ВОССТАНОВЛЕНИЕ — фиолетовый
  };

  @override
  void initState() {
    super.initState();
    _scored = widget.engine.matchProducts(widget.client);
    // Автовыбор топ-10 по очкам
    final top = _scored.take(10).map((s) => s.product.id).toSet();
    _selectedIds.addAll(top);
  }

  void _toggle(String id) => setState(() {
    _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
  });

  Future<void> _buildProgram() async {
    final selected = _scored
        .where((s) => _selectedIds.contains(s.product.id))
        .map((s) => s.product)
        .toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы один препарат')),
      );
      return;
    }

    final program = widget.engine.buildProgram(widget.client, selected);
    await AppStorage.upsertProgram(program);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ProgramViewScreen(program: program, products: widget.products),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Группируем по этапу
    final byStage = <int, List<ScoredProduct>>{};
    for (final s in _scored) {
      byStage.putIfAbsent(s.product.stage, () => []).add(s);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Препараты для ${widget.client.name}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: _selectedIds.isEmpty ? null : _buildProgram,
            icon: const Icon(Icons.calendar_today),
            label: Text('Программа (${_selectedIds.length})'),
          ),
        ],
      ),
      body: _scored.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Нет подходящих препаратов', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Уточните жалобы или диагнозы', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // Рекомендуемые анализы
                _TestsCard(client: widget.client, engine: widget.engine),
                const SizedBox(height: 12),
                // Препараты по этапам
                ...byStage.entries.map((entry) => _StageSection(
                  stage: entry.key,
                  color: _stageColors[entry.key] ?? Colors.grey,
                  products: entry.value,
                  selectedIds: _selectedIds,
                  onToggle: _toggle,
                  clientAge: widget.client.age,
                )),
              ],
            ),
      bottomNavigationBar: _selectedIds.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: _buildProgram,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text('Составить программу (${_selectedIds.length} препаратов)'),
                ),
              ),
            )
          : null,
    );
  }
}

// ─── Карточка рекомендуемых анализов ─────────────────────────────────────────
class _TestsCard extends StatefulWidget {
  final Client client;
  final RecommendationEngine engine;
  const _TestsCard({required this.client, required this.engine});

  @override
  State<_TestsCard> createState() => _TestsCardState();
}

class _TestsCardState extends State<_TestsCard> {
  bool _expanded = false;
  Map<String, Map<String, String>> _testMeta = {}; // id -> {name, purpose}

  @override
  void initState() {
    super.initState();
    _loadTestMeta();
  }

  Future<void> _loadTestMeta() async {
    final raw = await rootBundle.loadString('assets/data/conditions.json');
    final data = jsonDecode(raw);
    final map = <String, Map<String, String>>{};
    for (final t in (data['tests'] as List? ?? [])) {
      map[t['id'] as String] = {
        'name': t['name'] as String? ?? t['id'],
        'purpose': t['purpose'] as String? ?? '',
      };
    }
    if (mounted) setState(() => _testMeta = map);
  }

  @override
  Widget build(BuildContext context) {
    final testIds = widget.engine.buildProgram(widget.client, []).recommendedTests;
    if (testIds.isEmpty) return const SizedBox();
    return Card(
      color: Colors.orange.shade50,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.science_outlined, color: Colors.orange),
            title: const Text('Рекомендуемые анализы', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${testIds.length} анализов — помогут уточнить состояние'),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded)
            ...testIds.map((id) {
              final meta = _testMeta[id];
              final name = meta?['name'] ?? id;
              final purpose = meta?['purpose'] ?? '';
              return ListTile(
                dense: true,
                leading: const Icon(Icons.check_circle_outline, color: Colors.orange, size: 20),
                title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                subtitle: purpose.isNotEmpty
                    ? Text(purpose, style: const TextStyle(fontSize: 12, color: Colors.black54))
                    : null,
              );
            }),
          if (_expanded) const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Секция этапа ─────────────────────────────────────────────────────────────
class _StageSection extends StatelessWidget {
  final int stage;
  final Color color;
  final List<ScoredProduct> products;
  final Set<String> selectedIds;
  final void Function(String) onToggle;
  final int clientAge;

  const _StageSection({
    required this.stage,
    required this.color,
    required this.products,
    required this.selectedIds,
    required this.onToggle,
    required this.clientAge,
  });

  @override
  Widget build(BuildContext context) {
    final stageName = products.first.product.stageName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ЭТАП $stage — $stageName',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        ...products.map((sp) => _ProductCard(
          sp: sp,
          selected: selectedIds.contains(sp.product.id),
          color: color,
          onToggle: () => onToggle(sp.product.id),
          clientAge: clientAge,
        )),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ProductCard extends StatefulWidget {
  final ScoredProduct sp;
  final bool selected;
  final Color color;
  final VoidCallback onToggle;
  final int clientAge;
  const _ProductCard({required this.sp, required this.selected, required this.color, required this.onToggle, required this.clientAge});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.sp.product;
    final dose = p.doseForAge(widget.clientAge);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: widget.selected
            ? BorderSide(color: widget.color, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          ListTile(
            leading: Checkbox(
              value: widget.selected,
              activeColor: widget.color,
              onChanged: (_) => widget.onToggle(),
            ),
            title: Row(
              children: [
                Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.sp.score} балл.',
                    style: TextStyle(fontSize: 11, color: widget.color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: Text(p.action, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: widget.onToggle,
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.info_outline),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Серия', p.series),
                  _infoRow('Форма', p.form),
                  _infoRow('Курс', '${p.minCourseDays}-${p.maxCourseDays} дней'),
                  _infoRow('Доза', dose),
                  _infoRow('Приём', '${p.frequencyPerDay}×/день'),
                  const SizedBox(height: 4),
                  const Text('Состав:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(p.composition, style: const TextStyle(fontSize: 12)),
                  if (p.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Expanded(child: Text(p.notes, style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 70, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey))),
        Expanded(child: Text(val, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}
