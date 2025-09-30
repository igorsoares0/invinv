import 'package:flutter/material.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/simple_subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  final PremiumFeature? blockedFeature;
  final bool fromInvoiceLimit;

  const PaywallScreen({
    super.key,
    this.blockedFeature,
    this.fromInvoiceLimit = false,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final SimpleSubscriptionService _subscriptionService = SimpleSubscriptionService();
  List<SubscriptionPlan> _plans = [SubscriptionPlan.monthly, SubscriptionPlan.annual];
  SubscriptionPlan _selectedPlan = SubscriptionPlan.annual;
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    // Simulate loading time
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _makePurchase() async {
    if (_isPurchasing) return;

    setState(() {
      _isPurchasing = true;
    });

    try {
      final success = await _subscriptionService.simulatePremiumPurchase(_selectedPlan);

      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (adaptyError) {
      if (mounted) {
        String errorMessage = 'Purchase failed. Please try again.';

        if (adaptyError.toString().contains('cancelled')) {
          errorMessage = 'Purchase was cancelled.';
        } else if (adaptyError.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase failed. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    try {
      final status = await _subscriptionService.getSubscriptionStatus();
      if (status.isPremium && mounted) {
        Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No purchases found to restore.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to restore purchases.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildFeaturesList(),
                    const SizedBox(height: 32),
                    _buildPlanSelection(),
                    const SizedBox(height: 24),
                    _buildPurchaseButton(),
                    const SizedBox(height: 16),
                    _buildSecondaryActions(),
                    const SizedBox(height: 16),
                    _buildLegalText(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    String title = 'Unlock Premium Features';
    String subtitle = 'Get unlimited access to all professional tools';

    if (widget.fromInvoiceLimit) {
      title = 'Invoice Limit Reached';
      subtitle = 'Upgrade to create unlimited invoices';
    } else if (widget.blockedFeature != null) {
      switch (widget.blockedFeature!) {
        case PremiumFeature.logoUpload:
          title = 'Add Your Company Logo';
          subtitle = 'Make your invoices more professional';
          break;
        case PremiumFeature.premiumTemplates:
          title = 'Premium Templates';
          subtitle = 'Access Modern and Elegant designs';
          break;
        case PremiumFeature.noWatermark:
          title = 'Remove Watermark';
          subtitle = 'Generate clean, professional PDFs';
          break;
        case PremiumFeature.unlimitedInvoices:
          title = 'Unlimited Invoices';
          subtitle = 'Create as many invoices as you need';
          break;
      }
    }

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade400, Colors.amber.shade600],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.star,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.all_inclusive,
        'title': 'Unlimited Invoices',
        'description': 'Create as many invoices as you need',
      },
      {
        'icon': Icons.cleaning_services,
        'title': 'Remove Watermark',
        'description': 'Professional PDFs without branding',
      },
      {
        'icon': Icons.business,
        'title': 'Company Logo',
        'description': 'Add your logo to all invoices',
      },
      {
        'icon': Icons.palette,
        'title': 'Premium Templates',
        'description': 'Modern and Elegant designs',
      },
    ];

    return Column(
      children: features.map((feature) => _buildFeatureItem(
        feature['icon'] as IconData,
        feature['title'] as String,
        feature['description'] as String,
      )).toList(),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Icon(
              icon,
              color: Colors.green.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ..._plans.map((plan) => _buildPlanCard(plan)),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isSelected = _selectedPlan == plan;
    final isAnnual = plan == SubscriptionPlan.annual;
    final isPopular = isAnnual;

    String planName = 'Monthly Premium';
    String planPrice = '\$1.99';
    String planPeriod = 'per month';
    String? badge;

    if (isAnnual) {
      planName = 'Annual Premium';
      planPrice = '\$20.00';
      planPeriod = 'per year';
      badge = 'SAVE 17%';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = plan;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isPopular)
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          children: [
            if (badge != null)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected ? Colors.blue : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue.shade700 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All premium features included',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      planPrice,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue.shade700 : Colors.black87,
                      ),
                    ),
                    Text(
                      planPeriod,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade700],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _isPurchasing ? null : _makePurchase,
          child: Center(
            child: _isPurchasing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Start Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActions() {
    return Column(
      children: [
        TextButton(
          onPressed: _restorePurchases,
          child: const Text(
            'Restore Purchases',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Maybe Later',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Subscription automatically renews unless auto-renewal is turned off at least 24 hours before the end of the current period.',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}