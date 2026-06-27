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
    return Client(
      id: widget.client?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text) ?? 30,
      gender: _gender,
      symptoms: _selectedSymptoms,
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
            _sectionTitle('Жалобы и симптомы'),
            const SizedBox(height: 8),
            if (_conditions.isEmpty)
              const CircularProgressIndicator()
            else
              _checkboxGroup(
                items: (_conditions['symptoms'] as List? ?? []),
                selected: _selectedSymptoms,
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

  Widget _checkboxGroup({
    required List items,
    required List<String> selected,
    required void Function(String id, bool val) onToggle,
  }) {
    // Группируем по системе
    final Map<String, List<Map>> bySystem = {};
    for (final item in items) {
      final sys = item['system'] as String? ?? 'OTHER';
      bySystem.putIfAbsent(sys, () => []).add(item as Map);
    }

    return Column(
      children: bySystem.entries.map((entry) {
        return ExpansionTile(
          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          initiallyExpanded: entry.value.any((i) => selected.contains(i['id'])),
          children: entry.value.map((item) {
            final id = item['id'] as String;
            final name = item['name'] as String;
            return CheckboxListTile(
              dense: true,
              title: Text(name, style: const TextStyle(fontSize: 14)),
              value: selected.contains(id),
              onChanged: (v) => onToggle(id, v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
