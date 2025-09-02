class Company {
  final int? id;
  final String name;
  final String? legalName;
  final String? logoPath;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? taxId;
  final DateTime createdAt;

  Company({
    this.id,
    required this.name,
    this.legalName,
    this.logoPath,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.taxId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'legal_name': legalName,
      'logo_path': logoPath,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'tax_id': taxId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'],
      name: map['name'],
      legalName: map['legal_name'],
      logoPath: map['logo_path'],
      address: map['address'],
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      taxId: map['tax_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Company copyWith({
    int? id,
    String? name,
    String? legalName,
    String? logoPath,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? taxId,
    DateTime? createdAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      logoPath: logoPath ?? this.logoPath,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      taxId: taxId ?? this.taxId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}