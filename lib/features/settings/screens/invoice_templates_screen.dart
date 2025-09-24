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
  Color _classicTemplateColor = const Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    _loadSelectedTemplate();
  }

  Future<void> _loadSelectedTemplate() async {
    try {
      final template = await _templateService.getSelectedTemplate();
      final classicColor = await _templateService.getClassicTemplateColor();
      setState(() {
        _selectedTemplate = template;
        _classicTemplateColor = classicColor;
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
      child: Column(
        children: [
          InkWell(
            onTap: () => _selectTemplate(template.type),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Template Preview
              _buildTemplatePreview(template.type, isSelected, _classicTemplateColor),
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
                        if (template.isCustomizable) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.palette_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
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
          // Color customization for Classic template
          if (template.type == InvoiceTemplateType.classic && isSelected)
            _buildColorCustomization(),
        ],
      ),
    );
  }

  IconData _getTemplateIcon(InvoiceTemplateType type) {
    switch (type) {
      case InvoiceTemplateType.classic:
        return Icons.description_outlined;
      case InvoiceTemplateType.modern:
        return Icons.auto_awesome_outlined;
      case InvoiceTemplateType.elegant:
        return Icons.diamond_outlined;
    }
  }

  String _getTemplateFeatures(InvoiceTemplateType type) {
    switch (type) {
      case InvoiceTemplateType.classic:
        return 'Traditional layout • Clean typography • Professional appearance';
      case InvoiceTemplateType.modern:
        return 'Contemporary design • Enhanced colors • Visual hierarchy';
      case InvoiceTemplateType.elegant:
        return 'Sophisticated design • Premium aesthetics • Minimalist borders';
    }
  }

  Widget _buildTemplatePreview(InvoiceTemplateType type, bool isSelected, Color customColor) {
    switch (type) {
      case InvoiceTemplateType.classic:
        return _buildClassicPreview(isSelected, customColor);
      case InvoiceTemplateType.modern:
        return _buildModernPreview(isSelected);
      case InvoiceTemplateType.elegant:
        return _buildElegantPreview(isSelected);
    }
  }

  Widget _buildClassicPreview(bool isSelected, Color customColor) {
    final previewColor = customColor;
    return Container(
      key: ValueKey('classic_preview_${previewColor.value}'),
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? previewColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 30,
                  height: 4,
                  color: previewColor,
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Company info
            Container(
              width: 25,
              height: 2,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 2),
            Container(
              width: 30,
              height: 1,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 6),
            // Table
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                border: Border.all(color: previewColor),
              ),
              child: Container(
                color: previewColor.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 2),
            // Rows
            ...List.generate(3, (index) => Container(
              margin: const EdgeInsets.only(bottom: 1),
              width: double.infinity,
              height: 4,
              color: Colors.grey.shade50,
            )),
            const Spacer(),
            // Total
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 20,
                height: 8,
                decoration: BoxDecoration(
                  border: Border.all(color: previewColor, width: 1),
                  color: previewColor.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPreview(bool isSelected) {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient Header
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 15,
                      height: 2,
                      color: Colors.white,
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Colored boxes
            Row(
              children: [
                Container(
                  width: 25,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 25,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Gradient Table
            Container(
              width: double.infinity,
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade700],
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Alternating rows
            Container(
              width: double.infinity,
              height: 4,
              color: Colors.white,
            ),
            const SizedBox(height: 1),
            Container(
              width: double.infinity,
              height: 4,
              color: Colors.grey.shade50,
            ),
            const SizedBox(height: 1),
            Container(
              width: double.infinity,
              height: 4,
              color: Colors.white,
            ),
            const Spacer(),
            // Gradient Total
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 22,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElegantPreview(bool isSelected) {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bold Header with underline
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 3,
                  color: Colors.grey.shade800,
                ),
                const SizedBox(height: 1),
                Container(
                  width: double.infinity,
                  height: 2,
                  color: Colors.grey.shade800,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Sections with underlines
            Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 15,
                      height: 1,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 15,
                      height: 1,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  width: 20,
                  height: 1,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Bold table
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade800, width: 1.5),
                  bottom: BorderSide(color: Colors.grey.shade800, width: 1.5),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 8,
                    color: Colors.grey.shade800,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: double.infinity,
                    height: 3,
                    color: Colors.white,
                  ),
                  Container(
                    width: double.infinity,
                    height: 0.5,
                    color: Colors.grey.shade400,
                  ),
                  Container(
                    width: double.infinity,
                    height: 3,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Bordered Total
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 22,
                height: 12,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade800, width: 1),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 6,
                      color: Colors.grey.shade800,
                    ),
                    Container(
                      width: double.infinity,
                      height: 4,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCustomization() {
    final predefinedColors = [
      const Color(0xFF1976D2), // Blue
      const Color(0xFF388E3C), // Green
      const Color(0xFFD32F2F), // Red
      const Color(0xFFFF8F00), // Orange
      const Color(0xFF7B1FA2), // Purple
      const Color(0xFF00796B), // Teal
      const Color(0xFF5D4037), // Brown
      const Color(0xFF424242), // Grey
    ];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                size: 20,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Customize Colors',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Choose an accent color for your Classic template:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: predefinedColors.map((color) {
              final isSelected = _classicTemplateColor.value == color.value;
              return GestureDetector(
                onTap: () => _updateClassicColor(color),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _updateClassicColor(Color color) async {
    setState(() {
      _classicTemplateColor = color;
    });

    try {
      await _templateService.setClassicTemplateColor(color);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Color updated successfully!'),
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
            content: Text('Failed to save color'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}