import 'package:equatable/equatable.dart';
import 'subscription_plan.dart';

class SubscriptionStatus extends Equatable {
  final bool isPremium;
  final SubscriptionPlan plan;
  final DateTime? expiresAt;
  final bool isActive;
  final int invoiceCount;
  final DateTime updatedAt;

  const SubscriptionStatus({
    required this.isPremium,
    required this.plan,
    this.expiresAt,
    required this.isActive,
    required this.invoiceCount,
    required this.updatedAt,
  });

  factory SubscriptionStatus.free({required int invoiceCount}) {
    return SubscriptionStatus(
      isPremium: false,
      plan: SubscriptionPlan.free,
      expiresAt: null,
      isActive: true,
      invoiceCount: invoiceCount,
      updatedAt: DateTime.now(),
    );
  }

  factory SubscriptionStatus.premium({
    required SubscriptionPlan plan,
    required DateTime expiresAt,
    required int invoiceCount,
    bool isActive = true,
  }) {
    return SubscriptionStatus(
      isPremium: true,
      plan: plan,
      expiresAt: expiresAt,
      isActive: isActive,
      invoiceCount: invoiceCount,
      updatedAt: DateTime.now(),
    );
  }

  bool get hasUnlimitedInvoices => isPremium && isActive;
  bool get canRemoveWatermark => isPremium && isActive;
  bool get canUploadLogo => isPremium && isActive;
  bool get canUsePremiumTemplates => isPremium && isActive;

  bool get hasReachedFreeLimit => !isPremium && invoiceCount >= 10;
  int get remainingFreeInvoices => isPremium ? -1 : (10 - invoiceCount).clamp(0, 10);

  bool get isExpired {
    if (!isPremium || expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isExpiringSoon {
    if (!isPremium || expiresAt == null) return false;
    final now = DateTime.now();
    final daysUntilExpiry = expiresAt!.difference(now).inDays;
    return daysUntilExpiry <= 3;
  }

  String get statusText {
    if (!isPremium) {
      return 'Free Plan';
    }

    if (isExpired) {
      return 'Expired';
    }

    if (isExpiringSoon) {
      final daysLeft = expiresAt!.difference(DateTime.now()).inDays;
      return 'Expires in $daysLeft day${daysLeft != 1 ? 's' : ''}';
    }

    return plan.displayName;
  }

  SubscriptionStatus copyWith({
    bool? isPremium,
    SubscriptionPlan? plan,
    DateTime? expiresAt,
    bool? isActive,
    int? invoiceCount,
    DateTime? updatedAt,
  }) {
    return SubscriptionStatus(
      isPremium: isPremium ?? this.isPremium,
      plan: plan ?? this.plan,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      invoiceCount: invoiceCount ?? this.invoiceCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_premium': isPremium,
      'plan_type': plan.value,
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
      'invoice_count': invoiceCount,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      isPremium: json['is_premium'] ?? false,
      plan: SubscriptionPlanExtension.fromString(json['plan_type'] ?? 'free'),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      isActive: json['is_active'] ?? false,
      invoiceCount: json['invoice_count'] ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  List<Object?> get props => [
    isPremium,
    plan,
    expiresAt,
    isActive,
    invoiceCount,
    updatedAt,
  ];
}