/// Format angka double menjadi string Rupiah.
/// Contoh: 1500000 → 'Rp 1.500.000'
String formatRupiah(double value) {
  if (value == 0) return 'Rp 0';
  final parts = value.toStringAsFixed(0).split('');
  final result = StringBuffer();
  int count = 0;
  for (int i = parts.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) result.write('.');
    result.write(parts[i]);
    count++;
  }
  return 'Rp ${result.toString().split('').reversed.join()}';
}
