# 📱 Arquitectura y Consumo de Servicios en ServiYa (App Móvil)

Este documento detalla cómo funciona la arquitectura de la aplicación móvil (`ServiYa_ADSO`), cómo se divide el consumo entre **Supabase** y el **Backend en Go**, y los recorridos detallados de los flujos de **PQRs** y **Descarga de Reportes PDF**.

---

## 🏗️ 1. Arquitectura de la App Móvil (`ServiYa_ADSO`)

La aplicación móvil implementa un patrón **Clean Architecture + Feature-First (Por Características)** junto con **Riverpod** para la reactividad y gestión de estado.

```mermaid
graph TD
    UI[Capas de Presentación / UI\nWidgets, Screens, Tabs] -->|Observa / Ejecuta| Controller[Controlador / StateNotifier\nRiverpod Providers]
    Controller -->|Invoca Casos de Uso / Métodos| Repo[Repositorio / Interface\nIAdminPqrsRepository, etc.]
    Repo -->|Implementa| RepoImpl[Repository Implementation]
    RepoImpl -->|Consume Datos| Datasource[Remote DataSource]
    Datasource -->|Petición HTTP con JWT| GoAPI[🚀 Backend Go / REST API]
    Datasource -.->|Fallback de Respaldo| Supabase[(🗄️ PostgreSQL / Supabase)]
    GoAPI -->|Lee / Escribe| Supabase
```

### Capas del Proyecto:
1. **`Presentation Layer` (UI y Controladores):**
   - **Screens / Tabs:** Vistas visuales de la app (`AdminPqrsTab`, `AdminAnalyticsTab`, `AdminHistorialTab`, `PqrsScreen`, etc.).
   - **Controllers (`StateNotifier`):** Controlan el estado asíncrono (`loading`, `data`, `error`) y ejecutan las acciones del usuario.
2. **`Domain Layer` (Entidades y Contratos):**
   - **Entities / Models:** Clases de datos inmutables con métodos `fromJson` y getters de ayuda para la UI.
   - **Repository Interfaces:** Contratos abstractos que definen qué operaciones existen sin acoplarse a la tecnología de red.
3. **`Data Layer` (Datos y Red):**
   - **Remote DataSources:** Realizan las conexiones reales usando `Dio` (para Go) y `SupabaseClient` (para PostgreSQL).
   - **Repositories Implementations:** Orquestan las llamadas al backend en Go y activan automáticamente el fallback de Supabase si la API de Go no responde.

---

## 🔐 2. Cómo se consume Supabase vs 🚀 Backend en Go

La aplicación distribuye sus responsabilidades de forma clara:

```mermaid
graph LR
    subgraph Frontend [📱 App Móvil Flutter]
        AppAuth[Módulo Auth & Perfil]
        AppOps[Módulo Admin & Reportes]
    end

    subgraph SupabaseLayer [🔐 Supabase Platform]
        AuthEngine[Supabase Auth Engine]
        PostgresDB[(🗄️ PostgreSQL Database)]
    end

    subgraph GoBackend [🚀 Servidor Go - Render API]
        GoEngine[Motor REST API / Gin]
    end

    AppAuth -->|SDK supabase_flutter| AuthEngine
    AppAuth -->|Inserción directa de PQRs/Reservas| PostgresDB
    AppOps -->|HTTP REST con Bearer JWT / Dio| GoEngine
    GoEngine -->|Lectura / Escritura SQL compleja| PostgresDB
```

---

### A. Consumo de Supabase

Supabase se consume mediante el SDK oficial `supabase_flutter` y se encarga de:

1. **Autenticación e Identidad:**
   - Registro, inicio de sesión y gestión de sesiones activas.
   - Emisión y renovación del **Token de Acceso JWT**.
   ```dart
   final response = await Supabase.instance.client.auth.signInWithPassword(
     email: email,
     password: password,
   );
   ```
2. **Operaciones Transaccionales del Cliente:**
   - Inserción y consulta básica de reservas, calificaciones y creación de PQRs desde el perfil del cliente.
   ```dart
   await _supabase
     .schema('soporte')
     .from('pqrs')
     .insert({
       'id_cliente': clienteId,
       'id_reserva': idReserva,
       'tipo_pqr': tipo,
       'descripcion': descripcion,
     });
   ```

---

### B. Consumo del Backend en Go (API REST)

El backend en Go (`https://apiserviya.onrender.com/api/v1`) se consume a través de un cliente centralizado de **`Dio`** (`api_client.dart`), encargado de la lógica analítica, administrativa y generación de reportes.

1. **Inyección Automática del Token JWT (Interceptor):**
   Cada petición que sale hacia Go incluye automáticamente el token de la sesión activa de Supabase en la cabecera HTTP:
   ```http
   Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6...
   ```

2. **Endpoints Principales Consumidos por la App:**

| Módulo | Método HTTP | Endpoint de Go | Descripción |
| :--- | :---: | :--- | :--- |
| **Buzón PQRs** | `GET` | `/api/v1/operativo/pqrs` | Retorna todas las PQRs cruzadas con nombres de clientes. |
| **Responder PQR** | `POST` | `/api/v1/operativo/pqrs/responder` | Guarda la respuesta del admin, cambia estado a `Cerrado` y fecha. |
| **Historial Servicios** | `GET` | `/api/v1/operativo/historial-servicios` | Listado consolidado de servicios realizados y en curso. |
| **Prestadores** | `GET` | `/api/v1/operativo/prestadores` | Disponibilidad en tiempo real y métricas operativas. |
| **Analíticas Admin** | `GET` | `/api/v1/reportes/admin?mes=M&anio=Y` | KPIs generales, ingresos y top de prestadores. |
| **Servicios Populares** | `GET` | `/api/v1/reportes/servicios-populares` | Demanda por categoría de servicio. |
| **Actividad Usuarios** | `GET` | `/api/v1/reportes/actividad-usuarios` | Métricas de clientes y prestadores activos. |
| **Descarga PDF** | `GET` | `/api/v1/reportes/admin/pdf?mes=M&anio=Y` | Generación y entrega del archivo binario PDF (`ResponseType.bytes`). |

---

## 📋 3. Recorrido Completo: Ciclo de una PQR

```mermaid
sequenceDiagram
    autonumber
    actor Cliente as 📱 Cliente (App)
    participant ClientScreen as PqrsScreen
    participant DB as 🗄️ Base de Datos (PostgreSQL)
    actor Admin as 👨‍💼 Administrador (App)
    participant AdminTab as AdminPqrsTab
    participant GoAPI as 🚀 Backend Go API (/operativo/pqrs)

    Note over Cliente,DB: PASO 1: Creación de la PQR
    Cliente->>ClientScreen: Selecciona Reserva, Tipo y escribe Descripción
    ClientScreen->>DB: Inserta PQR en tabla soporte.pqrs (estado: "Abierto")
    
    Note over Admin,GoAPI: PASO 2: Consulta del Administrador
    Admin->>AdminTab: Entra a pestaña "📋 Gestión de PQRs"
    AdminTab->>GoAPI: GET /api/v1/operativo/pqrs (con Bearer Token)
    GoAPI->>DB: SELECT p.*, u.nombre, u.apellido FROM soporte.pqrs JOIN seguridad.usuarios
    DB-->>GoAPI: Retorna registros
    GoAPI-->>AdminTab: JSON con listado de PQRs (nombres, estados, etc.)
    AdminTab->>Admin: Muestra tarjeta con Badge "ABIERTO" (ámbar)

    Note over Admin,DB: PASO 3: Respuesta del Administrador
    Admin->>AdminTab: Clic en "💬 Responder", escribe solución y presiona "Enviar"
    AdminTab->>GoAPI: POST /api/v1/operativo/pqrs/responder { id_pqr, respuesta_admin }
    GoAPI->>DB: UPDATE soporte.pqrs SET respuesta_admin = ?, estado_pqr = 'Cerrado', fecha_respuesta = NOW()
    DB-->>GoAPI: OK (Filas afectadas)
    GoAPI-->>AdminTab: 200 OK {"mensaje": "PQR respondida exitosamente"}
    AdminTab->>Admin: Actualiza tarjeta a "CERRADO" (verde) mostrando la respuesta

    Note over Cliente,DB: PASO 4: Visualización del Cliente
    Cliente->>ClientScreen: Abre su sección de PQRs
    ClientScreen->>DB: Consulta sus PQRs
    ClientScreen->>Cliente: Muestra recuadro verde "RESPUESTA DE SOPORTE" con el mensaje del admin
```

---

## 📄 4. Recorrido Completo: Descarga del Reporte PDF

```mermaid
sequenceDiagram
    autonumber
    actor Admin as 👨‍💼 Administrador
    participant UI as AdminAnalyticsTab
    participant Controller as AdminAnalyticsController
    participant GoAPI as 🚀 Backend Go (/reportes/admin/pdf)
    participant Platform as 🌐 Web / 📱 Móvil

    Admin->>UI: Selecciona Mes (1-12) y Año (hasta 2028)
    Admin->>UI: Clic en botón "📄 PDF"
    UI->>Controller: downloadPDF(mes, anio)
    Controller->>GoAPI: GET /api/v1/reportes/admin/pdf?mes=M&anio=Y (ResponseType.bytes + JWT)
    GoAPI->>GoAPI: Compila métricas y genera el binario del PDF
    GoAPI-->>Controller: Retorna flujo de bytes List<int> del PDF

    alt ¿Es Flutter Web? (Chrome / Edge / Navegador)
        Controller->>Platform: Crea html.Blob([bytes], 'application/pdf')
        Controller->>Platform: Genera URL de objeto y dispara AnchorElement.click()
        Platform->>Admin: 💾 Descarga automática del archivo .pdf en el navegador
    else ¿Es Móvil / Desktop? (Android / iOS / Windows)
        Controller->>Platform: Obtiene getApplicationDocumentsDirectory()
        Controller->>Platform: File('reporte_general_M_A.pdf').writeAsBytes(bytes)
        Controller->>Platform: OpenFilex.open(filePath)
        Platform->>Admin: 📱 Abre el PDF en el visor nativo del dispositivo
    end
```
