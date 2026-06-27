import 'dart:convert';
import 'dart:io';
import 'activation.dart';

const int kTrialDays = 4;

class TrialStatus {
  final bool isExpired;
  final int daysLeft; // -1 when isActivated = true
  final bool isActivated;
  final DateTime firstLaunch;
  final DateTime expireDate;

  const TrialStatus({
    required this.isExpired,
    required this.daysLeft,
    this.isActivated = false,
    required this.firstLaunch,
    required this.expireDate,
  });
}

class Trial {
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

  static File get _file => File('${_dir.path}/trial.json');

  static Future<TrialStatus> check() async {
    Map<String, dynamic> data = {};
    DateTime firstLaunch;

    if (_file.existsSync()) {
      try {
        data = Map<String, dynamic>.from(jsonDecode(await _file.readAsString()));
        firstLaunch = DateTime.parse(data['firstLaunch'] as String);
      } catch (_) {
        firstLaunch = DateTime.now();
        data = {'firstLaunch': firstLaunch.toIso8601String()};
        await _file.writeAsString(jsonEncode(data));
      }
    } else {
      firstLaunch = DateTime.now();
      data = {'firstLaunch': firstLaunch.toIso8601String()};
      await _file.writeAsString(jsonEncode(data));
    }

    // Check stored activation code — re-validate on every launch
    final storedCode = data['activationCode'] as String? ?? '';
    if (storedCode.isNotEmpty && Activation.isValidCode(storedCode)) {
      return TrialStatus(
        isExpired: false,
        daysLeft: -1,
        isActivated: true,
        firstLaunch: firstLaunch,
        expireDate: firstLaunch,
      );
    }

    final expireDate = DateTime(
      firstLaunch.year, firstLaunch.month, firstLaunch.day + kTrialDays,
    );
    final now = DateTime.now();
    final daysLeft =
        expireDate.difference(DateTime(now.year, now.month, now.day)).inDays;

    return TrialStatus(
      isExpired: daysLeft <= 0,
      daysLeft: daysLeft.clamp(0, kTrialDays),
      firstLaunch: firstLaunch,
      expireDate: expireDate,
    );
  }

  /// Validates [code] and saves it. Returns true on success.
  static Future<bool> activate(String code) async {
    if (!Activation.isValidCode(code)) return false;
    Map<String, dynamic> data = {};
    if (_file.existsSync()) {
      try {
        data = Map<String, dynamic>.from(jsonDecode(await _file.readAsString()));
      } catch (_) {}
    }
    data['activationCode'] =
        code.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]'), '').isEmpty
            ? code
            : code.trim().toUpperCase();
    await _file.writeAsString(jsonEncode(data));
    return true;
  }
}
