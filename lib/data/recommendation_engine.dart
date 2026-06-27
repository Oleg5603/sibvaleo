import '../models/product.dart';
import '../models/client.dart';

class RecommendationEngine {
  final List<Product> allProducts;
  static const int _introGapDays = 3; // минимум дней между вводом препаратов
  static const int _maxPerReception = 3; // максимум одновременных препаратов
  static const int _programDays = 60; // длина программы

  RecommendationEngine(this.allProducts);

  /// Подбирает препараты по жалобам и диагнозам клиента.
  /// Применяет бонус +1 за каждого синергичного партнёра в подборке.
  List<ScoredProduct> matchProducts(Client client) {
    final clientConditions = {...client.symptoms, ...client.diagnoses};

    // Первый проход: базовый скор
    final baseScores = <String, int>{};
    final matchedOnMap = <String, List<String>>{};

    for (final p in allProducts) {
      int score = 0;
      final matchedOn = <String>[];

      for (final cond in clientConditions) {
        if (p.indications.contains(cond)) {
          score += 2;
          matchedOn.add(cond);
        }
        if (p.symptoms.contains(cond)) {
          score += 1;
          if (!matchedOn.contains(cond)) matchedOn.add(cond);
        }
      }

      if (score > 0) {
        final dose = p.doseForAge(client.age);
        if (dose == 'Не рекомендовано до 6 лет' || dose == 'Не рекомендовано') {
          continue;
        }
        baseScores[p.id] = score;
        matchedOnMap[p.id] = matchedOn;
      }
    }

    // Второй проход: бонус синергии
    final relevant = baseScores.keys.toSet();
    for (final p in allProducts) {
      if (!relevant.contains(p.id)) continue;
      final bonus = p.synergyWith.where(relevant.contains).length;
      if (bonus > 0) baseScores[p.id] = baseScores[p.id]! + bonus;
    }

    // Сборка результата
    final scored = <ScoredProduct>[];
    for (final p in allProducts) {
      final s = baseScores[p.id];
      if (s == null) continue;
      scored.add(ScoredProduct(product: p, score: s, matchedOn: matchedOnMap[p.id] ?? []));
    }

    scored.sort((a, b) {
      final stageComp = a.product.stage.compareTo(b.product.stage);
      if (stageComp != 0) return stageComp;
      return b.score.compareTo(a.score);
    });

    return scored;
  }

  /// Возвращает пары синергии и антагонизма среди [selected].
  List<ProductInteraction> getInteractions(List<Product> selected) {
    final result = <ProductInteraction>[];
    final seen = <String>{};

    for (int i = 0; i < selected.length; i++) {
      for (int j = i + 1; j < selected.length; j++) {
        final a = selected[i];
        final b = selected[j];
        final key = [a.id, b.id]..sort();
        final keyStr = key.join('|');
        if (seen.contains(keyStr)) continue;
        seen.add(keyStr);

        final isSynergy = a.synergyWith.contains(b.id) || b.synergyWith.contains(a.id);
        final isAntag = a.antagonismWith.contains(b.id) || b.antagonismWith.contains(a.id);

        if (isSynergy) result.add(ProductInteraction(a, b, isSynergy: true));
        if (isAntag)   result.add(ProductInteraction(a, b, isSynergy: false));
      }
    }

    // Сначала антагонизмы (важнее)
    result.sort((x, y) => x.isSynergy ? 1 : -1);
    return result;
  }

  // Окно старта для каждого этапа внутри 60-дневной программы
  static const _stageStartDay = {1: 1, 2: 8, 3: 22, 4: 36};

  int _activeAt(List<ProgramEntry> entries, int day) =>
      entries.where((e) => e.startDay <= day && e.endDay >= day).length;

  /// Строит 60-дневную программу из выбранных препаратов.
  /// Каждый этап получает своё окно: 1→д.1, 2→д.8, 3→д.22, 4→д.36.
  /// Это гарантирует присутствие всех 4 этапов на шкале.
  Program buildProgram(Client client, List<Product> selected) {
    final byStage = <int, List<Product>>{};
    for (final p in selected) {
      byStage.putIfAbsent(p.stage, () => []).add(p);
    }

    final entries = <ProgramEntry>[];

    for (int stage = 1; stage <= 4; stage++) {
      final products = byStage[stage] ?? [];
      if (products.isEmpty) continue;

      int day = _stageStartDay[stage]!;

      for (final p in products) {
        if (day > _programDays) break;

        // Сдвигаем вперёд если уже 3 одновременных
        while (_activeAt(entries, day) >= _maxPerReception && day <= _programDays) {
          day++;
        }
        if (day > _programDays) break;

        final duration = p.minCourseDays.clamp(1, _programDays - day + 1);
        entries.add(ProgramEntry(
          productId: p.id,
          productName: p.name,
          startDay: day,
          durationDays: duration,
          dose: p.doseForAge(client.age),
          timesPerDay: p.frequencyPerDay,
          stageName: p.stageName,
          stage: stage,
        ));

        day += _introGapDays;
      }
    }

    // Сортируем по дню начала для красивого отображения
    entries.sort((a, b) => a.startDay.compareTo(b.startDay));

    final tests = _recommendTests(client);

    return Program(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clientId: client.id,
      clientName: client.name,
      steps: entries,
      recommendedTests: tests,
    );
  }

  List<String> _recommendTests(Client client) {
    final tests = <String>{};
    final allConditions = {...client.symptoms, ...client.diagnoses};

    // Базовые анализы всегда
    tests.add('OAK');

    // По системам
    if (allConditions.any((c) => ['hepatitis', 'fatty_liver', 'cholecystitis',
        'боли_в_правом_боку', 'желтушность', 'горечь_во_рту'].contains(c))) {
      tests.addAll(['BH_liver', 'uzi_abdom']);
    }
    if (allConditions.any((c) => ['hypertension', 'atherosclerosis', 'arrhythmia',
        'боли_в_сердце', 'повышенное_давление'].contains(c))) {
      tests.addAll(['BH_lipids', 'echo_heart']);
    }
    if (allConditions.any((c) => ['diabetes_2', 'obesity', 'набор_веса'].contains(c))) {
      tests.add('BH_glucose');
    }
    if (allConditions.any((c) => ['hypothyroidism', 'endemic_goiter',
        'увеличение_щитовидной', 'зябкость'].contains(c))) {
      tests.addAll(['TSH_T4', 'uzi_thyroid']);
    }
    if (allConditions.any((c) => ['iron_deficiency_anemia', 'слабость',
        'выпадение_волос', 'бледность'].contains(c))) {
      tests.add('ferritin');
    }
    if (allConditions.any((c) => ['cystitis', 'urinary_infection',
        'цистит', 'боли_в_пояснице_почки'].contains(c))) {
      tests.addAll(['OAM', 'uzi_abdom']);
    }
    if (allConditions.any((c) => ['osteoarthritis', 'rheumatoid_arthritis',
        'боли_в_суставах', 'chronic_inflammation'].contains(c))) {
      tests.add('CRP');
    }
    if (allConditions.any((c) => ['depression', 'бессонница', 'тревога',
        'слабость', 'frequent_colds'].contains(c))) {
      tests.add('vitD');
    }
    if (allConditions.any((c) => ['pms', 'menopause', 'болезненные_месячные',
        'нерегулярный_цикл', 'симптомы_менопаузы'].contains(c))) {
      tests.add('sex_hormones');
    }
    if (allConditions.any((c) => ['prostatitis', 'male_health'].contains(c))) {
      tests.addAll(['testosterone', 'psa']);
    }
    if (allConditions.any((c) => ['arrhythmia', 'мышечные_судороги',
        'бессонница', 'тревога'].contains(c))) {
      tests.add('magnesium_bl');
    }

    return tests.toList();
  }
}

class ScoredProduct {
  final Product product;
  final int score;
  final List<String> matchedOn;
  bool selected;

  ScoredProduct({
    required this.product,
    required this.score,
    required this.matchedOn,
    this.selected = false,
  });
}

class ProductInteraction {
  final Product a;
  final Product b;
  final bool isSynergy;
  const ProductInteraction(this.a, this.b, {required this.isSynergy});
}
