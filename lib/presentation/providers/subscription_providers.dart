import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

import '../../data/repositories/subscription_repository_impl.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: '(default)',
  );
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return SubscriptionRepositoryImpl(firestore);
});

final subscriptionsStreamProvider = StreamProvider<List<Subscription>>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);

  // استخراج قيمة الـ userId من الـ AsyncValue
  final authState = ref.watch(authStateProvider);
  final userId = authState.value;

  // إذا لم يكن هناك مستخدم مسجل -> إرجاع قائمة فارغة
  if (userId == null) {
    return Stream.value([]);
  }

  return repository.getSubscriptions(userId);
});