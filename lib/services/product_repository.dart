import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product.dart';

class ProductRepository {
  ProductRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _colForUid(String uid) {
    return _firestore.collection('users').doc(uid).collection('products');
  }

  /// Flux lié à l’auth : évite une écoute Firestore avant que le jeton utilisateur soit prêt.
  Stream<List<Product>> watchProducts() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<List<Product>>.value(<Product>[]);
      }
      return Stream.fromFuture(user.getIdToken()).asyncExpand((_) {
        return _colForUid(user.uid)
            .orderBy('expirationDate')
            .snapshots()
            .map((snap) => snap.docs.map(Product.fromDoc).toList());
      });
    });
  }

  Future<List<Product>> fetchProductsOnce() async {
    final user = _auth.currentUser;
    if (user == null) return <Product>[];
    await user.getIdToken();
    final snap =
        await _colForUid(user.uid).orderBy('expirationDate').get();
    return snap.docs.map(Product.fromDoc).toList();
  }

  Future<String> addProduct({
    required String name,
    required DateTime expirationDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Utilisateur non connecté');
    }
    await user.getIdToken();
    final ref = await _colForUid(user.uid).add({
      'name': name.trim(),
      'expirationDate': Timestamp.fromDate(
        DateTime(expirationDate.year, expirationDate.month, expirationDate.day),
      ),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
