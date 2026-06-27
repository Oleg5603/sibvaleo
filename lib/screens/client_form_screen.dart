import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../models/client.dart';
import '../data/recommendation_engine.dart';
import '../data/app_storage.dart';
import 'product_selection_screen.dart';

class ClientFormScreen extends StatefulWidget {
  final Client? client;
  final List<Product> products;
  final RecommendationEngine engine;
  const ClientFormScreen({super.key, this.client, required this.products, required this.engine});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

// ─── Вопросы быстрого скрининга ──────────────────────────────────────────────
class _ScreenQ {
  final String id;
  final int stage;
  final String title;
  final String hint;
  final IconData icon;
  final Color color;
  final List<String> condIds; // IDs которые добавляются в симптомы клиента
  const _ScreenQ(this.id, this.stage, this.title, this.hint, this.icon, this.color, this.condIds);
}

const _screeningQuestions = [
  _ScreenQ('sq_git', 1, 'Нарушения пищеварения',
    'Запоры, вздутие, тяжесть после еды, горечь во рту, нерегулярный стул',
    Icons.restaurant, Color(0xFF8D6E63),
    ['gut_dysbiosis', 'irritable_bowel', 'запор', 'вздутие', 'тяжесть_после_еды', 'горечь_во_рту']),

  _ScreenQ('sq_detox', 1, 'Нагрузка на печень / детокс',
    'Кожные высыпания, аллергии, приём лекарств, алкоголь, плохая экология',
    Icons.water_drop_outlined, Color(0xFF8D6E63),
    ['fatty_liver', 'detox', 'allergy', 'chemical_exposure', 'кожные_высыпания', 'аллергия']),

  _ScreenQ('sq_immunity', 2, 'Ослабленный иммунитет',
    'ОРВИ 3+ раз в год, долгое восстановление, герпес, хронические инфекции',
    Icons.shield_outlined, Color(0xFF1976D2),
    ['immunity', 'chronic_infection', 'частые_простуды', 'снижение_иммунитета', 'seasonal_prevention']),

  _ScreenQ('sq_vitamins', 3, 'Дефицит витаминов и минералов',
    'Выпадение волос, ломкость ногтей, сухость кожи, судороги в ногах',
    Icons.local_pharmacy_outlined, Color(0xFF388E3C),
    ['vitamin_deficiency', 'general_health', 'выпадение_волос', 'ломкость_ногтей', 'сухость_кожи', 'brittle_nails']),

  _ScreenQ('sq_energy', 3, 'Хроническая усталость / стресс',
    'Сниженная энергия, нарушение сна, тревога, снижение концентрации',
    Icons.battery_charging_full_outlined, Color(0xFF388E3C),
    ['усталость', 'слабость', 'бессонница', 'стресс', 'insomnia', 'chronic_stress', 'снижение_работоспособности']),

  _ScreenQ('sq_joints', 3, 'Суставы, кости, позвоночник',
    'Боли в суставах, хруст, остеохондроз, снижение подвижности',
    Icons.accessibility_new, Color(0xFF388E3C),
    ['osteoarthritis', 'osteochondrosis', 'osteoporosis', 'bone_health', 'боль_в_суставах', 'боль_в_спине', 'joint_pain']),

  _ScreenQ('sq_heart', 2, 'Сердце и сосуды',
    'Повышенное давление, варикоз, атеросклероз, отёки ног',
    Icons.favorite_outline, Color(0xFF1976D2),
    ['hypertension', 'atherosclerosis', 'varicose', 'cardiovascular', 'повышенное_давление', 'отёки']),

  _ScreenQ('sq_recovery', 4, 'Восстановление после болезни/стресса',
    'После ОРВИ, операции, антибиотиков, длительного стресса или COVID',
    Icons.healing_outlined, Color(0xFF7B1FA2),
    ['after_illness', 'after_antibiotics', 'chronic_stress', 'после_COVID', 'снижение_работоспособности']),

  _ScreenQ('sq_antiage', 4, 'Антивозрастная поддержка',
    'Снижение упругости кожи, памяти, либидо, замедленный обмен веществ',
    Icons.elderly_outlined, Color(0xFF7B1FA2),
    ['anti_age', 'antioxidant', 'brain_support', 'metabolism_disorders', 'снижение_памяти', 'снижение_либидо']),
];

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl  = TextEditingController();
  final _labCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _customSymptomsCtrl = TextEditingController();
  String _gender = 'Ж';

  List<String> _selectedSymptoms   = [];
  List<String> _selectedDiagnoses  = [];
  List<String> _customSymptomsList  = [];
  final Set<String> _activeScreening = {}; // id вопросов скрининга

  List<String> get _screeningIds => _activeScreening
      .expand((qid) => _screeningQuestions.firstWhere((q) => q.id == qid).condIds)
      .toSet()
      .toList();

  void _addCustomSymptom() {
    final text = _customSymptomsCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _customSymptomsList.add(text);
      _customSymptomsCtrl.clear();
    });
  }

  Map<String, dynamic> _conditions = {};

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    if (c != null) {
      _nameCtrl.text  = c.name;
      _ageCtrl.text   = c.age.toString();
      _gender         = c.gender;
      _labCtrl.text   = c.labResults;
      _notesCtrl.text = c.notes;
      _customSymptomsList = List.from(c.customSymptoms);
      _selectedSymptoms  = List.from(c.symptoms);
      _selectedDiagnoses = List.from(c.diagnoses);
    }
    _loadConditions();
  }

  Future<void> _loadConditions() async {
    final raw = await rootBundle.loadString('assets/data/conditions.json');
    setState(() => _conditions = jsonDecode(raw));
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _ageCtrl.dispose();
    _labCtrl.dispose(); _notesCtrl.dispose(); _customSymptomsCtrl.dispose();
    super.dispose();
  }

  Client _buildClient() {
    // Объединяем симптомы из чекбоксов и из скрининга (без дублей)
    final allSymptoms = {..._selectedSymptoms, ..._screeningIds}.toList();
    return Client(
      id: widget.client?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text) ?? 30,
      gender: _gender,
      symptoms: allSymptoms,
      diagnoses: _selectedDiagnoses,
      customSymptoms: _customSymptomsList,
      labResults: _labCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      createdAt: widget.client?.createdAt,
    );
  }

  Future<void> _goToProductSelection() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя клиента')),
      );
      return;
    }
    final client = _buildClient();
    await AppStorage.upsertClient(client);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductSelectionScreen(
          client: client,
          engine: widget.engine,
          products: widget.products,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.client == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Новый клиент' : 'Редактировать'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: _goToProductSelection,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Подобрать препараты'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Основная информация'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Имя клиента *', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Возраст', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 12),
              _genderSelector(),
            ]),
            const SizedBox(height: 20),
            _sectionTitle('Быстрый скрининг'),
            const SizedBox(height: 4),
            const Text(
              'Отметьте всё что беспокоит — программа подберёт нужные этапы',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            _buildScreening(),
            const SizedBox(height: 20),
            _sectionTitle('Жалобы и симптомы (подробно)'),
            const SizedBox(height: 8),
            if (_conditions.isEmpty)
              const CircularProgressIndicator()
            else
              _checkboxGroup(
                items: (_conditions['symptoms'] as List? ?? []),
                selected: _selectedSymptoms,
                label: 'симптомы',
                onToggle: (id, val) => setState(() {
                  val ? _selectedSymptoms.add(id) : _selectedSymptoms.remove(id);
                }),
              ),
            const SizedBox(height: 12),
            _sectionTitle('Другие жалобы (свободный ввод)'),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _customSymptomsCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Введите жалобу и нажмите +',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addCustomSymptom(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 56),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: _addCustomSymptom,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            if (_customSymptomsList.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _customSymptomsList.map((s) => Chip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => setState(() => _customSymptomsList.remove(s)),
                  backgroundColor: Colors.green.shade50,
                  side: BorderSide(color: Colors.green.shade200),
                )).toList(),
              ),
            ],
            const SizedBox(height: 20),
            _sectionTitle('Диагнозы'),
            const SizedBox(height: 8),
            if (_conditions.isNotEmpty)
              _checkboxGroup(
                items: (_conditions['diagnoses'] as List? ?? []),
                selected: _selectedDiagnoses,
                label: 'диагнозы',
                onToggle: (id, val) => setState(() {
                  val ? _selectedDiagnoses.add(id) : _selectedDiagnoses.remove(id);
                }),
              ),
            const SizedBox(height: 20),
            _sectionTitle('Результаты анализов'),
            const SizedBox(height: 8),
            TextField(
              controller: _labCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Вставьте значения анализов (витамин D, ферритин, ТТГ, АЛТ/АСТ и т.д.)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _sectionTitle('Заметки'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Дополнительные замечания, аллергии, противопоказания...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _goToProductSelection,
                icon: const Icon(Icons.search),
                label: const Text('Подобрать препараты', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  );

  Widget _genderSelector() => SegmentedButton<String>(
    segments: const [
      ButtonSegment(value: 'М', label: Text('М')),
      ButtonSegment(value: 'Ж', label: Text('Ж')),
    ],
    selected: {_gender},
    onSelectionChanged: (s) => setState(() => _gender = s.first),
  );

  static const _stageColors = {
    1: Color(0xFF8D6E63),
    2: Color(0xFF1976D2),
    3: Color(0xFF388E3C),
    4: Color(0xFF7B1FA2),
  };
  static const _stageNames = {1: 'ОЧИЩЕНИЕ', 2: 'ЗАЩИТА', 3: 'ПИТАНИЕ', 4: 'ВОССТАНОВЛЕНИЕ'};

  Widget _buildScreening() {
    // Группируем по этапу
    final byStage = <int, List<_ScreenQ>>{};
    for (final q in _screeningQuestions) {
      byStage.putIfAbsent(q.stage, () => []).add(q);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: byStage.entries.map((entry) {
        final stage = entry.key;
        final color = _stageColors[stage] ?? Colors.grey;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Этап ${stage} — ${_stageNames[stage]}',
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
              ),
            ),
            ...entry.value.map((q) => _ScreeningTile(
              q: q,
              active: _activeScreening.contains(q.id),
              onToggle: (val) => setState(() {
                val ? _activeScreening.add(q.id) : _activeScreening.remove(q.id);
              }),
            )),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  static const _systemNames = {
    'GIT':      'Пищеварение',
    'LIVER':    'Печень / желчный пузырь',
    'HEART':    'Сердце и сосуды',
    'JOINTS':   'Суставы и кости',
    'NEURO':    'Нервная система',
    'IMMUNO':   'Иммунитет',
    'THYROID':  'Щитовидная железа',
    'GYNECO':   'Женское здоровье',
    'UROLOGY':  'Мочевыводящие пути',
    'SKIN':     'Кожа и волосы',
    'METABOL':  'Обмен веществ / вес',
    'ENERGY':   'Энергия и усталость',
    'DETOX':    'Детокс / экология',
    'RESP':     'Дыхательная система',
    'CHILDREN': 'Детское здоровье',
    'ANTIAGE':  'Антивозрастное',
    'OTHER':    'Прочее',
  };

  Widget _checkboxGroup({
    required List items,
    required List<String> selected,
    required void Function(String id, bool val) onToggle,
    required String label,
  }) {
    // Индекс id → name для итогового списка
    final Map<String, String> nameById = {
      for (final item in items) item['id'] as String: item['name'] as String,
    };

    // Группируем по системе
    final Map<String, List<Map>> bySystem = {};
    for (final item in items) {
      final sys = item['system'] as String? ?? 'OTHER';
      bySystem.putIfAbsent(sys, () => []).add(item as Map);
    }

    final selectedInGroup = selected.where(nameById.containsKey).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Итоговый список отмеченного
        if (selectedInGroup.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Отмечено ($label): ${selectedInGroup.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: selectedInGroup.map((id) => Chip(
                    label: Text(nameById[id] ?? id,
                        style: const TextStyle(fontSize: 11)),
                    deleteIcon: const Icon(Icons.close, size: 13),
                    onDeleted: () => onToggle(id, false),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFA5D6A7)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Группы по категориям
        ...bySystem.entries.map((entry) {
          final sysName = _systemNames[entry.key] ?? entry.key;
          final hasSelected = entry.value.any((i) => selected.contains(i['id']));
          return ExpansionTile(
            title: Row(children: [
              Expanded(child: Text(sysName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
              if (hasSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${entry.value.where((i) => selected.contains(i['id'])).length}',
                    style: const TextStyle(fontSize: 11, color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ]),
            initiallyExpanded: hasSelected,
            children: entry.value.map((item) {
              final id = item['id'] as String;
              final name = item['name'] as String;
              return CheckboxListTile(
                dense: true,
                title: Text(name, style: const TextStyle(fontSize: 14)),
                value: selected.contains(id),
                onChanged: (v) => onToggle(id, v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF2E7D32),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}

// ─── Карточка вопроса скрининга ───────────────────────────────────────────────
class _ScreeningTile extends StatelessWidget {
  final _ScreenQ q;
  final bool active;
  final ValueChanged<bool> onToggle;
  const _ScreeningTile({required this.q, required this.active, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final color = q.color;
    return GestureDetector(
      onTap: () => onToggle(!active),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? color : Colors.grey.shade300,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(q.icon, size: 22, color: active ? color : Colors.grey.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: active ? color : Colors.black87,
                      )),
                  Text(q.hint,
                      style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              active ? Icons.check_circle : Icons.circle_outlined,
              color: active ? color : Colors.grey.shade300,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
