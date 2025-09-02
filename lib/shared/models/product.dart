class Product {
  final int? id;
  final String name;
  final String? description;
  final double price;
  final String unit;
  final String? category;
  final DateTime createdAt;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    this.unit = 'un',
    this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? 'un',
      category: map['category'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? unit,
    String? category,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}