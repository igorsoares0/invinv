import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../bloc/client_bloc.dart';
import '../bloc/client_event.dart';
import '../../../shared/models/models.dart';

class ClientFormScreen extends StatefulWidget {
  final Client? client;

  const ClientFormScreen({super.key, this.client});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool get isEditing => widget.client != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Client' : 'Add Client',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        toolbarHeight: 80,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FormBuilder(
          key: _formKey,
          initialValue: isEditing ? _getInitialValues() : {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _buildFormField(
                name: 'name',
                icon: Icons.person_outline,
                labelText: 'Client Name *',
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                ]),
              ),
              const SizedBox(height: 20),
              _buildFormField(
                name: 'email',
                icon: Icons.email_outlined,
                labelText: 'Email *',
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.email(),
                ]),
              ),
              const SizedBox(height: 20),
              _buildFormField(
                name: 'phone',
                icon: Icons.phone_outlined,
                labelText: 'Phone',
              ),
              const SizedBox(height: 20),
              _buildFormField(
                name: 'address',
                icon: Icons.location_on_outlined,
                labelText: 'Address',
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildFormField(
                      name: 'city',
                      labelText: 'City',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFormField(
                      name: 'state',
                      labelText: 'State',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFormField(
                name: 'zipCode',
                icon: Icons.markunread_mailbox_outlined,
                labelText: 'ZIP Code',
              ),
              const SizedBox(height: 20),
              _buildFormField(
                name: 'notes',
                labelText: 'Notes',
                maxLines: 3,
              ),
              const SizedBox(height: 60),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextButton(
                        onPressed: _saveClient,
                        child: Text(
                          isEditing ? 'Update' : 'Save',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String name,
    IconData? icon,
    required String labelText,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                labelText,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ] else ...[
          Text(
            labelText,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FormBuilderTextField(
            name: name,
            validator: validator,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getInitialValues() {
    if (widget.client == null) return {};
    
    final client = widget.client!;
    return {
      'name': client.name,
      'email': client.email,
      'phone': client.phone,
      'address': client.address,
      'city': client.city,
      'state': client.state,
      'zipCode': client.zipCode,
      'notes': client.notes,
    };
  }

  void _saveClient() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      
      final client = Client(
        id: isEditing ? widget.client!.id : null,
        name: values['name'],
        email: values['email'],
        phone: values['phone'],
        address: values['address'],
        city: values['city'],
        state: values['state'],
        zipCode: values['zipCode'],
        notes: values['notes'],
      );

      if (isEditing) {
        context.read<ClientBloc>().add(UpdateClient(client));
      } else {
        context.read<ClientBloc>().add(AddClient(client));
      }

      Navigator.pop(context);
    }
  }
}