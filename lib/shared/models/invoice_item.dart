import 'product.dart';

class InvoiceItem {
  final int? id;
  final int invoiceId;
  final int? productId;
  final String name;
  final String description;
  final double quantity;
  final String unit;
  final double unitPrice;
  final String? category;
  final double total;

  InvoiceItem({
    this.id,
    required this.invoiceId,
    this.productId,
    required this.name,
    required this.description,
    required this.quantity,
    this.unit = 'un',
    required this.unitPrice,
    this.category,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'category': category,
      'total': total,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'],
      invoiceId: map['invoice_id'],
      productId: map['product_id'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      quantity: map['quantity']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'un',
      unitPrice: map['unit_price']?.toDouble() ?? 0.0,
      category: map['category'],
      total: map['total']?.toDouble() ?? 0.0,
    );
  }

  factory InvoiceItem.fromProduct(Product product, {
    required int invoiceId,
    double quantity = 1.0,
  }) {
    final total = quantity * product.price;
    return InvoiceItem(
      invoiceId: invoiceId,
      productId: product.id,
      name: product.name,
      description: product.description ?? '',
      quantity: quantity,
      unit: product.unit,
      unitPrice: product.price,
      category: product.category,
      total: total,
    );
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? productId,
    String? name,
    String? description,
    double? quantity,
    String? unit,
    double? unitPrice,
    String? category,
    double? total,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      category: category ?? this.category,
      total: total ?? this.total,
    );
  }

  InvoiceItem recalculateTotal() {
    return copyWith(total: quantity * unitPrice);
  }
}