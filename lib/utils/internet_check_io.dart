import 'dart:io';

Future<bool> checkInternetConnection() async {
  try {
    final result = await InternetAddress.lookup(
      'google.com',
    ).timeout(const Duration(seconds: 4));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
