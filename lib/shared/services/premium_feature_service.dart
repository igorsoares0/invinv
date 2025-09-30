import '../models/models.dart';
import 'simple_subscription_service.dart';

class PremiumFeatureService {
  final SimpleSubscriptionService _subscriptionService = SimpleSubscriptionService();

  static final PremiumFeatureService _instance = PremiumFeatureService._internal();
  factory PremiumFeatureService() => _instance;
  PremiumFeatureService._internal();

  Future<bool> hasFeature(PremiumFeature feature) async {
    final status = await _subscriptionService.getSubscriptionStatus();

    if (!status.isPremium || !status.isActive || status.isExpired) {
      return false;
    }

    switch (feature) {
      case PremiumFeature.unlimitedInvoices:
        return status.hasUnlimitedInvoices;
      case PremiumFeature.noWatermark:
        return status.canRemoveWatermark;
      case PremiumFeature.logoUpload:
        return status.canUploadLogo;
      case PremiumFeature.premiumTemplates:
        return status.canUsePremiumTemplates;
    }
  }

  Future<bool> hasUnlimitedInvoices() async {
    return hasFeature(PremiumFeature.unlimitedInvoices);
  }

  Future<bool> canRemoveWatermark() async {
    return hasFeature(PremiumFeature.noWatermark);
  }

  Future<bool> canUploadLogo() async {
    return hasFeature(PremiumFeature.logoUpload);
  }

  Future<bool> canUsePremiumTemplates() async {
    return hasFeature(PremiumFeature.premiumTemplates);
  }

  Future<bool> canCreateInvoice() async {
    return _subscriptionService.canCreateInvoice();
  }

  Future<int> getRemainingFreeInvoices() async {
    return _subscriptionService.getRemainingFreeInvoices();
  }

  Future<bool> shouldShowWatermark() async {
    return !(await canRemoveWatermark());
  }

  Future<bool> canUseTemplate(InvoiceTemplateType templateType) async {
    switch (templateType) {
      case InvoiceTemplateType.classic:
        return true; // Always available
      case InvoiceTemplateType.modern:
      case InvoiceTemplateType.elegant:
        return canUsePremiumTemplates();
    }
  }

  Future<List<InvoiceTemplateType>> getAvailableTemplates() async {
    final canUsePremium = await canUsePremiumTemplates();

    if (canUsePremium) {
      return InvoiceTemplateType.values;
    }

    return [InvoiceTemplateType.classic];
  }

  Future<FeatureGateResult> checkFeatureAccess(PremiumFeature feature) async {
    final hasAccess = await hasFeature(feature);

    if (hasAccess) {
      return FeatureGateResult.allowed();
    }

    final status = await _subscriptionService.getSubscriptionStatus();

    String title = feature.displayName;
    String description = feature.description;
    String actionText = 'Upgrade to Premium';

    switch (feature) {
      case PremiumFeature.unlimitedInvoices:
        if (status.hasReachedFreeLimit) {
          title = 'Invoice Limit Reached';
          description = 'You\'ve reached the limit of ${status.invoiceCount} free invoices. Upgrade to create unlimited invoices.';
        } else {
          final remaining = status.remainingFreeInvoices;
          description = 'You have $remaining free invoice${remaining != 1 ? 's' : ''} remaining. Upgrade for unlimited invoices.';
        }
        break;

      case PremiumFeature.noWatermark:
        title = 'Remove Watermark';
        description = 'Upgrade to Premium to generate clean PDFs without the "powered by invoice box" watermark.';
        break;

      case PremiumFeature.logoUpload:
        title = 'Add Your Logo';
        description = 'Upgrade to Premium to add your company logo to invoices and make them more professional.';
        break;

      case PremiumFeature.premiumTemplates:
        title = 'Premium Templates';
        description = 'Upgrade to Premium to access Modern and Elegant invoice templates with enhanced designs.';
        break;
    }

    return FeatureGateResult.blocked(
      title: title,
      description: description,
      actionText: actionText,
      feature: feature,
    );
  }

  Future<void> incrementInvoiceCount() async {
    await _subscriptionService.incrementInvoiceCount();
  }

  Stream<SubscriptionStatus> get subscriptionStatusStream {
    return _subscriptionService.statusStream;
  }
}

class FeatureGateResult {
  final bool isAllowed;
  final String? title;
  final String? description;
  final String? actionText;
  final PremiumFeature? blockedFeature;

  const FeatureGateResult._({
    required this.isAllowed,
    this.title,
    this.description,
    this.actionText,
    this.blockedFeature,
  });

  factory FeatureGateResult.allowed() {
    return const FeatureGateResult._(isAllowed: true);
  }

  factory FeatureGateResult.blocked({
    required String title,
    required String description,
    required String actionText,
    required PremiumFeature feature,
  }) {
    return FeatureGateResult._(
      isAllowed: false,
      title: title,
      description: description,
      actionText: actionText,
      blockedFeature: feature,
    );
  }
}