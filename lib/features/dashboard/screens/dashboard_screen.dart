import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/services/invoice_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _invoiceService.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadStats();
            },
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(),
                  const SizedBox(height: 24),
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildRecentActivity(),
                ],
              ),
            ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here\'s your business overview for ${DateFormat('MMMM yyyy').format(DateTime.now())}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.analytics,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_stats == null) return const SizedBox.shrink();

    final totalInvoices = _stats!['total_invoices'] ?? 0;
    final totalPaid = (_stats!['total_paid'] ?? 0.0).toDouble();
    final totalPending = (_stats!['total_pending'] ?? 0.0).toDouble();
    final totalOverdue = (_stats!['total_overdue'] ?? 0.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Month',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatCard(
              'Total Invoices',
              totalInvoices.toString(),
              Icons.receipt,
              Colors.blue,
            ),
            _buildStatCard(
              'Paid',
              NumberFormat.currency(symbol: '\$').format(totalPaid),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              'Pending',
              NumberFormat.currency(symbol: '\$').format(totalPending),
              Icons.schedule,
              Colors.orange,
            ),
            _buildStatCard(
              'Overdue',
              NumberFormat.currency(symbol: '\$').format(totalOverdue),
              Icons.warning,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildActionCard(
              'New Invoice',
              Icons.add_circle,
              Colors.blue,
              () => _navigateToInvoiceForm(),
            ),
            _buildActionCard(
              'Add Client',
              Icons.person_add,
              Colors.green,
              () => _navigateToClientForm(),
            ),
            _buildActionCard(
              'Add Product',
              Icons.inventory,
              Colors.purple,
              () => _navigateToProductForm(),
            ),
            _buildActionCard(
              'View Reports',
              Icons.analytics,
              Colors.orange,
              () => _navigateToReports(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: const Icon(Icons.receipt, color: Colors.blue),
                  ),
                  title: const Text('Invoice #INV-2024-0001 created'),
                  subtitle: const Text('2 hours ago'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to invoice details
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: const Icon(Icons.person_add, color: Colors.green),
                  ),
                  title: const Text('New client "Acme Corp" added'),
                  subtitle: const Text('1 day ago'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to client details
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    child: const Icon(Icons.inventory, color: Colors.purple),
                  ),
                  title: const Text('Product "Web Development" updated'),
                  subtitle: const Text('3 days ago'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to product details
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToInvoiceForm() {
    // TODO: Navigate to invoice form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice form coming soon!')),
    );
  }

  void _navigateToClientForm() {
    // TODO: Navigate to client form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Client form coming soon!')),
    );
  }

  void _navigateToProductForm() {
    // TODO: Navigate to product form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product form coming soon!')),
    );
  }

  void _navigateToReports() {
    // TODO: Navigate to reports
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reports coming soon!')),
    );
  }
}