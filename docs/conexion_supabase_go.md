# ⚙️ Conexión con Supabase y Backend Go — ServiYa App Móvil

Este documento explica cómo funciona técnicamente la conexión de la app Flutter (`ServiYa_ADSO`) con **Supabase** y el **Backend en Go**, desde el arranque hasta cada petición de datos.

---

## 🚀 Paso 1: Arranque de la App (`main.dart`)

Cuando la app abre, ocurren **3 cosas en orden**:

```dart
// lib/main.dart
await dotenv.load(fileName: ".env");        // 1. Carga variables del archivo .env

await Supabase.initialize(                   // 2. Inicializa el cliente de Supabase
  url: Env.supabaseUrl,
  anonKey: Env.supabaseAnonKey,
);

runApp(ProviderScope(child: ServiYaApp())); // 3. Arranca la app con Riverpod
```

El archivo `.env` en la raíz del proyecto contiene:

```env
SUPABASE_URL=https://lvxhporsajorgckeisna.supabase.co
SUPABASE_ANON_KEY=eyJ...            # Llave pública para usuarios normales
SUPABASE_SERVICE_ROLE_KEY=eyJ...    # Llave que bypasea RLS (solo admin)
API_BASE_URL=https://apiserviya.onrender.com/api/v1
```

> ⚠️ El archivo `.env` NO se sube a Git. Debes copiarlo manualmente al nuevo PC antes de correr la app.

---

## 🔐 Supabase — Forma 1: SDK oficial (Usuarios normales)

El `SupabaseClient` se obtiene via Riverpod desde cualquier datasource:

```dart
// lib/core/network/supabase_client.dart
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
```

Uso típico:

```dart
final _supabase = Supabase.instance.client;

// Login
await _supabase.auth.signInWithPassword(email: email, password: password);

// Consulta con esquema de PostgreSQL
await _supabase
  .schema('seguridad')
  .from('usuarios')
  .select('id_usuario, nombre, apellido, rol')
  .eq('auth_id', authId)
  .maybeSingle();

// Inserción
await _supabase.schema('soporte').from('pqrs').insert({
  'id_cliente': clienteId,
  'tipo_pqr': 'Queja',
  'descripcion': 'Texto del problema',
});

// Stream reactivo de sesión
_supabase.auth.onAuthStateChange.listen((event) { ... });
```

**Se usa para:** Login, Registro, Reservas del cliente, PQRs del cliente, Calificaciones.

---

## 🔐 Supabase — Forma 2: HTTP directo con `service_role key` (Solo Admin)

El panel de Admin necesita bypass de RLS. Se llama directamente a la REST API de Supabase con la llave de servicio:

```dart
// lib/features/admin/data/datasources/admin_remote_datasource.dart
final response = await http.get(
  Uri.parse('$supabaseUrl/rest/v1/usuarios?select=id_usuario,nombre,apellido'),
  headers: {
    'apikey': serviceRoleKey,
    'Authorization': 'Bearer $serviceRoleKey',
    'Accept': 'application/json',
    'Accept-Profile': 'seguridad',   // <- Equivale a .schema('seguridad')
  },
);
```

**Se usa para:** Gestión de todos los usuarios, moderación de reseñas.

> ⚠️ La `service_role key` es de alto privilegio. Nunca la expongas en el código fuente. Solo va en `.env`.

---

## 🌐 Backend Go — Cliente Dio centralizado (`api_client.dart`)

Existe un solo cliente Dio compartido para toda la app, registrado como Provider:

```dart
// lib/core/network/api_client.dart
final apiClientProvider = Provider<Dio>((ref) {
  final supabase = ref.watch(supabaseClientProvider);

  final dio = Dio(BaseOptions(
    baseUrl: 'https://apiserviya.onrender.com/api/v1',
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 15),
  ));

  // INTERCEPTOR 1: Inyecta el JWT automáticamente en CADA petición
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final session = supabase.auth.currentSession;
      if (session != null) {
        options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
      handler.next(options);
    },
  ));

  // INTERCEPTOR 2: Imprime logs en consola (modo debug)
  dio.interceptors.add(LogInterceptor(
    logPrint: (obj) => debugPrint('🚀 [API Go]: $obj'),
  ));

  return dio;
});
```

> 💡 Gracias al interceptor, ningún datasource necesita escribir el token manualmente. Solo hacen `_dio.get(...)` y el JWT viaja solo.

---

## 🌐 Backend Go — Uso en los DataSources

```dart
class AdminAnalyticsRemoteDataSource {
  final Dio _dio;
  AdminAnalyticsRemoteDataSource(this._dio); // <- Inyectado desde el Provider

  // GET normal (retorna JSON)
  Future<void> fetchPqrs() async {
    final response = await _dio.get('/operativo/pqrs');
    // response.data -> List<dynamic> (JSON ya parseado)
  }

  // GET en paralelo (3 endpoints al mismo tiempo = más rápido)
  final results = await Future.wait([
    _dio.get('/reportes/admin?mes=9&anio=2026'),
    _dio.get('/reportes/servicios-populares?mes=9&anio=2026'),
    _dio.get('/reportes/actividad-usuarios?mes=9&anio=2026'),
  ]);

  // POST con body JSON
  await _dio.post('/operativo/pqrs/responder', data: {
    'id_pqr': 82,
    'respuesta_admin': 'Hemos gestionado tu caso.',
  });

  // GET de archivo binario (PDF)
  final response = await _dio.get<List<int>>(
    '/reportes/admin/pdf?mes=9&anio=2026',
    options: Options(responseType: ResponseType.bytes),
  );
  // response.data -> List<int> con los bytes del PDF
}
```

---

## 🔄 Flujo Completo de una Petición

```
1. App abre
   └─► main.dart carga .env → inicializa Supabase

2. Usuario hace Login
   └─► Supabase Auth.signInWithPassword()
         └─► Retorna Session con accessToken (JWT)

3. Pantalla Admin se monta (ej. AdminPqrsTab)
   └─► ref.watch(adminPqrsProvider)
         └─► Controller.load() se dispara
               └─► Repositorio llama datasource
                     └─► _dio.get('/operativo/pqrs')
                           ├─ Interceptor inyecta:
                           │    Authorization: Bearer eyJhbGc...
                           └─► Go API recibe la petición
                                 └─► Valida JWT con Supabase
                                 └─► Consulta PostgreSQL
                                 └─► Retorna JSON
                     └─► JSON → List<AdminPqrEntity>
               └─► Estado cambia a AsyncData([pqr1, pqr2, ...])
   └─► Widget se reconstruye con los datos
```

---

## 📊 Resumen: ¿Quién hace qué?

| Necesidad | Tecnología | Archivo Clave |
| :--- | :--- | :--- |
| Login / Registro | Supabase Auth SDK | `auth_remote_datasource.dart` |
| Perfil de usuario | Supabase SDK → seguridad.usuarios | `auth_remote_datasource.dart` |
| Reservas del cliente | Supabase SDK → gestion.reservas | `reservation_remote_datasource.dart` |
| PQRs del cliente | Supabase SDK → soporte.pqrs | `pqrs_remote_datasource.dart` |
| Calificaciones del cliente | Supabase SDK → gestion.calificaciones | `calificacion_remote_datasource.dart` |
| Cancelar Cita/Reserva | Dio → PUT /reservas/{id}/cancelar | `reservation_remote_datasource.dart` |
| Panel Admin (usuarios) | HTTP directo + Service Role Key | `admin_remote_datasource.dart` |
| Reseñas y Calificaciones Admin | HTTP/Dio → GET /reportes/calificaciones | `admin_remote_datasource.dart` |
| Reportes analíticos Admin | Dio → GET /reportes/admin | `admin_analytics_remote_datasource.dart` |
| Historial de servicios Admin | Dio → GET /operativo/historial-servicios | `prestadores_remote_datasource.dart` |
| Gestión de Prestadores Admin | Dio → GET /operativo/prestadores | `prestadores_remote_datasource.dart` |
| Buzón de PQRs Admin | Dio → GET /operativo/pqrs | `admin_pqrs_remote_datasource.dart` |
| Responder PQR Admin | Dio → POST /operativo/pqrs/responder | `admin_pqrs_remote_datasource.dart` |
| Descarga de PDF | Dio → GET /reportes/admin/pdf (bytes) | `admin_analytics_remote_datasource.dart` |
| JWT automático en Go | Interceptor de Dio | `api_client.dart` |
| Variables de entorno | flutter_dotenv | `.env` + `env.dart` |
