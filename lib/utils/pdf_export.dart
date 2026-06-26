import '../models/client.dart';

/// Генерирует текстовый вариант программы для копирования/отправки клиенту.
/// PDF-экспорт будет добавлен в следующей версии (requires pdf package).
String generateTextProgram(Program program) {
  final buf = StringBuffer();

  buf.writeln('═══════════════════════════════════════════');
  buf.writeln('  ПРОГРАММА ЗДОРОВЬЯ Siberian Wellness');
  buf.writeln('═══════════════════════════════════════════');
  buf.writeln('Клиент: ${program.clientName}');
  buf.writeln('Дата составления: ${_fmtDate(program.createdAt)}');
  buf.writeln('Длительность: 60 дней');
  buf.writeln();

  if (program.recommendedTests.isNotEmpty) {
    buf.writeln('─── РЕКОМЕНДУЕМЫЕ АНАЛИЗЫ (до начала курса) ───');
    for (final t in program.recommendedTests) {
      buf.writeln('  • $t');
    }
    buf.writeln();
  }

  buf.writeln('─── ПРОГРАММА ПРИЁМА ───');
  buf.writeln('Правила:');
  buf.writeln('  • Новый препарат вводить через 3-4 дня после предыдущего');
  buf.writeln('  • Одновременно не более 3 препаратов');
  buf.writeln('  • Принимать во время еды (если не указано иное)');
  buf.writeln();

  // Группируем по этапу
  final byStage = <int, List<ProgramEntry>>{};
  for (final step in program.steps) {
    byStage.putIfAbsent(step.stage, () => []).add(step);
  }
  final stageNames = {1:'ОЧИЩЕНИЕ', 2:'ЗАЩИТА', 3:'ПИТАНИЕ', 4:'ВОССТАНОВЛЕНИЕ'};

  for (final stage in byStage.keys.toList()..sort()) {
    buf.writeln('┌─ ЭТАП $stage — ${stageNames[stage]} ─────────────────');
    for (final step in byStage[stage]!) {
      buf.writeln('│  ${step.productName}');
      buf.writeln('│    Дни: ${step.startDay}-${step.endDay} (${step.durationDays} дней)');
      buf.writeln('│    Доза: ${step.dose}');
      buf.writeln('│    Кратность: ${step.timesPerDay}× в день');
      buf.writeln('│');
    }
    buf.writeln('└────────────────────────────────────────────');
    buf.writeln();
  }

  buf.writeln('─── ВАЖНО ───');
  buf.writeln('Данная программа составлена консультантом Siberian Wellness');
  buf.writeln('и носит информационный характер. Перед применением');
  buf.writeln('проконсультируйтесь с лечащим врачом.');

  return buf.toString();
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';
