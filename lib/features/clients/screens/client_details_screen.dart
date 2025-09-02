import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/client_bloc.dart';
import '../bloc/client_event.dart';
import '../bloc/client_state.dart';
import 'client_form_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  final int clientId;

  const ClientDetailsScreen({Key? key, required this.clientId}) : super(key: key);

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ClientBloc>().add(LoadClientDetails(widget.clientId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Details'),
        elevation: 0,
        actions: [
          BlocBuilder<ClientBloc, ClientState>(
            builder: (context, state) {
              if (state is ClientDetailsLoaded) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _navigateToEdit(state.client),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<ClientBloc, ClientState>(
        listener: (context, state) {
          if (state is ClientError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ClientLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ClientDetailsLoaded) {
            return _buildClientDetails(state);
          }

          return const Center(child: Text('Client not found'));
        },
      ),
    );
  }

  Widget _buildClientDetails(ClientDetailsLoaded state) {
    final client = state.client;
    final stats = state.stats;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClientInfoCard(client),
          const SizedBox(height: 16),
          _buildStatsCard(stats),
          const SizedBox(height: 16),
          _buildInvoiceHistoryCard(state.invoiceHistory),
        ],
      ),
    );
  }

  Widget _buildClientInfoCard(client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    client.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        client.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, 'Phone', client.phone ?? 'Not provided'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'Address', client.fullAddress.isEmpty ? 'Not provided' : client.fullAddress),
            if (client.notes != null && client.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.note, 'Notes', client.notes!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    final totalInvoices = stats['total_invoices'] ?? 0;
    final totalPaid = (stats['total_paid'] ?? 0.0).toDouble();
    final totalPending = (stats['total_pending'] ?? 0.0).toDouble();
    final totalOverdue = (stats['total_overdue'] ?? 0.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoice Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Invoices',
                    totalInvoices.toString(),
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Paid',
                    NumberFormat.currency(symbol: '\$').format(totalPaid),
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Pending',
                    NumberFormat.currency(symbol: '\$').format(totalPending),
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Overdue',
                    NumberFormat.currency(symbol: '\$').format(totalOverdue),
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceHistoryCard(List<Map<String, dynamic>> invoices) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Invoices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (invoices.isEmpty)
              const Center(
                child: Text(
                  'No invoices yet',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...invoices.take(5).map((invoice) => _buildInvoiceItem(invoice)),
            if (invoices.length > 5)
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full invoice list
                },
                child: const Text('View All Invoices'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceItem(Map<String, dynamic> invoice) {
    final status = invoice['status'] as String;
    final total = (invoice['total'] ?? 0.0).toDouble();
    final date = DateTime.parse(invoice['created_at']);
    
    Color statusColor = Colors.grey;
    switch (status) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'sent':
        statusColor = Colors.orange;
        break;
      case 'overdue':
        statusColor = Colors.red;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice['number'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.currency(symbol: '\$').format(total),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientFormScreen(client: client),
      ),
    ).then((_) {
      context.read<ClientBloc>().add(LoadClientDetails(widget.clientId));
    });
  }
}