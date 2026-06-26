class Product {
  final String id;
  final String name;
  final String series;
  final String form;
  final String category;
  final int stage;
  final String stageName;
  final String composition;
  final String action;
  final List<String> indications;
  final List<String> symptoms;
  final List<String> contraindications;
  final String doseAdult;
  final String? doseChild612;
  final String? doseChild1218;
  final String? doseElderly;
  final String? doseIntensive;
  final int frequencyPerDay;
  final int minCourseDays;
  final int maxCourseDays;
  final String notes;

  const Product({
    required this.id,
    required this.name,
    required this.series,
    required this.form,
    required this.category,
    required this.stage,
    required this.stageName,
    required this.composition,
    required this.action,
    required this.indications,
    required this.symptoms,
    required this.contraindications,
    required this.doseAdult,
    this.doseChild612,
    this.doseChild1218,
    this.doseElderly,
    this.doseIntensive,
    required this.frequencyPerDay,
    required this.minCourseDays,
    required this.maxCourseDays,
    required this.notes,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'],
        name: j['name'],
        series: j['series'],
        form: j['form'],
        category: j['category'],
        stage: j['stage'],
        stageName: j['stage_name'],
        composition: j['composition'],
        action: j['action'],
        indications: List<String>.from(j['indications']),
        symptoms: List<String>.from(j['symptoms']),
        contraindications: List<String>.from(j['contraindications']),
        doseAdult: j['dose_adult'],
        doseChild612: j['dose_child_6_12'],
        doseChild1218: j['dose_child_12_18'],
        doseElderly: j['dose_elderly'],
        doseIntensive: j['dose_intensive'],
        frequencyPerDay: j['frequency_per_day'],
        minCourseDays: j['min_course_days'],
        maxCourseDays: j['max_course_days'],
        notes: j['notes'],
      );

  String doseForAge(int ageyears) {
    if (ageyears < 6) return 'Не рекомендовано до 6 лет';
    if (ageyears < 12) return doseChild612 ?? 'Не рекомендовано';
    if (ageyears < 18) return doseChild1218 ?? doseAdult;
    if (ageyears >= 65) return doseElderly ?? doseAdult;
    return doseAdult;
  }
}

// Одна позиция в программе (шаг)
class ProgramStep {
  final Product product;
  final int startDay;
  final int durationDays;
  final String dose;
  final int timesPerDay;
  bool checked; // отметка о приёме

  ProgramStep({
    required this.product,
    required this.startDay,
    required this.durationDays,
    required this.dose,
    required this.timesPerDay,
    this.checked = false,
  });

  int get endDay => startDay + durationDays - 1;
}
