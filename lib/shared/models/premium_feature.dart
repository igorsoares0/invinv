enum PremiumFeature {
  unlimitedInvoices,
  noWatermark,
  logoUpload,
  premiumTemplates,
}

extension PremiumFeatureExtension on PremiumFeature {
  String get value {
    switch (this) {
      case PremiumFeature.unlimitedInvoices:
        return 'unlimited_invoices';
      case PremiumFeature.noWatermark:
        return 'no_watermark';
      case PremiumFeature.logoUpload:
        return 'logo_upload';
      case PremiumFeature.premiumTemplates:
        return 'premium_templates';
    }
  }

  String get displayName {
    switch (this) {
      case PremiumFeature.unlimitedInvoices:
        return 'Unlimited Invoices';
      case PremiumFeature.noWatermark:
        return 'Remove Watermark';
      case PremiumFeature.logoUpload:
        return 'Company Logo';
      case PremiumFeature.premiumTemplates:
        return 'Premium Templates';
    }
  }

  String get description {
    switch (this) {
      case PremiumFeature.unlimitedInvoices:
        return 'Create as many invoices as you need';
      case PremiumFeature.noWatermark:
        return 'Generate clean PDFs without watermark';
      case PremiumFeature.logoUpload:
        return 'Add your company logo to invoices';
      case PremiumFeature.premiumTemplates:
        return 'Access Modern and Elegant templates';
    }
  }

  String get icon {
    switch (this) {
      case PremiumFeature.unlimitedInvoices:
        return '∞';
      case PremiumFeature.noWatermark:
        return '✨';
      case PremiumFeature.logoUpload:
        return '🏢';
      case PremiumFeature.premiumTemplates:
        return '🎨';
    }
  }

  static PremiumFeature fromString(String value) {
    switch (value) {
      case 'unlimited_invoices':
        return PremiumFeature.unlimitedInvoices;
      case 'no_watermark':
        return PremiumFeature.noWatermark;
      case 'logo_upload':
        return PremiumFeature.logoUpload;
      case 'premium_templates':
        return PremiumFeature.premiumTemplates;
      default:
        throw ArgumentError('Unknown premium feature: $value');
    }
  }
}