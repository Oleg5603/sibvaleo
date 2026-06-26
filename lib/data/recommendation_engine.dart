import '../models/product.dart';
import '../models/client.dart';

class RecommendationEngine {
  final List<Product> allProducts;
  static const int _introGapDays = 3; // минимум дней между вводом препаратов
  static const int _maxPerReception = 3; // максимум одновременных препаратов
  static const int _programDays = 60; // длина программы

  RecommendationEngine(this.allProducts);

  /// Подбирает препараты по жалобам и диагнозам клиента
  List<ScoredProduct> matchProducts(Client client) {
    final clientConditions = {...client.symptoms, ...client.diagnoses};
    final scored = <ScoredProduct>[];

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
        // Проверка возрастных ограничений
        final dose = p.doseForAge(client.age);
        if (dose == 'Не рекомендовано до 6 лет' || dose == 'Не рекомендовано') {
          continue;
        }
        scored.add(ScoredProduct(product: p, score: score, matchedOn: matchedOn));
      }
    }

    // Сортировка: по этапу (1 сначала), затем по очкам
    scored.sort((a, b) {
      final stageComp = a.product.stage.compareTo(b.product.stage);
      if (stageComp != 0) return stageComp;
      return b.score.compareTo(a.score);
    });

    return scored;
  }

  /// Строит 60-дневную программу из выбранных препаратов
  Program buildProgram(Client client, List<Product> selected) {
    // Сортируем по этапам: очищение → защита → питание → восстановление
    final sorted = List<Product>.from(selected)
      ..sort((a, b) => a.stage.compareTo(b.stage));

    final entries = <ProgramEntry>[];
    int currentDay = 1;
    int activeCount = 0; // сколько препаратов сейчас одновременно

    for (final p in sorted) {
      if (currentDay > _programDays) break;

      // Если одновременно уже 3 препарата — ждём пока один не закончится
      while (activeCount >= _maxPerReception && currentDay <= _programDays) {
        // Найти ближайший конец уже идущего препарата
        int earliestEnd = _programDays + 1;
        for (final e in entries) {
          if (e.endDay >= currentDay && e.endDay < earliestEnd) {
            earliestEnd = e.endDay;
          }
        }
        currentDay = earliestEnd + _introGapDays;
        // Пересчитываем активные
        activeCount = entries.where((e) => e.endDay >= currentDay).length;
      }

      if (currentDay > _programDays) break;

      final duration = p.minCourseDays.clamp(1, _programDays - currentDay + 1);
      final dose = p.doseForAge(client.age);

      entries.add(ProgramEntry(
        productId: p.id,
        productName: p.name,
        startDay: currentDay,
        durationDays: duration,
        dose: dose,
        timesPerDay: p.frequencyPerDay,
        stageName: p.stageName,
        stage: p.stage,
      ));

      // Следующий препарат вводится через 3-4 дня
      currentDay += _introGapDays;
      activeCount = entries.where((e) => e.endDay >= currentDay).length;
    }

    // Собираем рекомендуемые анализы
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
