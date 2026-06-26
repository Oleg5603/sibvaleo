import 'package:flutter/material.dart';
import '../models/product.dart';

class CatalogScreen extends StatefulWidget {
  final List<Product> products;
  const CatalogScreen({super.key, required this.products});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _search = '';
  int? _stageFilter;
  String? _categoryFilter;

  static const _stageColors = {
    1: Color(0xFF8D6E63),
    2: Color(0xFF1976D2),
    3: Color(0xFF388E3C),
    4: Color(0xFF7B1FA2),
  };

  List<Product> get _filtered {
    return widget.products.where((p) {
      final q = _search.toLowerCase();
      final nameMatch = q.isEmpty || p.name.toLowerCase().contains(q) ||
          p.series.toLowerCase().contains(q) || p.action.toLowerCase().contains(q);
      final stageMatch = _stageFilter == null || p.stage == _stageFilter;
      final catMatch = _categoryFilter == null || p.category == _categoryFilter;
      return nameMatch && stageMatch && catMatch;
    }).toList()
      ..sort((a, b) => a.stage == b.stage ? a.name.compareTo(b.name) : a.stage.compareTo(b.stage));
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог препаратов'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Поиск по названию или действию...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _search = ''))
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          // Фильтры
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Этапы
                ...[null, 1, 2, 3, 4].map((s) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(s == null ? 'Все этапы' : 'Этап $s'),
                    selected: _stageFilter == s,
                    selectedColor: s == null ? Colors.grey.shade200 : (_stageColors[s] ?? Colors.grey).withOpacity(0.2),
                    onSelected: (_) => setState(() => _stageFilter = s),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Счётчик
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('${items.length} препаратов', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          // Список
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final p = items[i];
                final color = _stageColors[p.stage] ?? Colors.grey;
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ExpansionTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text('${p.stage}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(p.stageName, style: TextStyle(fontSize: 10, color: color)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(child: Text(p.series, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _row('Форма', p.form),
                            _row('Действие', p.action),
                            _row('Состав', p.composition),
                            _row('Доза (взрослые)', p.doseAdult),
                            if (p.doseChild612 != null) _row('Доза (6-12 лет)', p.doseChild612!),
                            if (p.doseChild1218 != null) _row('Доза (12-18 лет)', p.doseChild1218!),
                            if (p.doseElderly != null) _row('Доза (65+)', p.doseElderly!),
                            _row('Курс', '${p.minCourseDays}-${p.maxCourseDays} дней'),
                            if (p.contraindications.isNotEmpty)
                              _row('Противопоказания', p.contraindications.join(', ')),
                            if (p.notes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('💡 ${p.notes}', style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String val) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: Colors.black87),
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          TextSpan(text: val),
        ],
      ),
    ),
  );
}
