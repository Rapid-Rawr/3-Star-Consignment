import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/catalog_model.dart';
import '../models/consignment_request_model.dart';

class ConsignmentRequestController {
  final FirebaseFirestore firestore;
  final String collectionName = 'consignment_requests';

  ConsignmentRequestController({required this.firestore});

  /// Stream semua pengajuan (batch), terbaru di atas
  Stream<QuerySnapshot> getRequestsStream() {
    return firestore
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream pengajuan milik user tertentu
  Stream<QuerySnapshot> getRequestsStreamForUser(String userId) {
    return firestore
        .collection(collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Buat satu dokumen pengajuan dari semua item yang dipilih sekaligus
  Future<Map<String, dynamic>> createRequest({
    required List<CatalogModel> catalogItems,
    required List<int> quantities,
    required String userId,
    required String userName,
    required String userEmail,
    String userSchool = '',
  }) async {
    assert(catalogItems.length == quantities.length);
    try {
      final items = List.generate(catalogItems.length, (i) {
        final cat = catalogItems[i];
        return ConsignmentItemEntry(
          catalogId: cat.id,
          catalogName: cat.name,
          catalogPrice: cat.price,
          catalogCategory: cat.category,
          catalogImagePath: cat.imagePath,
          quantity: quantities[i],
        );
      });

      final model = ConsignmentRequestModel(
        id: '',
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        userSchool: userSchool,
        items: items,
      );

      await firestore.collection(collectionName).add(model.toMap());
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update status satu item di dalam array.
  /// Otomatis set batch status ke `processing` jika masih `pending`.
  Future<Map<String, dynamic>> updateItemStatus(
    String docId,
    int itemIndex,
    ConsignmentItemStatus newStatus, {
    int? approvedQty,
  }) async {
    try {
      final ref = firestore.collection(collectionName).doc(docId);
      final snap = await ref.get();
      if (!snap.exists)
        return {'success': false, 'error': 'Dokumen tidak ditemukan'};

      final model = ConsignmentRequestModel.fromMap(
        snap.id,
        snap.data() as Map<String, dynamic>,
      );

      if (model.status == ConsignmentBatchStatus.packed) {
        return {'success': false, 'error': 'Pengajuan sudah dikemas'};
      }

      final updatedItems = List<ConsignmentItemEntry>.from(model.items);
      updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
        itemStatus: newStatus,
        approvedQty: newStatus == ConsignmentItemStatus.partial
            ? approvedQty
            : null,
      );

      final newBatchStatus = model.status == ConsignmentBatchStatus.pending
          ? ConsignmentBatchStatus.processing
          : model.status;

      await ref.update({
        'items': updatedItems.map((e) => e.toMap()).toList(),
        'status': newBatchStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Approve semua item pending dalam satu batch
  Future<Map<String, dynamic>> approveAllPending(String docId) async {
    try {
      final ref = firestore.collection(collectionName).doc(docId);
      final snap = await ref.get();
      if (!snap.exists)
        return {'success': false, 'error': 'Dokumen tidak ditemukan'};

      final model = ConsignmentRequestModel.fromMap(
        snap.id,
        snap.data() as Map<String, dynamic>,
      );

      if (model.status == ConsignmentBatchStatus.packed) {
        return {'success': false, 'error': 'Pengajuan sudah dikemas'};
      }

      final updatedItems = model.items.map((item) {
        if (item.itemStatus == ConsignmentItemStatus.pending) {
          return item.copyWith(itemStatus: ConsignmentItemStatus.approved);
        }
        return item;
      }).toList();

      await ref.update({
        'items': updatedItems.map((e) => e.toMap()).toList(),
        'status': ConsignmentBatchStatus.processing.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Tolak semua item pending dalam satu batch
  Future<Map<String, dynamic>> rejectAllPending(String docId) async {
    try {
      final ref = firestore.collection(collectionName).doc(docId);
      final snap = await ref.get();
      if (!snap.exists)
        return {'success': false, 'error': 'Dokumen tidak ditemukan'};

      final model = ConsignmentRequestModel.fromMap(
        snap.id,
        snap.data() as Map<String, dynamic>,
      );

      if (model.status == ConsignmentBatchStatus.packed) {
        return {'success': false, 'error': 'Pengajuan sudah dikemas'};
      }

      final updatedItems = model.items.map((item) {
        if (item.itemStatus == ConsignmentItemStatus.pending) {
          return item.copyWith(itemStatus: ConsignmentItemStatus.rejected);
        }
        return item;
      }).toList();

      await ref.update({
        'items': updatedItems.map((e) => e.toMap()).toList(),
        'status': ConsignmentBatchStatus.processing.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Kemas: kunci batch, tidak bisa diedit lagi
  Future<Map<String, dynamic>> packBatch(String docId) async {
    try {
      await firestore.collection(collectionName).doc(docId).update({
        'status': ConsignmentBatchStatus.packed.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Hapus seluruh batch
  Future<Map<String, dynamic>> deleteRequest(String id) async {
    try {
      await firestore.collection(collectionName).doc(id).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
