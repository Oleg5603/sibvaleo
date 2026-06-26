class Client {
  final String id;
  String name;
  int age;
  String gender; // 'М' | 'Ж'
  List<String> symptoms;
  List<String> diagnoses;
  String labResults;
  String notes;
  DateTime createdAt;

  Client({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.symptoms = const [],
    this.diagnoses = const [],
    this.labResults = '',
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'gender': gender,
        'symptoms': symptoms,
        'diagnoses': diagnoses,
        'labResults': labResults,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Client.fromJson(Map<String, dynamic> j) => Client(
        id: j['id'],
        name: j['name'],
        age: j['age'],
        gender: j['gender'],
        symptoms: List<String>.from(j['symptoms'] ?? []),
        diagnoses: List<String>.from(j['diagnoses'] ?? []),
        labResults: j['labResults'] ?? '',
        notes: j['notes'] ?? '',
        createdAt: DateTime.parse(j['createdAt']),
      );

  String get ageGroup {
    if (age < 6) return 'infant';
    if (age < 12) return 'child_6_12';
    if (age < 18) return 'child_12_18';
    if (age >= 65) return 'elderly';
    return 'adult';
  }
}

class Program {
  final String id;
  final String clientId;
  final String clientName;
  final List<ProgramEntry> steps;
  final List<String> recommendedTests;
  final DateTime createdAt;
  String notes;

  Program({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.steps,
    this.recommendedTests = const [],
    DateTime? createdAt,
    this.notes = '',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'clientName': clientName,
        'steps': steps.map((s) => s.toJson()).toList(),
        'recommendedTests': recommendedTests,
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
      };

  factory Program.fromJson(Map<String, dynamic> j) => Program(
        id: j['id'],
        clientId: j['clientId'],
        clientName: j['clientName'],
        steps: (j['steps'] as List).map((s) => ProgramEntry.fromJson(s)).toList(),
        recommendedTests: List<String>.from(j['recommendedTests'] ?? []),
        createdAt: DateTime.parse(j['createdAt']),
        notes: j['notes'] ?? '',
      );
}

class ProgramEntry {
  final String productId;
  final String productName;
  final int startDay;
  final int durationDays;
  final String dose;
  final int timesPerDay;
  final String stageName;
  final int stage;

  ProgramEntry({
    required this.productId,
    required this.productName,
    required this.startDay,
    required this.durationDays,
    required this.dose,
    required this.timesPerDay,
    required this.stageName,
    required this.stage,
  });

  int get endDay => startDay + durationDays - 1;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'startDay': startDay,
        'durationDays': durationDays,
        'dose': dose,
        'timesPerDay': timesPerDay,
        'stageName': stageName,
        'stage': stage,
      };

  factory ProgramEntry.fromJson(Map<String, dynamic> j) => ProgramEntry(
        productId: j['productId'],
        productName: j['productName'],
        startDay: j['startDay'],
        durationDays: j['durationDays'],
        dose: j['dose'],
        timesPerDay: j['timesPerDay'],
        stageName: j['stageName'],
        stage: j['stage'],
      );
}
