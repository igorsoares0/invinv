import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_template.dart';

class TemplateService {
  static const String _templateKey = 'selected_invoice_template';

  Future<InvoiceTemplateType> getSelectedTemplate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templateString = prefs.getString(_templateKey) ?? 'classic';
      return InvoiceTemplateTypeExtension.fromString(templateString);
    } catch (e) {
      return InvoiceTemplateType.classic; // Default fallback
    }
  }

  Future<void> setSelectedTemplate(InvoiceTemplateType template) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_templateKey, template.value);
    } catch (e) {
      // Silently fail - user will see default template
    }
  }
}