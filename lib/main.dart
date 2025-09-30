import 'package:flutter/material.dart';
import 'app/app.dart';
import 'shared/services/simple_subscription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final subscriptionService = SimpleSubscriptionService();
    await subscriptionService.initialize();
  } catch (e) {
    debugPrint('Subscription service initialization failed: $e');
  }

  runApp(const InvoiceApp());
}
