import '../entities/subscription.dart';

abstract class SubscriptionRepository {
  Stream<List<Subscription>> getSubscriptions(String userId);
  Future<void> addSubscription(Subscription subscription);
  Future<void> updateSubscription(Subscription subscription);
  Future<void> deleteSubscription(String id);
}