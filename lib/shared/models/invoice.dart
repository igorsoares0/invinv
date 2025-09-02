enum InvoiceType {
  invoice('invoice'),
  estimate('estimate'),
  receipt('receipt');

  const InvoiceType(this.value);
  final String value;

  static InvoiceType fromString(String value) {
    return InvoiceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => InvoiceType.invoice,
    );
  }
}

enum InvoiceStatus {
  draft('draft'),
  sent('sent'),
  paid('paid'),
  overdue('overdue'),
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const InvoiceStatus(this.value);
  final String value;

  static InvoiceStatus fromString(String value) {
    return InvoiceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => InvoiceStatus.draft,
    );
  }
}

class Invoice {
  final int? id;
  final String number;
  final InvoiceType type;
  final int clientId;
  final DateTime issueDate;
  final DateTime? dueDate;
  final InvoiceStatus status;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double total;
  final String? notes;
  final String? terms;
  final DateTime createdAt;

  Invoice({
    this.id,
    required this.number,
    required this.type,
    required this.clientId,
    required this.issueDate,
    this.dueDate,
    this.status = InvoiceStatus.draft,
    required this.subtotal,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    required this.total,
    this.notes,
    this.terms,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'type': type.value,
      'client_id': clientId,
      'issue_date': issueDate.toIso8601String().split('T')[0],
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'status': status.value,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total': total,
      'notes': notes,
      'terms': terms,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      number: map['number'],
      type: InvoiceType.fromString(map['type']),
      clientId: map['client_id'],
      issueDate: DateTime.parse(map['issue_date']),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      status: InvoiceStatus.fromString(map['status']),
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
      discountAmount: map['discount_amount']?.toDouble() ?? 0.0,
      taxAmount: map['tax_amount']?.toDouble() ?? 0.0,
      total: map['total']?.toDouble() ?? 0.0,
      notes: map['notes'],
      terms: map['terms'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Invoice copyWith({
    int? id,
    String? number,
    InvoiceType? type,
    int? clientId,
    DateTime? issueDate,
    DateTime? dueDate,
    InvoiceStatus? status,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? total,
    String? notes,
    String? terms,
    DateTime? createdAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      number: number ?? this.number,
      type: type ?? this.type,
      clientId: clientId ?? this.clientId,
      issueDate: issueDate ?? this.issueDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isOverdue {
    if (dueDate == null || status == InvoiceStatus.paid) return false;
    return DateTime.now().isAfter(dueDate!) && status != InvoiceStatus.paid;
  }
}