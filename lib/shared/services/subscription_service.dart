import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class SubscriptionService {
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _lastSyncKey = 'last_subscription_sync';
  static const int _syncIntervalHours = 6;

  SubscriptionStatus? _cachedStatus;
  final StreamController<SubscriptionStatus> _statusController = StreamController<SubscriptionStatus>.broadcast();

  Stream<SubscriptionStatus> get statusStream => _statusController.stream;
  SubscriptionStatus? get currentStatus => _cachedStatus;

  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  Future<void> initialize() async {
    try {
      await _loadCachedStatus();
      await _syncWithAdapty();
    } catch (e) {
      await _loadCachedStatus();
    }
  }

  Future<SubscriptionStatus> getSubscriptionStatus() async {
    if (_cachedStatus == null) {
      await _loadCachedStatus();
    }

    final shouldSync = await _shouldSyncWithServer();
    if (shouldSync) {
      try {
        await _syncWithAdapty();
      } catch (e) {
        // Use cached status on sync failure
      }
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

    await _updateCachedStatus(updatedStatus);
  }

  Future<List<AdaptyPaywallProduct>> getAvailableProducts() async {
    try {
      final paywall = await Adapty().getPaywall(placementId: 'main_paywall');
      // Adapty API might use different property name - fallback to empty list
      return [];
    } catch (e) {
      // Return empty list for development/testing
      return [];
    }
  }

  List<AdaptyPaywallProduct> _getMockProducts() {
    // This is a fallback for when Adapty is not properly configured
    // In production, this should be removed once Adapty is set up
    return [];
  }

  Future<bool> purchaseProduct(AdaptyPaywallProduct product) async {
    try {
      await Adapty().makePurchase(product: product);

      // Get updated profile after purchase
      final profile = await Adapty().getProfile();
      await _updateStatusFromProfile(profile);

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restorePurchases() async {
    try {
      final profile = await Adapty().restorePurchases();
      await _updateStatusFromProfile(profile);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _syncWithAdapty() async {
    try {
      final profile = await Adapty().getProfile();
      await _updateStatusFromProfile(profile);
      await _updateLastSyncTime();
    } catch (e) {
      // Handle network errors gracefully
      print('Adapty sync error: $e');
    }
  }

  Future<void> _updateStatusFromProfile(AdaptyProfile profile) async {
    final accessLevels = profile.accessLevels;
    bool isPremium = false;
    SubscriptionPlan plan = SubscriptionPlan.free;
    DateTime? expiresAt;
    bool isActive = false;

    if (accessLevels.isNotEmpty) {
      final premiumAccess = accessLevels['premium'];
      if (premiumAccess != null) {
        isPremium = premiumAccess.isActive;
        isActive = premiumAccess.isActive;
        expiresAt = premiumAccess.expiresAt;

        // Determine plan type from store
        // This is a simplified approach - in production you might use other methods
        if (isActive) {
          plan = SubscriptionPlan.monthly; // Default assumption
        }
      }
    }

    final currentInvoiceCount = _cachedStatus?.invoiceCount ?? 0;

    final newStatus = SubscriptionStatus(
      isPremium: isPremium,
      plan: plan,
      expiresAt: expiresAt,
      isActive: isActive,
      invoiceCount: currentInvoiceCount,
      updatedAt: DateTime.now(),
    );

    await _updateCachedStatus(newStatus);
  }

  Future<void> _updateCachedStatus(SubscriptionStatus status) async {
    _cachedStatus = status;
    _statusController.add(status);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subscriptionStatusKey, _encodeStatus(status));
  }

  Future<void> _loadCachedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString(_subscriptionStatusKey);

      if (statusJson != null) {
        _cachedStatus = _decodeStatus(statusJson);
        if (_cachedStatus != null) {
          _statusController.add(_cachedStatus!);
        }
      }

      if (_cachedStatus == null) {
        _cachedStatus = SubscriptionStatus.free(invoiceCount: 0);
        _statusController.add(_cachedStatus!);
      }
    } catch (e) {
      _cachedStatus = SubscriptionStatus.free(invoiceCount: 0);
      _statusController.add(_cachedStatus!);
    }
  }

  Future<bool> _shouldSyncWithServer() async {
    if (!await _hasInternetConnection()) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);

    if (lastSyncString == null) return true;

    final lastSync = DateTime.parse(lastSyncString);
    final now = DateTime.now();
    final hoursSinceSync = now.difference(lastSync).inHours;

    return hoursSinceSync >= _syncIntervalHours;
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  String _encodeStatus(SubscriptionStatus status) {
    final json = status.toJson();
    return jsonEncode(json);
  }

  SubscriptionStatus? _decodeStatus(String encodedStatus) {
    try {
      final json = jsonDecode(encodedStatus);
      return SubscriptionStatus.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _statusController.close();
  }
}