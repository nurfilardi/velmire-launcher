class Validators {
  static String? nick(String raw) {
    final value = raw.trim();
    if (value.length < 3 || value.length > 20 || value.contains(RegExp(r'\s'))) {
      return 'Nick 3–20 karakter, tanpa spasi.';
    }
    return null;
  }

  static String? host(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'Alamat IP/domain wajib diisi.';
    if (value.contains(RegExp(r'\s')) || value.contains('/') || value.contains('://')) {
      return 'Masukkan IP atau domain tanpa spasi/skema.';
    }
    return null;
  }

  static String? port(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null || value < 1 || value > 65535) return 'Port harus 1–65535.';
    return null;
  }
}
