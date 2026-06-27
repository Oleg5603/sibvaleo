// Activation code system.
// Format: SVLnnn-mmmmm  (e.g. SVL001-62277)
//   nnn  = client number 001..999
//   mmmmm = checksum for device slot (1 = PC, 2 = phone)
class Activation {
  static const _salt = 54321;
  static const _k1 = 37;
  static const _k2 = 7919; // prime → good distribution

  static int _cs(int n, int slot) =>
      (n * _k1 + slot * _k2 + _salt) % 100000;

  /// Returns true if [raw] is a valid activation code (slot 1 or 2).
  static bool isValidCode(String raw) {
    final c = raw.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
    if (c.length != 11 || !RegExp(r'^SVL\d{8}$').hasMatch(c)) return false;
    final n = int.parse(c.substring(3, 6));
    final v = int.parse(c.substring(6, 11));
    return v == _cs(n, 1) || v == _cs(n, 2);
  }

  /// Generates activation code for [clientNum] (1..999) and [deviceSlot] (1=PC, 2=phone).
  static String generateCode(int clientNum, int deviceSlot) {
    final n = clientNum.clamp(1, 999);
    final v = _cs(n, deviceSlot.clamp(1, 2));
    return 'SVL${n.toString().padLeft(3, '0')}-${v.toString().padLeft(5, '0')}';
  }

  /// Returns [pcCode, phoneCode] for a client.
  static List<String> generatePair(int clientNum) => [
        generateCode(clientNum, 1),
        generateCode(clientNum, 2),
      ];
}
