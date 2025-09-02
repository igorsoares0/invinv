import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../bloc/client_bloc.dart';
import '../bloc/client_event.dart';
import '../../../shared/models/models.dart';

class ClientFormScreen extends StatefulWidget {
  final Client? client;

  const ClientFormScreen({Key? key, this.client}) : super(key: key);

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool get isEditing => widget.client != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Client' : 'Add Client'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          initialValue: isEditing ? _getInitialValues() : {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'name',
                decoration: const InputDecoration(
                  labelText: 'Client Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'email',
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.email(),
                ]),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'phone',
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'address',
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'city',
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FormBuilderTextField(
                      name: 'state',
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'zipCode',
                decoration: const InputDecoration(
                  labelText: 'ZIP Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.mail),
                ),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'notes',
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveClient,
                      child: Text(isEditing ? 'Update' : 'Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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