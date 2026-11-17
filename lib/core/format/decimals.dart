/// Números con coma decimal, como se escriben en español.
abstract final class Decimals {
  /// Lee «8,5», «8.5» o «8». Devuelve `null` si no es un número.
  static double? parse(String text) {
    final clean = text.trim().replaceAll(',', '.');
    if (clean.isEmpty) return null;
    final value = double.tryParse(clean);
    return value == null || value.isNaN || value.isInfinite ? null : value;
  }

  /// Muestra hasta [maxDecimals] decimales, sin ceros de relleno:
  /// 4 → «4», 0.1 → «0,1», 3.75 → «3,75», 4.249999 → «4,25».
  static String format(double value, {int maxDecimals = 2}) {
    var text = value.toStringAsFixed(maxDecimals);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    if (text == '-0') text = '0';
    return text.replaceAll('.', ',');
  }

  /// Redondea a [decimals] para quitar el ruido de la aritmética binaria
  /// (0,1 + 0,2 = 0,30000000000000004).
  static double round(double value, [int decimals = 4]) {
    final factor = _pow10(decimals);
    return (value * factor).roundToDouble() / factor;
  }

  static double _pow10(int n) {
    var result = 1.0;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }
}
