import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/client.dart';

class AppStorage {
  static const _clientsFile = 'clients.json';
  static const _programsFile = 'programs.json';

  static Future<String> get _dir async {
    final d = await getApplicationDocumentsDirectory();
    return d.path;
  }

  // ─── Клиенты ──────────────────────────────────────────────
  static Future<List<Client>> loadClients() async {
    try {
      final path = '${await _dir}/$_clientsFile';
      final f = File(path);
      if (!await f.exists()) return [];
      final raw = await f.readAsString();
      final list = jsonDecode(raw) as List;
      return list.map((j) => Client.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveClients(List<Client> clients) async {
    final path = '${await _dir}/$_clientsFile';
    await File(path).writeAsString(
      jsonEncode(clients.map((c) => c.toJson()).toList()),
    );
  }

  static Future<void> upsertClient(Client client) async {
    final clients = await loadClients();
    final idx = clients.indexWhere((c) => c.id == client.id);
    if (idx >= 0) {
      clients[idx] = client;
    } else {
      clients.add(client);
    }
    await saveClients(clients);
  }

  static Future<void> deleteClient(String id) async {
    final clients = await loadClients();
    clients.removeWhere((c) => c.id == id);
    await saveClients(clients);
  }

  // ─── Программы ────────────────────────────────────────────
  static Future<List<Program>> loadPrograms() async {
    try {
      final path = '${await _dir}/$_programsFile';
      final f = File(path);
      if (!await f.exists()) return [];
      final raw = await f.readAsString();
      final list = jsonDecode(raw) as List;
      return list.map((j) => Program.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> upsertProgram(Program program) async {
    final programs = await loadPrograms();
    final idx = programs.indexWhere((p) => p.id == program.id);
    if (idx >= 0) {
      programs[idx] = program;
    } else {
      programs.add(program);
    }
    final path = '${await _dir}/$_programsFile';
    await File(path).writeAsString(
      jsonEncode(programs.map((p) => p.toJson()).toList()),
    );
  }

  static Future<Program?> latestProgramForClient(String clientId) async {
    final all = await loadPrograms();
    final mine = all.where((p) => p.clientId == clientId).toList();
    if (mine.isEmpty) return null;
    mine.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine.first;
  }
}
