import 'package:flutter/material.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/template_service.dart';

class InvoiceTemplatesScreen extends StatefulWidget {
  const InvoiceTemplatesScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceTemplatesScreen> createState() => _InvoiceTemplatesScreenState();
}

class _InvoiceTemplatesScreenState extends State<InvoiceTemplatesScreen> {
  final TemplateService _templateService = TemplateService();
  InvoiceTemplateType _selectedTemplate = InvoiceTemplateType.classic;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedTemplate();
  }

  Future<void> _loadSelectedTemplate() async {
    try {
      final template = await _templateService.getSelectedTemplate();
      setState(() {
        _selectedTemplate = template;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTemplate(InvoiceTemplateType template) async {
    setState(() {
      _selectedTemplate = template;
    });

    try {
      await _templateService.setSelectedTemplate(template);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template "${InvoiceTemplate.getTemplate(template).name}" selected'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save template selection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Invoice Templates',
          style: TextStyle(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Choose a template that matches your business style. You can change this anytime.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Available Templates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...InvoiceTemplate.templates.map((template) =>
                      _buildTemplateCard(template),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTemplateCard(InvoiceTemplate template) {
    final isSelected = _selectedTemplate == template.type;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _selectTemplate(template.type),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Template Preview
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getTemplateIcon(template.type),
                      size: 32,
                      color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 50,
                      height: 2,
                      color: isSelected ? Colors.blue.shade400 : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 2,
                      color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: 2,
                      color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Template Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          template.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.blue.shade700 : Colors.black87,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      template.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getTemplateFeatures(template.type),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              // Selection indicator
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
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTemplateIcon(InvoiceTemplateType type) {
    switch (type) {
      case InvoiceTemplateType.classic:
        return Icons.description_outlined;
      case InvoiceTemplateType.modern:
        return Icons.auto_awesome_outlined;
    }
  }

  String _getTemplateFeatures(InvoiceTemplateType type) {
    switch (type) {
      case InvoiceTemplateType.classic:
        return 'Traditional layout • Clean typography • Professional appearance';
      case InvoiceTemplateType.modern:
        return 'Contemporary design • Enhanced colors • Visual hierarchy';
    }
  }
}