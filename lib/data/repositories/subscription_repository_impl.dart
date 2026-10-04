import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../models/subscription_model.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final FirebaseFirestore _firestore;

  SubscriptionRepositoryImpl(this._firestore);

  CollectionReference get _collection =>
      _firestore.collection('subscriptions');

  @override
  Stream<List<Subscription>> getSubscriptions(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SubscriptionModel.fromMap(
          doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<void> addSubscription(Subscription subscription) async {
    try {
      final docRef = _collection.doc();

      final model = SubscriptionModel(
        id: docRef.id,
        userId: subscription.userId,
        name: subscription.name,
        price: subscription.price,
        currency: subscription.currency,
        billingCycle: subscription.billingCycle,
        category: subscription.category,
        nextBillingDate: subscription.nextBillingDate,
        note: subscription.note,
        createdAt: subscription.createdAt,
      );

      await docRef.set(model.toMap()).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Connection timeout while saving'),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateSubscription(Subscription subscription) async {
    if (subscription.id.isEmpty) {
      throw Exception('Cannot update subscription with an empty ID');
    }

    try {
      final model = SubscriptionModel(
        id: subscription.id,
        userId: subscription.userId,
        name: subscription.name,
        price: subscription.price,
        currency: subscription.currency,
        billingCycle: subscription.billingCycle,
        category: subscription.category,
        nextBillingDate: subscription.nextBillingDate,
        note: subscription.note,
        createdAt: subscription.createdAt,
      );

      await _collection
          .doc(subscription.id)
          .set(model.toMap(), SetOptions(merge: true))
          .timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Connection timeout while updating'),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteSubscription(String id) async {
    if (id.isEmpty) return;
    await _collection.doc(id).delete();
  }
}