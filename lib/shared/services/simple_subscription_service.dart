import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Simplified subscription service that works without Adapty SDK
/// This allows the app to function with freemium features even when
/// Adapty is not fully configured yet
class SimpleSubscriptionService {
  static const String _subscriptionStatusKey = 'simple_subscription_status';
  static const String _invoiceCountKey = 'invoice_count';

  SubscriptionStatus? _cachedStatus;
  final StreamController<SubscriptionStatus> _statusController =
      StreamController<SubscriptionStatus>.broadcast();

  Stream<SubscriptionStatus> get statusStream => _statusController.stream;
  SubscriptionStatus? get currentStatus => _cachedStatus;

  static final SimpleSubscriptionService _instance = SimpleSubscriptionService._internal();
  factory SimpleSubscriptionService() => _instance;
  SimpleSubscriptionService._internal();

  Future<void> initialize() async {
    await _loadStatus();
  }

  Future<SubscriptionStatus> getSubscriptionStatus() async {
    if (_cachedStatus == null) {
      await _loadStatus();
    }
    return _cachedStatus ?? SubscriptionStatus.free(invoiceCount: 0);
  }

  Future<bool> isPremiumUser() async {
    final status = await getSubscriptionStatus();
    return status.isPremium && status.isActive && !status.isExpired;
  }

  Future<bool> canCreateInvoice() async {
    final status = await getSubscriptionStatus();
    if (status.hasUnlimitedInvoices) return true;
    return !status.hasReachedFreeLimit;
  }

  Future<int> getRemainingFreeInvoices() async {
    final status = await getSubscriptionStatus();
    return status.remainingFreeInvoices;
  }

  Future<void> incrementInvoiceCount() async {
    if (_cachedStatus == null) return;

    final updatedStatus = _cachedStatus!.copyWith(
      invoiceCount: _cachedStatus!.invoiceCount + 1,
      updatedAt: DateTime.now(),
    );

    await _updateStatus(updatedStatus);
  }

  /// Simulate a premium purchase (for testing purposes)
  Future<bool> simulatePremiumPurchase(SubscriptionPlan plan) async {
    final expiresAt = plan == SubscriptionPlan.annual
        ? DateTime.now().add(const Duration(days: 365))
        : DateTime.now().add(const Duration(days: 30));

    final premiumStatus = SubscriptionStatus.premium(
      plan: plan,
      expiresAt: expiresAt,
      invoiceCount: _cachedStatus?.invoiceCount ?? 0,
    );

    await _updateStatus(premiumStatus);
    return true;
  }

  /// For testing: reset to free plan
  Future<void> resetToFree() async {
    final freeStatus = SubscriptionStatus.free(
      invoiceCount: _cachedStatus?.invoiceCount ?? 0,
    );
    await _updateStatus(freeStatus);
  }

  Future<void> _loadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final invoiceCount = prefs.getInt(_invoiceCountKey) ?? 0;
      final statusJson = prefs.getString(_subscriptionStatusKey);

      if (statusJson != null) {
        // Try to load saved premium status
        final savedStatus = SubscriptionStatus.fromJson(
          Map<String, dynamic>.from(
            // Simple JSON decode simulation
            {'invoice_count': invoiceCount}
          )
        );
        _cachedStatus = savedStatus.copyWith(invoiceCount: invoiceCount);
      } else {
        _cachedStatus = SubscriptionStatus.free(invoiceCount: invoiceCount);
      }

      _statusController.add(_cachedStatus!);
    } catch (e) {
      _cachedStatus = SubscriptionStatus.free(invoiceCount: 0);
      _statusController.add(_cachedStatus!);
    }
  }

  Future<void> _updateStatus(SubscriptionStatus status) async {
    _cachedStatus = status;
    _statusController.add(status);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_invoiceCountKey, status.invoiceCount);

    if (status.isPremium) {
      await prefs.setString(_subscriptionStatusKey, 'premium');
      await prefs.setString('premium_plan', status.plan.value);
      if (status.expiresAt != null) {
        await prefs.setString('expires_at', status.expiresAt!.toIso8601String());
      }
    } else {
      await prefs.remove(_subscriptionStatusKey);
      await prefs.remove('premium_plan');
      await prefs.remove('expires_at');
    }
  }

  void dispose() {
    _statusController.close();
  }
}