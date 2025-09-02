import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../bloc/product_bloc.dart';
import '../../../shared/models/models.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({Key? key, this.product}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool get isEditing => widget.product != null;

  final List<String> _units = ['un', 'hr', 'kg', 'lb', 'm', 'ft', 'L', 'gal', 'piece', 'box'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          initialValue: isEditing ? _getInitialValues() : {'unit': 'un'},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'name',
                decoration: const InputDecoration(
                  labelText: 'Product/Service Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'description',
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FormBuilderTextField(
                      name: 'price',
                      decoration: const InputDecoration(
                        labelText: 'Price *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.numeric(),
                        FormBuilderValidators.min(0),
                      ]),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FormBuilderDropdown<String>(
                      name: 'unit',
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: _units.map((unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      )).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'category',
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
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
                      onPressed: _saveProduct,
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
    if (widget.product == null) return {};
    
    final product = widget.product!;
    return {
      'name': product.name,
      'description': product.description,
      'price': product.price.toString(),
      'unit': product.unit,
      'category': product.category,
    };
  }

  void _saveProduct() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      
      final product = Product(
        id: isEditing ? widget.product!.id : null,
        name: values['name'],
        description: values['description'],
        price: double.parse(values['price']),
        unit: values['unit'] ?? 'un',
        category: values['category'],
      );

      if (isEditing) {
        context.read<ProductBloc>().add(UpdateProduct(product));
      } else {
        context.read<ProductBloc>().add(AddProduct(product));
      }

      Navigator.pop(context);
    }
  }
}