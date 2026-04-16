import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/barang_models/katalog_model.dart';
import '../../models/barang_models/konsinyasi_model.dart';

class ConsignmentRequestController {
  final FirebaseFirestore firestore;
  final String collectionName = 'consignment_requests';

  ConsignmentRequestController({required this.firestore});

  Stream<QuerySnapshot> getRequestsStream() {
    return firestore
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getRequestsStreamForUser(String clientId) {
    return firestore
        .collection(collectionName)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>> createRequest({
    required List<CatalogModel> catalogItems,
    required List<int> quantities,
    required String clientId,
    required String clientName,
    String clientAddress = '',
    required String clientEmail,
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
        clientId: clientId,
        clientName: clientName,
        clientAddress: clientAddress,
        clientEmail: clientEmail,
        items: items,
      );

      await firestore.collection(collectionName).add(model.toMap());
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createDirectReceivedRequest({
    required String clientId,
    required String clientName,
    String clientAddress = '',
    required String clientEmail,
    required List<ConsignmentItemEntry> items,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final processorName = user?.displayName ?? user?.email ?? 'Operator';
      final now = DateTime.now();

      final model = ConsignmentRequestModel(
        id: '',
        clientId: clientId,
        clientName: clientName,
        clientAddress: clientAddress,
        clientEmail: clientEmail,
        status: ConsignmentBatchStatus.received,
        items: items,
        packedBy: processorName,
        receivedBy: processorName,
        receivedAt: now,
      );

      final docData = model.toMap();
      docData['createdAt'] = FieldValue.serverTimestamp();

      await firestore.collection(collectionName).add(docData);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

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

      final isAllPending = updatedItems.every(
        (i) => i.itemStatus == ConsignmentItemStatus.pending,
      );
      final newBatchStatus = isAllPending
          ? ConsignmentBatchStatus.pending
          : ConsignmentBatchStatus.processing;

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

  Future<Map<String, dynamic>> cancelAllItems(String docId) async {
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

      final updatedItems = model.items
          .map(
            (item) => item.copyWith(
              itemStatus: ConsignmentItemStatus.pending,
              approvedQty: null,
            ),
          )
          .toList();

      await ref.update({
        'items': updatedItems.map((e) => e.toMap()).toList(),
        'status': ConsignmentBatchStatus.pending.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> packBatch(String docId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final packerName = user?.displayName ?? user?.email ?? 'Operator';

      await firestore.collection(collectionName).doc(docId).update({
        'status': ConsignmentBatchStatus.packed.name,
        'packedBy': packerName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectBatch(String docId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final rejectorName = user?.displayName ?? user?.email ?? 'Operator';
      final now = FieldValue.serverTimestamp();

      await firestore.collection(collectionName).doc(docId).update({
        'status': ConsignmentBatchStatus.rejected.name,
        'rejectedBy': rejectorName,
        'receivedAt': now,
        'updatedAt': now,
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> receiveBatch(String docId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final receiverName = user?.displayName ?? user?.email ?? 'Operator';
      final now = Timestamp.now();

      final batchSnap = await firestore
          .collection(collectionName)
          .doc(docId)
          .get();
      if (!batchSnap.exists) {
        return {'success': false, 'error': 'Batch tidak ditemukan'};
      }
      final batch = ConsignmentRequestModel.fromMap(
        batchSnap.id,
        batchSnap.data() as Map<String, dynamic>,
      );

      final approvedItems = batch.items
          .where(
            (item) =>
                item.itemStatus == ConsignmentItemStatus.approved ||
                item.itemStatus == ConsignmentItemStatus.partial,
          )
          .toList();

      if (approvedItems.isNotEmpty) {
        // Cari dokumen klien: utamakan clientId, fallback ke userEmail (data lama)
        DocumentReference? clientRef;

        if (batch.clientId.isNotEmpty) {
          final clientDoc = await firestore
              .collection('clients')
              .doc(batch.clientId)
              .get();
          if (clientDoc.exists) {
            clientRef = clientDoc.reference;
          }
        }

        // Fallback untuk data lama yang menggunakan userEmail
        if (clientRef == null && (batch.userEmail?.isNotEmpty == true)) {
          final clientQuery = await firestore
              .collection('clients')
              .where('email', isEqualTo: batch.userEmail)
              .limit(1)
              .get();
          if (clientQuery.docs.isNotEmpty) {
            clientRef = clientQuery.docs.first.reference;
          }
        }

        if (clientRef == null) {
          return {'success': false, 'error': 'Klien tidak ditemukan'};
        }

        await firestore.runTransaction((tx) async {
          final clientSnap = await tx.get(clientRef!);
          final data = clientSnap.data() as Map<String, dynamic>?;
          final rawBorrowed = (data?['borrowedItems'] as List<dynamic>?) ?? [];

          String mergeKey(Map<String, dynamic> raw) {
            final id = raw['catalogId'] as String? ?? '';
            final price = (raw['catalogPrice'] as num?)?.toDouble() ?? 0.0;
            return '${id}_$price';
          }

          final Map<String, Map<String, dynamic>> mergedMap = {
            for (final raw in rawBorrowed.whereType<Map<String, dynamic>>())
              mergeKey(raw): raw,
          };

          for (final item in approvedItems) {
            final qty = item.approvedQty ?? item.quantity;
            final key = '${item.catalogId}_${item.catalogPrice}';
            if (mergedMap.containsKey(key)) {
              final existing = mergedMap[key]!;
              mergedMap[key] = {
                ...existing,
                'quantity':
                    ((existing['quantity'] as num?)?.toInt() ?? 0) + qty,
                'lastReceivedAt': now,
              };
            } else {
              mergedMap[key] = {
                'catalogId': item.catalogId,
                'catalogName': item.catalogName,
                'catalogPrice': item.catalogPrice,
                'catalogCategory': item.catalogCategory,
                'catalogImagePath': item.catalogImagePath,
                'quantity': qty,
                'lastReceivedAt': now,
              };
            }
          }

          tx.update(clientRef, {'borrowedItems': mergedMap.values.toList()});
        });
      }

      await firestore.collection(collectionName).doc(docId).update({
        'status': ConsignmentBatchStatus.received.name,
        'receivedBy': receiverName,
        'receivedAt': now,
        'updatedAt': now,
      });

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteRequest(String id) async {
    try {
      await firestore.collection(collectionName).doc(id).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
