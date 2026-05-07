class Zona {
  final String id;
  final String nombre;
  final double latitud;
  final double longitud;

  const Zona({
    required this.id,
    required this.nombre,
    required this.latitud,
    required this.longitud,
  });

  factory Zona.fromJson(Map<String, dynamic> json) {
    return Zona(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      latitud: (json['latitud'] as num?)?.toDouble() ?? 0.0,
      longitud: (json['longitud'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'latitud': latitud,
        'longitud': longitud,
      };
}
