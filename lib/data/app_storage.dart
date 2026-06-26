import 'dart:convert';
import 'dart:io';

import '../models/client.dart';

// Хранение через dart:io напрямую — без плагинов, без симлинков, все платформы
class AppStorage {
  static Directory get _dir {
    final String base;
    if (Platform.isWindows) {
      base = Platform.environment['LOCALAPPDATA'] ??
          Platform.environment['APPDATA'] ?? '.';
    } else if (Platform.isMacOS) {
      base = '${Platform.environment['HOME']}/Library/Application Support';
    } else if (Platform.isLinux) {
      base = '${Platform.environment['HOME']}/.local/share';
    } else {
      base = '/data/data/com.sibvaleo.sibvaleo/files';
    }
    final dir = Directory('$base/sibvaleo');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static File _file(String name) => File('${_dir.path}/$name');

  // ─── Клиенты ──────────────────────────────────────────────
  static Future<List<Client>> loadClients() async {
    try {
      final f = _file('clients.json');
      if (!f.existsSync()) return [];
      final list = jsonDecode(await f.readAsString()) as List;
      return list.map((j) => Client.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveClients(List<Client> clients) async {
    await _file('clients.json').writeAsString(
      jsonEncode(clients.map((c) => c.toJson()).toList()),
    );
  }

  static Future<void> upsertClient(Client client) async {
    final clients = await loadClients();
    final idx = clients.indexWhere((c) => c.id == client.id);
    if (idx >= 0) { clients[idx] = client; } else { clients.add(client); }
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
      final f = _file('programs.json');
      if (!f.existsSync()) return [];
      final list = jsonDecode(await f.readAsString()) as List;
      return list.map((j) => Program.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> upsertProgram(Program program) async {
    final programs = await loadPrograms();
    final idx = programs.indexWhere((p) => p.id == program.id);
    if (idx >= 0) { programs[idx] = program; } else { programs.add(program); }
    await _file('programs.json').writeAsString(
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
