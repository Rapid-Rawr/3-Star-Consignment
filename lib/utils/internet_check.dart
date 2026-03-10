// Conditional import: gunakan dart:io di mobile, stub di web
export 'internet_check_io.dart'
    if (dart.library.html) 'internet_check_web.dart';
