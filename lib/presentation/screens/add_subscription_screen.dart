import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/subscription.dart';
import '../providers/subscription_providers.dart';
import '../providers/auth_providers.dart';

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  final Subscription? existingSubscription;

  const AddSubscriptionScreen({super.key, this.existingSubscription});

  @override
  ConsumerState<AddSubscriptionScreen> createState() =>
      _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState
    extends ConsumerState<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;

  late String _currency;
  late BillingCycle _billingCycle;
  late SubscriptionCategory _category;
  DateTime? _nextBillingDate;
  bool _isSaving = false;

  bool get _isEditing => widget.existingSubscription != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingSubscription;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _priceController =
        TextEditingController(text: existing?.price.toString() ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');
    _currency = existing?.currency ?? 'USD';
    _billingCycle = existing?.billingCycle ?? BillingCycle.monthly;
    _category = existing?.category ?? SubscriptionCategory.entertainment;
    _nextBillingDate = existing?.nextBillingDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _nextBillingDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nextBillingDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('field_required'.tr()),
        ),
      );
      return;
    }

    // جلب معرف المستخدم الحالي بشكل صحيح من AsyncValue
    final currentUserId = ref.read(authStateProvider).value;

    final userId = widget.existingSubscription?.userId ?? currentUserId;

    // فحص أمان للتحقق من وجود المستخدم
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_occurred'.tr()),
        ),
      );
      return;
    }

    final subscription = Subscription(
      id: widget.existingSubscription?.id ?? '',
      userId: userId,
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      currency: _currency,
      billingCycle: _billingCycle,
      category: _category,
      nextBillingDate: _nextBillingDate!,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: widget.existingSubscription?.createdAt ?? DateTime.now(),
    );

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(subscriptionRepositoryProvider);

      if (_isEditing) {
        await repository
            .updateSubscription(subscription)
            .timeout(const Duration(seconds: 10));
      } else {
        await repository
            .addSubscription(subscription)
            .timeout(const Duration(seconds: 10));
      }

      if (!mounted) return;

      // العودة بعد نجاح الحفظ
      Navigator.of(context).pop(true);
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_occurred'.tr()),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_occurred'.tr()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? 'edit_subscription'.tr()
            : 'add_subscription'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'name'.tr()),
                validator: (value) =>
                (value == null || value.trim().isEmpty)
                    ? 'field_required'.tr()
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'price'.tr()),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'field_required'.tr();
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'invalid_price'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: InputDecoration(labelText: 'currency'.tr()),
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'SYP', child: Text('SYP')),
                  DropdownMenuItem(value: 'TRY', child: Text('TRY')),
                ],
                onChanged: (value) => setState(() => _currency = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BillingCycle>(
                value: _billingCycle,
                decoration: InputDecoration(labelText: 'billing_cycle'.tr()),
                items: [
                  DropdownMenuItem(
                    value: BillingCycle.monthly,
                    child: Text('monthly'.tr()),
                  ),
                  DropdownMenuItem(
                    value: BillingCycle.yearly,
                    child: Text('yearly'.tr()),
                  ),
                ],
                onChanged: (value) => setState(() => _billingCycle = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SubscriptionCategory>(
                value: _category,
                decoration: InputDecoration(labelText: 'category'.tr()),
                items: [
                  DropdownMenuItem(
                    value: SubscriptionCategory.entertainment,
                    child: Text('entertainment'.tr()),
                  ),
                  DropdownMenuItem(
                    value: SubscriptionCategory.productivity,
                    child: Text('productivity'.tr()),
                  ),
                  DropdownMenuItem(
                    value: SubscriptionCategory.other,
                    child: Text('other'.tr()),
                  ),
                ],
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _nextBillingDate == null
                      ? 'next_billing_date'.tr()
                      : '${'next_billing_date'.tr()}: ${_nextBillingDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(labelText: 'note_optional'.tr()),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : Text('save'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}