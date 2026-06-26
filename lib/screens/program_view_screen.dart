import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/client.dart';

class ProgramViewScreen extends StatefulWidget {
  final Program program;
  final List<Product> products;
  const ProgramViewScreen({super.key, required this.program, required this.products});

  @override
  State<ProgramViewScreen> createState() => _ProgramViewScreenState();
}

class _ProgramViewScreenState extends State<ProgramViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  static const _stageColors = {
    1: Color(0xFF8D6E63),
    2: Color(0xFF1976D2),
    3: Color(0xFF388E3C),
    4: Color(0xFF7B1FA2),
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.program;
    return Scaffold(
      appBar: AppBar(
        title: Text('Программа: ${p.clientName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Список'),
            Tab(icon: Icon(Icons.view_timeline), text: 'Шкала'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ListView(program: p, stageColors: _stageColors),
          _TimelineView(program: p, stageColors: _stageColors),
        ],
      ),
    );
  }
}

// ─── Список препаратов ────────────────────────────────────────────────────────
class _ListView extends StatelessWidget {
  final Program program;
  final Map<int, Color> stageColors;
  const _ListView({required this.program, required this.stageColors});

  @override
  Widget build(BuildContext context) {
    final steps = program.steps;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Программа на 60 дней', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Клиент: ${program.clientName}', style: const TextStyle(color: Colors.grey)),
                  Text('Препаратов: ${steps.length}', style: const TextStyle(color: Colors.grey)),
                  Text('Дата: ${_formatDate(program.createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Рекомендуемые анализы
          if (program.recommendedTests.isNotEmpty) ...[
            Text('Рекомендуемые обследования', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Card(
              color: Colors.orange.shade50,
              child: Column(
                children: program.recommendedTests.map((t) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.science_outlined, color: Colors.orange, size: 20),
                  title: Text(t, style: const TextStyle(fontSize: 13)),
                )).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Препараты по этапам
          Text('Расписание приёма', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final color = stageColors[step.stage] ?? Colors.grey;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: color.withOpacity(0.4), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color,
                          radius: 14,
                          child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(step.productName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(step.stageName,
                              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _row(Icons.calendar_today, 'Дни приёма:', 'с ${step.startDay} по ${step.endDay} (${step.durationDays} дн.)'),
                    _row(Icons.medication, 'Доза:', step.dose),
                    _row(Icons.schedule, 'Кратность:', '${step.timesPerDay}× в день'),
                  ],
                ),
              ),
            );
          }),

          // Правило одновременного приёма
          const SizedBox(height: 8),
          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    SizedBox(width: 6),
                    Text('Правила приёма', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ]),
                  SizedBox(height: 8),
                  Text('• Новый препарат вводить через 3-4 дня после предыдущего', style: TextStyle(fontSize: 13)),
                  Text('• Одновременно не более 3 препаратов', style: TextStyle(fontSize: 13)),
                  Text('• Принимать во время еды (если не указано иное)', style: TextStyle(fontSize: 13)),
                  Text('• При появлении нежелательных реакций — отменить и сообщить консультанту', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text('$label ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Expanded(child: Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
      ],
    ),
  );

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

// ─── Шкала 60 дней ───────────────────────────────────────────────────────────
class _TimelineView extends StatelessWidget {
  final Program program;
  final Map<int, Color> stageColors;
  const _TimelineView({required this.program, required this.stageColors});

  @override
  Widget build(BuildContext context) {
    final steps = program.steps;
    const totalDays = 60;
    const dayWidth = 12.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Шапка — числа дней
            Row(
              children: [
                const SizedBox(width: 180),
                ...List.generate(totalDays, (i) => SizedBox(
                  width: dayWidth,
                  child: (i + 1) % 5 == 0
                      ? Text('${i + 1}', style: const TextStyle(fontSize: 8, color: Colors.grey), textAlign: TextAlign.center)
                      : const SizedBox(),
                )),
              ],
            ),
            const SizedBox(height: 4),
            // Строки препаратов
            ...steps.asMap().entries.map((entry) {
              final step = entry.value;
              final color = stageColors[step.stage] ?? Colors.grey;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    // Название
                    SizedBox(
                      width: 180,
                      child: Text(
                        step.productName,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Полоска дней
                    ...List.generate(totalDays, (day) {
                      final d = day + 1;
                      final active = d >= step.startDay && d <= step.endDay;
                      return Container(
                        width: dayWidth,
                        height: 18,
                        decoration: BoxDecoration(
                          color: active ? color : Colors.grey.shade100,
                          borderRadius: d == step.startDay
                              ? const BorderRadius.horizontal(left: Radius.circular(4))
                              : d == step.endDay
                                  ? const BorderRadius.horizontal(right: Radius.circular(4))
                                  : BorderRadius.zero,
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
            // Легенда этапов
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: stageColors.entries.map((e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 16, height: 12, decoration: BoxDecoration(color: e.value, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 4),
                  Text(_stageName(e.key), style: const TextStyle(fontSize: 11)),
                ],
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _stageName(int s) => const {1:'ОЧИЩЕНИЕ',2:'ЗАЩИТА',3:'ПИТАНИЕ',4:'ВОССТАНОВЛЕНИЕ'}[s] ?? '';
}
