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
                // Анализ систем
                _SystemAnalysisCard(client: widget.client),
                const SizedBox(height: 8),
                // Сводка жалоб клиента
                _ComplaintsCard(client: widget.client),
                const SizedBox(height: 8),
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

// ─── Анализ нагрузки по системам ─────────────────────────────────────────────
class _SystemAnalysisCard extends StatefulWidget {
  final Client client;
  const _SystemAnalysisCard({required this.client});
  @override
  State<_SystemAnalysisCard> createState() => _SystemAnalysisCardState();
}

class _SystemAnalysisCardState extends State<_SystemAnalysisCard> {
  _Analysis? _analysis;

  // Какие системы страдают вторично при поражении первичной
  static const _cascade = {
    'GIT':     ['LIVER', 'IMMUNO', 'ENERGY', 'SKIN'],
    'LIVER':   ['GIT', 'SKIN', 'IMMUNO', 'METABOL'],
    'HEART':   ['ENERGY', 'NEURO', 'METABOL'],
    'THYROID': ['METABOL', 'ENERGY', 'SKIN', 'NEURO', 'HEART'],
    'IMMUNO':  ['RESP', 'SKIN', 'GIT', 'ENERGY'],
    'NEURO':   ['ENERGY', 'HEART', 'IMMUNO'],
    'METABOL': ['HEART', 'LIVER', 'JOINTS'],
    'JOINTS':  ['ENERGY', 'METABOL'],
    'GYNECO':  ['NEURO', 'METABOL', 'ENERGY', 'THYROID'],
    'UROLOGY': ['ENERGY', 'IMMUNO'],
    'SKIN':    ['LIVER', 'METABOL', 'IMMUNO'],
    'ENERGY':  ['THYROID', 'LIVER', 'IMMUNO', 'NEURO'],
    'DETOX':   ['LIVER', 'SKIN', 'IMMUNO'],
    'RESP':    ['IMMUNO', 'DETOX', 'ENERGY'],
    'CHILDREN':['IMMUNO', 'GIT', 'ENERGY'],
    'ANTIAGE': ['METABOL', 'LIVER', 'SKIN'],
  };

  static const _systemNames = {
    'GIT': 'ЖКТ', 'LIVER': 'Печень', 'HEART': 'Сердце/Сосуды',
    'JOINTS': 'Суставы', 'NEURO': 'Нервная система', 'IMMUNO': 'Иммунитет',
    'THYROID': 'Щитовидная железа', 'GYNECO': 'Женское здоровье',
    'UROLOGY': 'Почки/МВП', 'SKIN': 'Кожа/Волосы', 'METABOL': 'Обмен веществ',
    'ENERGY': 'Энергетика', 'DETOX': 'Детокс', 'RESP': 'Дыхание',
    'CHILDREN': 'Детское здоровье', 'ANTIAGE': 'Anti-age',
  };

  static const _primaryText = {
    'GIT':     'Нарушения ЖКТ снижают всасывание нутриентов — вторично страдают иммунитет, кожа и энергетика.',
    'LIVER':   'Перегрузка печени нарушает детоксикацию, гормональный баланс и состояние кожи.',
    'HEART':   'Сердечно-сосудистые нарушения снижают оксигенацию тканей мозга, почек и мышц.',
    'THYROID': 'Щитовидная железа управляет обменом веществ: её дисфункция каскадно влияет на вес, настроение и сердце.',
    'IMMUNO':  'Снижение иммунитета открывает путь хроническим инфекциям, аллергиям и аутоиммунным реакциям.',
    'NEURO':   'Хронический стресс подавляет иммунитет, нарушает сон и усиливает боли в других системах.',
    'METABOL': 'Нарушения обмена создают системное воспаление — страдают сосуды, печень и суставы.',
    'JOINTS':  'Хроническое воспаление суставов истощает энергетику и повышает нагрузку на детоксикацию.',
    'GYNECO':  'Гормональный дисбаланс влияет на настроение, кости, обмен веществ и сердечно-сосудистую систему.',
    'UROLOGY': 'Хронические инфекции МВП снижают общий иммунитет и энергетику, нарушают микробиоту.',
    'SKIN':    'Состояние кожи отражает внутренние проблемы — чаще всего это печень, кишечник или иммунитет.',
    'ENERGY':  'Хроническая усталость требует исключения дефицитов (железо, D3, B12), дисфункции щитовидной и надпочечников.',
    'DETOX':   'Накопление токсинов перегружает печень и иммунную систему, проявляется через кожу и кишечник.',
    'RESP':    'Хронические заболевания дыхательных путей указывают на снижение иммунитета и аллергическую составляющую.',
    'CHILDREN':'У детей снижение иммунитета связано с дефицитом витаминов, дисбактериозом и недостаточным питанием.',
    'ANTIAGE': 'Преждевременное старение — дефицит антиоксидантов, нарушение детоксикации и снижение гормонального фона.',
  };

  static const _icons = {
    'GIT': Icons.set_meal, 'LIVER': Icons.water_drop_outlined,
    'HEART': Icons.favorite_outline, 'JOINTS': Icons.accessibility_new,
    'NEURO': Icons.psychology_outlined, 'IMMUNO': Icons.shield_outlined,
    'THYROID': Icons.radio_button_unchecked, 'GYNECO': Icons.female,
    'UROLOGY': Icons.opacity, 'SKIN': Icons.face_outlined,
    'METABOL': Icons.local_fire_department_outlined, 'ENERGY': Icons.bolt_outlined,
    'DETOX': Icons.eco_outlined, 'RESP': Icons.air,
    'CHILDREN': Icons.child_care, 'ANTIAGE': Icons.auto_awesome_outlined,
  };

  @override
  void initState() {
    super.initState();
    _analyse();
  }

  Future<void> _analyse() async {
    final raw = await rootBundle.loadString('assets/data/conditions.json');
    final data = jsonDecode(raw);

    final symSystem = <String, String>{};
    for (final s in (data['symptoms'] as List? ?? [])) {
      symSystem[s['id'] as String] = s['system'] as String;
    }
    final diagSystem = <String, String>{};
    for (final d in (data['diagnoses'] as List? ?? [])) {
      diagSystem[d['id'] as String] = d['system'] as String;
    }

    final counts = <String, int>{};
    for (final id in widget.client.symptoms) {
      final sys = symSystem[id]; if (sys != null) counts[sys] = (counts[sys] ?? 0) + 1;
    }
    for (final id in widget.client.diagnoses) {
      final sys = diagSystem[id]; if (sys != null) counts[sys] = (counts[sys] ?? 0) + 2; // диагноз весит больше
    }

    if (counts.isEmpty) return;

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final primary = sorted.first.key;
    final secondary = sorted.length > 1 ? sorted.skip(1).take(2).map((e) => e.key).toList() : <String>[];
    final cascade = (_cascade[primary] ?? [])
        .where((s) => !secondary.contains(s) && s != primary)
        .take(3)
        .toList();

    if (mounted) setState(() => _analysis = _Analysis(
      primary: primary,
      secondary: secondary,
      cascade: cascade,
      systemCounts: Map.fromEntries(sorted),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final a = _analysis;
    if (a == null) return const SizedBox();

    final primaryColor = _colorFor(a.primary);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.analytics_outlined, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text('Анализ состояния', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor)),
            ]),
            const SizedBox(height: 10),

            // Приоритетная система
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(_icons[a.primary] ?? Icons.circle, color: primaryColor, size: 28),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Приоритет: ${_systemNames[a.primary] ?? a.primary}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(_primaryText[a.primary] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  )),
                ],
              ),
            ),

            // Также вовлечены
            if (a.secondary.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Также вовлечены:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6, runSpacing: 4,
                children: a.secondary.map((s) => _sysChip(s, _colorFor(s))).toList(),
              ),
            ],

            // Вероятные каскадные нарушения
            if (a.cascade.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Вероятные связанные нарушения:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6, runSpacing: 4,
                children: a.cascade.map((s) => _sysChip(s, Colors.grey.shade600, dashed: true)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sysChip(String sys, Color color, {bool dashed = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: dashed ? Colors.transparent : color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: dashed ? 0.4 : 0.5),
          style: dashed ? BorderStyle.solid : BorderStyle.solid),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(_icons[sys] ?? Icons.circle, size: 13, color: color),
      const SizedBox(width: 4),
      Text(_systemNames[sys] ?? sys, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    ]),
  );

  Color _colorFor(String sys) => const {
    'GIT': Color(0xFF6D4C41), 'LIVER': Color(0xFFE65100),
    'HEART': Color(0xFFC62828), 'JOINTS': Color(0xFFE64A19),
    'NEURO': Color(0xFF6A1B9A), 'IMMUNO': Color(0xFF00695C),
    'THYROID': Color(0xFF1565C0), 'GYNECO': Color(0xFFAD1457),
    'UROLOGY': Color(0xFF00838F), 'SKIN': Color(0xFF558B2F),
    'METABOL': Color(0xFFBF360C), 'ENERGY': Color(0xFFF9A825),
    'DETOX': Color(0xFF2E7D32), 'RESP': Color(0xFF0277BD),
    'CHILDREN': Color(0xFF00897B), 'ANTIAGE': Color(0xFF7B1FA2),
  }[sys] ?? Colors.grey;
}

class _Analysis {
  final String primary;
  final List<String> secondary;
  final List<String> cascade;
  final Map<String, int> systemCounts;
  const _Analysis({required this.primary, required this.secondary, required this.cascade, required this.systemCounts});
}

// ─── Сводка жалоб клиента ────────────────────────────────────────────────────
class _ComplaintsCard extends StatefulWidget {
  final Client client;
  const _ComplaintsCard({required this.client});
  @override
  State<_ComplaintsCard> createState() => _ComplaintsCardState();
}

class _ComplaintsCardState extends State<_ComplaintsCard> {
  bool _expanded = false;
  Map<String, String> _symNames = {}; // id → name
  Map<String, String> _diagNames = {};

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    final raw = await rootBundle.loadString('assets/data/conditions.json');
    final data = jsonDecode(raw);
    final sm = <String, String>{};
    for (final s in (data['symptoms'] as List? ?? [])) {
      sm[s['id']] = s['name'];
    }
    final dm = <String, String>{};
    for (final d in (data['diagnoses'] as List? ?? [])) {
      dm[d['id']] = d['name'];
    }
    if (mounted) setState(() { _symNames = sm; _diagNames = dm; });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.client;
    final allCount = c.symptoms.length + c.diagnoses.length + c.customSymptoms.length;
    if (allCount == 0) return const SizedBox();
    return Card(
      color: Colors.teal.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.person_search, color: Colors.teal),
            title: Text('Жалобы: ${c.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$allCount позиций'),
            trailing: IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded) ...[
            if (c.symptoms.isNotEmpty) _section('Симптомы', c.symptoms.map((id) => _symNames[id] ?? id).toList(), Colors.teal),
            if (c.diagnoses.isNotEmpty) _section('Диагнозы', c.diagnoses.map((id) => _diagNames[id] ?? id).toList(), Colors.indigo),
            if (c.customSymptoms.isNotEmpty) _section('Другие жалобы', c.customSymptoms, Colors.green),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _section(String title, List<String> items, Color color) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: items.map((s) => Chip(
            label: Text(s, style: const TextStyle(fontSize: 11)),
            backgroundColor: color.withValues(alpha: 0.1),
            side: BorderSide(color: color.withValues(alpha: 0.3)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )).toList(),
        ),
      ],
    ),
  );
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
