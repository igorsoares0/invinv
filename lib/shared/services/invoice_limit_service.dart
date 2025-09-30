import '../models/models.dart';
import '../../core/database/database_helper.dart';
import 'simple_subscription_service.dart';

class InvoiceLimitService {
  final DatabaseHelper _db = DatabaseHelper();
  final SimpleSubscriptionService _subscriptionService = SimpleSubscriptionService();

  static final InvoiceLimitService _instance = InvoiceLimitService._internal();
  factory InvoiceLimitService() => _instance;
  InvoiceLimitService._internal();

  Future<bool> canCreateInvoice() async {
    final status = await _subscriptionService.getSubscriptionStatus();

    if (status.hasUnlimitedInvoices) {
      return true;
    }

    return !status.hasReachedFreeLimit;
  }

  Future<int> getCurrentInvoiceCount() async {
    final status = await _subscriptionService.getSubscriptionStatus();
    return status.invoiceCount;
  }

  Future<int> getRemainingFreeInvoices() async {
    final status = await _subscriptionService.getSubscriptionStatus();
    return status.remainingFreeInvoices;
  }

  Future<bool> hasReachedLimit() async {
    final status = await _subscriptionService.getSubscriptionStatus();
    return status.hasReachedFreeLimit;
  }

  Future<InvoiceLimitResult> checkCreateInvoicePermission() async {
    final status = await _subscriptionService.getSubscriptionStatus();

    if (status.hasUnlimitedInvoices) {
      return InvoiceLimitResult.allowed();
    }

    if (status.hasReachedFreeLimit) {
      return InvoiceLimitResult.limitReached(
        currentCount: status.invoiceCount,
        limit: 10,
      );
    }

    final remaining = status.remainingFreeInvoices;
    if (remaining <= 2) {
      return InvoiceLimitResult.warning(
        currentCount: status.invoiceCount,
        remaining: remaining,
        limit: 10,
      );
    }

    return InvoiceLimitResult.allowed();
  }

  Future<void> incrementInvoiceCount() async {
    await _subscriptionService.incrementInvoiceCount();
  }

  Future<void> syncInvoiceCountFromDatabase() async {
    try {
      final result = await _db.rawQuery('SELECT COUNT(*) as count FROM invoices');
      final actualCount = result.first['count'] as int? ?? 0;

      await _db.rawUpdate('''
        UPDATE subscription_status
        SET invoice_count = ?,
            updated_at = datetime('now')
        WHERE id = 1
      ''', [actualCount]);

      await _subscriptionService.initialize();
    } catch (e) {
      // Handle error silently
    }
  }

  Stream<SubscriptionStatus> get subscriptionStatusStream {
    return _subscriptionService.statusStream;
  }
}

class InvoiceLimitResult {
  final bool canCreate;
  final int currentCount;
  final int limit;
  final int? remaining;
  final String? title;
  final String? message;
  final InvoiceLimitType type;

  const InvoiceLimitResult._({
    required this.canCreate,
    required this.currentCount,
    required this.limit,
    this.remaining,
    this.title,
    this.message,
    required this.type,
  });

  factory InvoiceLimitResult.allowed() {
    return const InvoiceLimitResult._(
      canCreate: true,
      currentCount: 0,
      limit: 10,
      type: InvoiceLimitType.allowed,
    );
  }

  factory InvoiceLimitResult.warning({
    required int currentCount,
    required int remaining,
    required int limit,
  }) {
    return InvoiceLimitResult._(
      canCreate: true,
      currentCount: currentCount,
      limit: limit,
      remaining: remaining,
      type: InvoiceLimitType.warning,
      title: 'Almost at your limit',
      message: 'You have $remaining free invoice${remaining != 1 ? 's' : ''} remaining. Upgrade to Premium for unlimited invoices.',
    );
  }

  factory InvoiceLimitResult.limitReached({
    required int currentCount,
    required int limit,
  }) {
    return InvoiceLimitResult._(
      canCreate: false,
      currentCount: currentCount,
      limit: limit,
      type: InvoiceLimitType.limitReached,
      title: 'Invoice limit reached',
      message: 'You\'ve reached the limit of $limit free invoices. Upgrade to Premium to create unlimited invoices.',
    );
  }
}

enum InvoiceLimitType {
  allowed,
  warning,
  limitReached,
}