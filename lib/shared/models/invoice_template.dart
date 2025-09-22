enum InvoiceTemplateType {
  classic,
  modern,
  elegant,
}

class InvoiceTemplate {
  final InvoiceTemplateType type;
  final String name;
  final String description;
  final String? previewImagePath;

  const InvoiceTemplate({
    required this.type,
    required this.name,
    required this.description,
    this.previewImagePath,
  });

  static const List<InvoiceTemplate> templates = [
    InvoiceTemplate(
      type: InvoiceTemplateType.classic,
      name: 'Classic',
      description: 'Traditional professional invoice layout with clean lines',
    ),
    InvoiceTemplate(
      type: InvoiceTemplateType.modern,
      name: 'Modern',
      description: 'Contemporary design with enhanced visual hierarchy',
    ),
    InvoiceTemplate(
      type: InvoiceTemplateType.elegant,
      name: 'Elegant',
      description: 'Sophisticated design with premium aesthetics and refined details',
    ),
  ];

  static InvoiceTemplate getTemplate(InvoiceTemplateType type) {
    return templates.firstWhere((template) => template.type == type);
  }
}

extension InvoiceTemplateTypeExtension on InvoiceTemplateType {
  String get value {
    switch (this) {
      case InvoiceTemplateType.classic:
        return 'classic';
      case InvoiceTemplateType.modern:
        return 'modern';
      case InvoiceTemplateType.elegant:
        return 'elegant';
    }
  }

  static InvoiceTemplateType fromString(String value) {
    switch (value) {
      case 'classic':
        return InvoiceTemplateType.classic;
      case 'modern':
        return InvoiceTemplateType.modern;
      case 'elegant':
        return InvoiceTemplateType.elegant;
      default:
        return InvoiceTemplateType.classic;
    }
  }
}