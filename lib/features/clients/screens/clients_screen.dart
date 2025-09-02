import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/client_bloc.dart';
import '../bloc/client_event.dart';
import '../bloc/client_state.dart';
import '../../../shared/models/models.dart';
import 'client_form_screen.dart';
import 'client_details_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({Key? key}) : super(key: key);

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ClientBloc>().add(LoadClients());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToClientForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search clients...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                context.read<ClientBloc>().add(SearchClients(query));
              },
            ),
          ),
          Expanded(
            child: BlocConsumer<ClientBloc, ClientState>(
              listener: (context, state) {
                if (state is ClientError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (state is ClientOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ClientLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ClientLoaded) {
                  if (state.clients.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildClientList(state.clients);
                }

                return const Center(child: Text('Something went wrong'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No clients yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first client to get started',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToClientForm(),
            icon: const Icon(Icons.add),
            label: const Text('Add Client'),
          ),
        ],
      ),
    );
  }

  Widget _buildClientList(List<Client> clients) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                client.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(client.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.email),
                if (client.phone != null)
                  Text(client.phone!),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, client),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: ListTile(
                    leading: Icon(Icons.visibility),
                    title: Text('View Details'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            onTap: () => _navigateToClientDetails(client.id!),
          ),
        );
      },
    );
  }

  void _handleMenuAction(String action, Client client) {
    switch (action) {
      case 'view':
        _navigateToClientDetails(client.id!);
        break;
      case 'edit':
        _navigateToClientForm(client: client);
        break;
      case 'delete':
        _showDeleteConfirmation(client);
        break;
    }
  }

  void _showDeleteConfirmation(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete ${client.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ClientBloc>().add(DeleteClient(client.id!));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToClientForm({Client? client}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientFormScreen(client: client),
      ),
    );
  }

  void _navigateToClientDetails(int clientId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientDetailsScreen(clientId: clientId),
      ),
    );
  }
}