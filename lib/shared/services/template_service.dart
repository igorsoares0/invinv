import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_template.dart';

class TemplateService {
  static const String _templateKey = 'selected_invoice_template';
  static const String _classicColorKey = 'classic_template_color';
  static const String _modernColorKey = 'modern_template_color';

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

  Future<Color> getClassicTemplateColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorValue = prefs.getInt(_classicColorKey) ?? 0xFF1976D2;
      return Color(colorValue);
    } catch (e) {
      return const Color(0xFF1976D2); // Default blue
    }
  }

  Future<void> setClassicTemplateColor(Color color) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_classicColorKey, color.value);
    } catch (e) {
      // Silently fail
    }
  }

  Future<Color> getModernTemplateColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorValue = prefs.getInt(_modernColorKey) ?? 0xFF1976D2;
      return Color(colorValue);
    } catch (e) {
      return const Color(0xFF1976D2); // Default blue
    }
  }

  Future<void> setModernTemplateColor(Color color) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_modernColorKey, color.value);
    } catch (e) {
      // Silently fail
    }
  }
}