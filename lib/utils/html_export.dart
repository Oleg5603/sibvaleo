import 'dart:io';
import '../models/client.dart';

Future<String?> exportProgramToHtml(Program program, {bool openInBrowser = true}) async {
  final html = _buildHtml(program);

  final String desktopDir;
  if (Platform.isWindows) {
    desktopDir = '${Platform.environment['USERPROFILE'] ?? ''}\\Desktop';
  } else if (Platform.isMacOS) {
    desktopDir = '${Platform.environment['HOME'] ?? ''}/Desktop';
  } else {
    desktopDir = '${Platform.environment['HOME'] ?? ''}/Desktop';
  }

  final safeName = program.clientName.replaceAll(RegExp(r'[^\wЀ-ӿ]'), '_');
  final fileName = 'sibvaleo_${safeName}_${_dateStr(program.createdAt)}.html';
  final filePath = '$desktopDir${Platform.pathSeparator}$fileName';

  try {
    await File(filePath).writeAsString(html, encoding: const SystemEncoding());
    if (openInBrowser) {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', filePath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [filePath]);
      } else {
        await Process.run('xdg-open', [filePath]);
      }
    }
    return filePath;
  } catch (_) {
    return null;
  }
}

String _dateStr(DateTime d) =>
    '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

const _stageColors = {
  1: '#8D6E63',
  2: '#1976D2',
  3: '#388E3C',
  4: '#7B1FA2',
};
const _stageNames = {
  1: 'ОЧИЩЕНИЕ',
  2: 'ЗАЩИТА',
  3: 'ПИТАНИЕ',
  4: 'ВОССТАНОВЛЕНИЕ',
};

String _buildHtml(Program program) {
  final byStage = <int, List<ProgramEntry>>{};
  for (final s in program.steps) {
    byStage.putIfAbsent(s.stage, () => []).add(s);
  }

  final stagesHtml = StringBuffer();
  for (final stage in byStage.keys.toList()..sort()) {
    final color = _stageColors[stage] ?? '#555';
    final stageName = _stageNames[stage] ?? '';
    stagesHtml.write('''
      <div class="stage">
        <div class="stage-header" style="background:$color">Этап $stage — $stageName</div>
        <table>
          <tr><th>Препарат</th><th>Дни</th><th>Дней</th><th>Доза</th><th>Приём</th></tr>
    ''');
    for (final step in byStage[stage]!) {
      stagesHtml.write('''
          <tr>
            <td><strong>${step.productName}</strong></td>
            <td>${step.startDay}–${step.endDay}</td>
            <td>${step.durationDays}</td>
            <td>${step.dose}</td>
            <td>${step.timesPerDay}×/день</td>
          </tr>
      ''');
    }
    stagesHtml.write('</table></div>');
  }

  final testsHtml = program.recommendedTests.isNotEmpty
      ? '''
        <div class="tests">
          <h3>Рекомендуемые анализы (до начала курса)</h3>
          <ul>${program.recommendedTests.map((t) => '<li>$t</li>').join()}</ul>
        </div>'''
      : '';

  final d = program.createdAt;
  final dateFormatted = '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';

  return '''<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<title>Программа здоровья — ${program.clientName}</title>
<style>
  body { font-family: Arial, sans-serif; max-width: 900px; margin: 30px auto; color: #222; }
  h1 { color: #2E7D32; border-bottom: 2px solid #2E7D32; padding-bottom: 8px; }
  .meta { color: #555; margin-bottom: 20px; }
  .stage { margin-bottom: 24px; border-radius: 6px; overflow: hidden; box-shadow: 0 1px 4px rgba(0,0,0,.15); }
  .stage-header { color: #fff; font-weight: bold; padding: 10px 16px; font-size: 14px; letter-spacing: .5px; }
  table { width: 100%; border-collapse: collapse; }
  th { background: #f5f5f5; text-align: left; padding: 8px 12px; font-size: 13px; color: #555; }
  td { padding: 8px 12px; border-top: 1px solid #eee; font-size: 13px; }
  tr:hover td { background: #fafafa; }
  .tests { background: #FFF8E1; border-left: 4px solid #FF8F00; padding: 14px 18px; border-radius: 4px; margin-bottom: 20px; }
  .tests h3 { margin: 0 0 8px; color: #E65100; font-size: 14px; }
  .tests ul { margin: 0; padding-left: 20px; }
  .tests li { font-size: 13px; margin-bottom: 4px; }
  .footer { margin-top: 30px; padding-top: 14px; border-top: 1px solid #ddd; font-size: 12px; color: #888; }
  @media print {
    body { margin: 10px; }
    .stage { break-inside: avoid; }
  }
</style>
</head>
<body>
<h1>Программа здоровья Siberian Wellness</h1>
<div class="meta">
  <strong>Клиент:</strong> ${program.clientName} &nbsp;|&nbsp;
  <strong>Составлена:</strong> $dateFormatted &nbsp;|&nbsp;
  <strong>Длительность:</strong> 60 дней
</div>
$testsHtml
${stagesHtml.toString()}
<div class="footer">
  Программа составлена консультантом Siberian Wellness и носит информационный характер.<br>
  Перед применением проконсультируйтесь с лечащим врачом.<br>
  Для печати или сохранения в PDF: Ctrl+P → «Сохранить как PDF».
</div>
</body>
</html>''';
}
