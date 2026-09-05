class ServiceCategoryEntity {
  final int id;
  final String nombre;
  final String icono;
  final List<String> detalles;
  final List<String> subServicios;

  const ServiceCategoryEntity({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.detalles,
    required this.subServicios,
  });

  static const List<ServiceCategoryEntity> allServices = [
    ServiceCategoryEntity(
      id: 1,
      nombre: 'Plomería y Agua',
      icono: '💧',
      detalles: [
        'Fugas y goteos',
        'Destapado de tuberías',
        'Instalación de sanitarios',
        'Grifos y llaves de agua',
        'Mantenimiento de tanques',
        'Reparación de bombas',
      ],
      subServicios: [
        'Reparación de tuberías',
        'Fugas de agua',
        'Instalación de grifos',
        'Destape de cañerías',
        'Mantenimiento general de plomería',
      ],
    ),
    ServiceCategoryEntity(
      id: 2,
      nombre: 'Servicios Eléctricos',
      icono: '⚡',
      detalles: [
        'Cortocircuitos',
        'Instalación de tomas',
        'Cableado eléctrico',
        'Luminarias y lámparas',
        'Tableros eléctricos',
        'Interruptores y dimers',
      ],
      subServicios: [
        'Corto circuito',
        'Cambio de enchufes e interruptores',
        'Instalación de iluminación',
        'Cableado estructurado',
        'Revisión eléctrica integral',
      ],
    ),
    ServiceCategoryEntity(
      id: 3,
      nombre: 'Servicios de Gas',
      icono: '🔥',
      detalles: [
        'Detección de fugas',
        'Instalación de estufas',
        'Calentadores de agua',
        'Conexiones seguras',
        'Mantenimiento preventivo',
        'Certificaciones',
      ],
      subServicios: [
        'Revisión y detección de fugas',
        'Instalación de estufa o calentador',
        'Mantenimiento preventivo de gas',
        'Puntos de conexión seguros',
      ],
    ),
    ServiceCategoryEntity(
      id: 4,
      nombre: 'Carpintería y Decoración',
      icono: '🪚',
      detalles: [
        'Instalación de cortinas',
        'Montaje de estantes',
        'Reparación de muebles',
        'Closets y organizadores',
        'Puertas y marcos',
        'Trabajos en madera',
      ],
      subServicios: [
        'Reparación de muebles',
        'Instalación de puertas y marcos',
        'Montaje de estantes y repisas',
        'Ajuste y mantenimiento de closets',
      ],
    ),
    ServiceCategoryEntity(
      id: 5,
      nombre: 'Pintura y Acabados',
      icono: '🎨',
      detalles: [
        'Pintura de interiores',
        'Pintura de exteriores',
        'Reparación de grietas',
        'Acabados decorativos',
        'Pintura de techos',
        'Restauración de superficies',
      ],
      subServicios: [
        'Pintura de interiores',
        'Pintura de exteriores o fachada',
        'Resane y reparación de grietas',
        'Acabados decorativos y estuco',
      ],
    ),
    ServiceCategoryEntity(
      id: 6,
      nombre: 'Aire Acondicionado',
      icono: '❄️',
      detalles: [
        'Instalación de equipos',
        'Mantenimiento preventivo',
        'Reparación de averías',
        'Limpieza de filtros',
        'Recarga de gas',
        'Ventiladores de techo',
      ],
      subServicios: [
        'Mantenimiento y limpieza de filtros',
        'Instalación de aire acondicionado',
        'Recarga de gas refrigerante',
        'Reparación y diagnóstico de fallas',
      ],
    ),
  ];
}