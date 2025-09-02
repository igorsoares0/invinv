import 'product.dart';

class InvoiceItem {
  final int? id;
  final int invoiceId;
  final int? productId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double total;

  InvoiceItem({
    this.id,
    required this.invoiceId,
    this.productId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'],
      invoiceId: map['invoice_id'],
      productId: map['product_id'],
      description: map['description'],
      quantity: map['quantity']?.toDouble() ?? 0.0,
      unitPrice: map['unit_price']?.toDouble() ?? 0.0,
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
      description: product.name,
      quantity: quantity,
      unitPrice: product.price,
      total: total,
    );
  }

  InvoiceItem copyWith({
    int? id,
    int? invoiceId,
    int? productId,
    String? description,
    double? quantity,
    double? unitPrice,
    double? total,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
    );
  }

  InvoiceItem recalculateTotal() {
    return copyWith(total: quantity * unitPrice);
  }
}