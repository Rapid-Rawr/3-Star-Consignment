import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _bucketName = 'Catalog';

  /// Inisialisasi Supabase client — panggil sekali di main()
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<String?> uploadCatalogImage({
    required String catalogId,
    required XFile imageFile,
  }) async {
    try {
      final ext = imageFile.name.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'catalog/$catalogId/$timestamp.$ext';

      final Uint8List bytes = await imageFile.readAsBytes();
      dev.log(
        'Uploading image: $filePath (${bytes.length} bytes)',
        name: 'SupabaseService',
      );

      await _client.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );

      dev.log('Upload success: $filePath', name: 'SupabaseService');
      return filePath;
    } catch (e, st) {
      dev.log(
        'Upload FAILED: $e',
        name: 'SupabaseService',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Ambil public URL dari path file (bucket harus public).
  /// Operasi ini sinkron — tidak perlu API call tambahan.
  static String? getPublicUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    try {
      return _client.storage.from(_bucketName).getPublicUrl(path);
    } catch (e) {
      dev.log('getPublicUrl failed: $e', name: 'SupabaseService');
      return null;
    }
  }

  /// Hapus file gambar dari Storage berdasarkan path-nya.
  static Future<void> deleteCatalogImage(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      await _client.storage.from(_bucketName).remove([path]);
    } catch (e) {
      dev.log('deleteCatalogImage failed: $e', name: 'SupabaseService');
    }
  }

  /// Hapus semua gambar dalam folder catalog/{catalogId}/
  static Future<void> deleteCatalogFolder(String catalogId) async {
    try {
      final folderPath = 'catalog/$catalogId';
      final files = await _client.storage
          .from(_bucketName)
          .list(path: folderPath);
      if (files.isEmpty) return;
      final paths = files.map((f) => '$folderPath/${f.name}').toList();
      await _client.storage.from(_bucketName).remove(paths);
    } catch (e) {
      dev.log('deleteCatalogFolder failed: $e', name: 'SupabaseService');
    }
  }
}
