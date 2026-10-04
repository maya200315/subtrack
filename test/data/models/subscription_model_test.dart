import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtrack/data/models/subscription_model.dart';
import 'package:subtrack/domain/entities/subscription.dart';

void main() {
  group('SubscriptionModel.fromMap - Happy Path', () {
    test('يحول Map كامل وصحيح لـ SubscriptionModel بنجاح', () {
      final map = {
        'userId': 'user-1',
        'name': 'Netflix',
        'price': 15.99,
        'currency': 'USD',
        'billingCycle': 'monthly',
        'category': 'entertainment',
        'nextBillingDate': Timestamp.fromDate(DateTime(2026, 10, 15)),
        'note': 'اشتراك مشترك مع العائلة',
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      };

      final model = SubscriptionModel.fromMap('sub-1', map);

      expect(model.id, 'sub-1');
      expect(model.userId, 'user-1');
      expect(model.name, 'Netflix');
      expect(model.price, 15.99);
      expect(model.currency, 'USD');
      expect(model.billingCycle, BillingCycle.monthly);
      expect(model.category, SubscriptionCategory.entertainment);
      expect(model.nextBillingDate, DateTime(2026, 10, 15));
      expect(model.note, 'اشتراك مشترك مع العائلة');
    });
  });

  group('SubscriptionModel.fromMap - Edge Cases', () {
    test('يتعامل صح مع note = null (اشتراك بدون ملاحظة)', () {
      final map = {
        'userId': 'user-1',
        'name': 'Spotify',
        'price': 5.99,
        'currency': 'EUR',
        'billingCycle': 'monthly',
        'category': 'entertainment',
        'nextBillingDate': Timestamp.fromDate(DateTime(2026, 10, 1)),
        'note': null,
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      };

      final model = SubscriptionModel.fromMap('sub-2', map);

      expect(model.note, isNull);
    });

    test('يتعامل صح مع سعر صحيح (int) مو عشري (يستخدم num.toDouble)', () {
      final map = {
        'userId': 'user-1',
        'name': 'Gym',
        'price': 20,
        'currency': 'USD',
        'billingCycle': 'monthly',
        'category': 'other',
        'nextBillingDate': Timestamp.fromDate(DateTime(2026, 10, 1)),
        'note': null,
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      };

      final model = SubscriptionModel.fromMap('sub-3', map);

      expect(model.price, 20.0);
      expect(model.price, isA<double>());
    });

    test('يتعامل صح مع دورة الدفع yearly (ليس فقط monthly)', () {
      final map = {
        'userId': 'user-1',
        'name': 'Adobe',
        'price': 120,
        'currency': 'USD',
        'billingCycle': 'yearly',
        'category': 'productivity',
        'nextBillingDate': Timestamp.fromDate(DateTime(2027, 1, 1)),
        'note': null,
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      };

      final model = SubscriptionModel.fromMap('sub-4', map);

      expect(model.billingCycle, BillingCycle.yearly);
      expect(model.category, SubscriptionCategory.productivity);
    });

    test('يتعامل صح مع السعر = صفر (اشتراك مجاني/تجريبي)', () {
      final map = {
        'userId': 'user-1',
        'name': 'Free Trial',
        'price': 0,
        'currency': 'USD',
        'billingCycle': 'monthly',
        'category': 'other',
        'nextBillingDate': Timestamp.fromDate(DateTime(2026, 10, 1)),
        'note': null,
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      };

      final model = SubscriptionModel.fromMap('sub-5', map);

      expect(model.price, 0.0);
    });
  });

  group('SubscriptionModel.toMap', () {
    test('يحول SubscriptionModel لـ Map صحيح (Happy Path)', () {
      final model = SubscriptionModel(
        id: 'sub-6',
        userId: 'user-1',
        name: 'Netflix',
        price: 15.99,
        currency: 'USD',
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        nextBillingDate: DateTime(2026, 10, 15),
        note: 'ملاحظة تجريبية',
        createdAt: DateTime(2026, 9, 1),
      );

      final map = model.toMap();

      expect(map['userId'], 'user-1');
      expect(map['name'], 'Netflix');
      expect(map['price'], 15.99);
      expect(map['currency'], 'USD');
      expect(map['billingCycle'], 'monthly');
      expect(map['category'], 'entertainment');
      expect(map['note'], 'ملاحظة تجريبية');
      expect(map.containsKey('id'), isFalse);
    });

    test('يحول note = null صح لـ Map (بدون ما يرمي خطأ)', () {
      final model = SubscriptionModel(
        id: 'sub-7',
        userId: 'user-1',
        name: 'Spotify',
        price: 5.99,
        currency: 'EUR',
        billingCycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        nextBillingDate: DateTime(2026, 10, 1),
        note: null,
        createdAt: DateTime(2026, 9, 1),
      );

      final map = model.toMap();

      expect(map['note'], isNull);
    });
  });

  group('Round-trip test (fromMap ثم toMap)', () {
    test('البيانات تبقى نفسها بعد التحويل ذهاب وإياب', () {
      final originalMap = {
        'userId': 'user-1',
        'name': 'Netflix',
        'price': 15.99,
        'currency': 'USD',
        'billingCycle': 'monthly',
        'category': 'entertainment',
        'nextBillingDate': Timestamp.fromDate(DateTime(2026, 10, 15)),
        'note': 'test note',
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      };

      final model = SubscriptionModel.fromMap('sub-8', originalMap);
      final resultMap = model.toMap();

      expect(resultMap['userId'], originalMap['userId']);
      expect(resultMap['name'], originalMap['name']);
      expect(resultMap['price'], originalMap['price']);
      expect(resultMap['billingCycle'], originalMap['billingCycle']);
      expect(resultMap['category'], originalMap['category']);
      expect(resultMap['note'], originalMap['note']);
    });
  });
}