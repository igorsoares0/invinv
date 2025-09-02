class Client {
  final int? id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? notes;
  final DateTime createdAt;

  Client({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      zipCode: map['zip_code'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Client copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? notes,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get fullAddress {
    final parts = [address, city, state, zipCode]
        .where((part) => part != null && part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}