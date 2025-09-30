enum SubscriptionPlan {
  free,
  monthly,
  annual,
}

extension SubscriptionPlanExtension on SubscriptionPlan {
  String get value {
    switch (this) {
      case SubscriptionPlan.free:
        return 'free';
      case SubscriptionPlan.monthly:
        return 'monthly';
      case SubscriptionPlan.annual:
        return 'annual';
    }
  }

  String get displayName {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.monthly:
        return 'Monthly Premium';
      case SubscriptionPlan.annual:
        return 'Annual Premium';
    }
  }

  String get productId {
    switch (this) {
      case SubscriptionPlan.free:
        return '';
      case SubscriptionPlan.monthly:
        return 'com.invinv.monthly_premium';
      case SubscriptionPlan.annual:
        return 'com.invinv.annual_premium';
    }
  }

  double get price {
    switch (this) {
      case SubscriptionPlan.free:
        return 0.0;
      case SubscriptionPlan.monthly:
        return 1.99;
      case SubscriptionPlan.annual:
        return 20.00;
    }
  }

  String get priceText {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.monthly:
        return '\$1.99/month';
      case SubscriptionPlan.annual:
        return '\$20.00/year';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionPlan.free:
        return '10 invoices max • Watermark included • Classic template only';
      case SubscriptionPlan.monthly:
        return 'Unlimited invoices • No watermark • All templates • Company logo';
      case SubscriptionPlan.annual:
        return 'Unlimited invoices • No watermark • All templates • Company logo • Save 17%';
    }
  }

  bool get isPremium {
    return this != SubscriptionPlan.free;
  }

  static SubscriptionPlan fromString(String value) {
    switch (value) {
      case 'monthly':
        return SubscriptionPlan.monthly;
      case 'annual':
        return SubscriptionPlan.annual;
      case 'free':
      default:
        return SubscriptionPlan.free;
    }
  }
}