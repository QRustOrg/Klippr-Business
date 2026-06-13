# Business Frontend Architecture

## 1. Propósito

Este documento define la arquitectura del frontend **Business** de Klippr: una aplicación **Flutter** construida sobre el patrón **BLoC** y organizada por **bounded context / feature**.

El objetivo es establecer un blueprint claro antes de escribir código Dart, de modo que toda implementación futura siga la misma estructura de carpetas, separación de capas y convenciones de nombres.

Principios rectores:

- **Mantenibilidad**: cada feature vive aislada; un cambio en un BC no obliga a tocar los demás.
- **Escalabilidad**: agregar un nuevo BC o crecer uno existente no rompe la estructura global.
- **Claridad por feature**: la organización refleja el dominio del negocio (IAM, Promotions, Redemption, etc.), no detalles técnicos transversales.
- **Separación de responsabilidades**: UI, lógica de estado, acceso a datos y modelos están desacoplados.

Este archivo es **solo documentación**. No contiene implementación Dart, widgets, BLoCs reales, repositorios ni modelos. Los archivos `.md` listados dentro de los árboles son *placeholders* documentales que guiarán la futura implementación.

---

## 2. Stack base

| Paquete | Versión | Uso |
|---|---|---|
| `http` | ^1.6.0 | Consumo de la REST API de Klippr (peticiones GET/POST/PUT/DELETE, serialización de respuestas). |
| `bloc` | ^9.1.0 | Núcleo del patrón: definición de eventos, estados y transiciones puras de lógica. |
| `flutter_bloc` | ^9.1.1 | Integración de BLoC con el árbol de widgets (`BlocProvider`, `BlocBuilder`, `BlocListener`). |
| `shared_preferences` | ^2.5.5 | Persistencia ligera: sesión, token, flags de feature y preferencias locales del usuario. |

Reglas de stack:

- **`http`** es el único canal de red. Toda llamada remota pasa por `services` (cliente HTTP) y se expone a la app a través de `repository`.
- **`bloc` / `flutter_bloc`** controlan el estado de la UI y la navegación lógica (qué pantalla/estado mostrar según eventos del usuario o respuestas del backend).
- **`shared_preferences`** guarda únicamente **datos ligeros** (token de sesión, idioma, tema, flags). No reemplaza una base de datos: cache estructurado pesado se reserva para `db` en el futuro.

---

## 3. Arquitectura general

El flujo de datos y control sigue una separación estricta por capas:

```
UI / Views
   │   eventos (user actions)
   ▼
BLoC  ──────────────► emite States ──────────────► UI / Views (rebuild)
   │   solicita datos
   ▼
Repository  (abstrae el origen de datos)
   │
   ├──► Services / Remote API   (http)
   ├──► Prefs / Local           (shared_preferences)
   └──► db / Cache local        (solo si aplica, futuro)
   │
   ▼
Models   (dominio + DTO internos del frontend)
```

Responsabilidad de cada capa:

- **views**: solo presentación. **No contienen lógica de negocio**. Disparan eventos al BLoC y reconstruyen según el State recibido.
- **bloc**: orquesta **eventos** y **estados**. Decide transiciones, llama al repository y emite los States que la UI consume. Controla navegación lógica.
- **repository**: **abstrae el origen de datos**. La UI/BLoC no sabe si un dato viene de la API, de prefs o de cache local. Coordina services, prefs y db.
- **services**: clientes HTTP y utilidades de red. Aquí vive el consumo concreto de la REST API con `http`.
- **models**: representan el **dominio y los DTO internos** del frontend. Mapean las respuestas del backend a objetos usables por la app (vía `mappers`).
- **mappers**: conversión entre DTO/response del backend y modelos de dominio del frontend.
- **prefs**: **persistencia ligera** con `shared_preferences` (token, flags, preferencias).
- **db**: reservado para **cache local futura** (solo se usará si un BC lo requiere; hoy son placeholders).
- **utils**: helpers transversales sin estado (formateadores, validadores, constantes locales del feature).

Regla de oro: **las dependencias apuntan hacia adentro**. Views dependen de BLoC; BLoC depende de Repository; Repository depende de Services/Prefs/db y Models. Nunca al revés.

---

## 4. Bounded Contexts

Cada bounded context (BC) mantiene la misma estructura por capas. No todos usan todas las subcarpetas (p. ej. no todos necesitan `db/`), pero todos conservan la **misma consistencia arquitectónica**.

Patrón base por BC:

```
<bc>/
├── bloc/
│   ├── <bc>_bloc.md
│   ├── <bc>_event.md
│   └── <bc>_state.md
├── models/
│   ├── <bc>_model.md
│   ├── <bc>_dto.md
│   └── <bc>_response.md
├── repository/
│   └── <bc>_repository.md
├── services/
│   └── <bc>_service.md
├── mappers/
│   └── <bc>_mapper.md
├── views/
│   ├── <bc>_screen.md
│   ├── <bc>_widget.md
│   └── <bc>_item.md
├── prefs/
│   └── <bc>_preferences.md
└── db/
    └── <bc>_cache.md
```

---

### 4.1 IAM

**Descripción funcional**: autenticación e identidad del usuario Business (acceso, registro, manejo de sesión y permisos por rol).

**Responsabilidades**:
- Sign in y sign up del usuario Business.
- Manejo de sesión (login/logout, expiración).
- Almacenamiento del token de sesión.
- Control de acceso basado en rol (role-based access).
- Bootstrap del perfil tras autenticar (si el backend lo requiere).

**Source tree**:

```
iam/
├── bloc/
│   ├── iam_bloc.md
│   ├── iam_event.md          # SignInRequested, SignUpRequested, SignOutRequested
│   └── iam_state.md          # Authenticated, Unauthenticated, AuthLoading, AuthFailure
├── models/
│   ├── auth_model.md         # sesión + rol en dominio
│   ├── credentials_dto.md    # payload de login/registro
│   └── auth_response.md      # token + datos del backend
├── repository/
│   └── iam_repository.md     # coordina auth_service + prefs (token)
├── services/
│   └── iam_service.md        # http: /auth/sign-in, /auth/sign-up
├── mappers/
│   └── auth_mapper.md        # auth_response -> auth_model
├── views/
│   ├── sign_in_screen.md
│   ├── sign_up_screen.md
│   └── auth_form_widget.md
└── prefs/
    └── iam_preferences.md    # token, role, isLoggedIn flag
```

---

### 4.2 Profile

**Descripción funcional**: gestión del perfil de usuario y del perfil de negocio (datos, verificación y metadata del Business).

**Responsabilidades**:
- Perfil de usuario y perfil de negocio.
- Actualización de perfil.
- Estado de verificación del negocio.
- Metadata del negocio (categoría, horarios, ubicación, contacto).
- Manejo de imágenes (logo / portada) si aplica.

**Source tree**:

```
profile/
├── bloc/
│   ├── profile_bloc.md
│   ├── profile_event.md      # LoadProfile, UpdateProfile, UploadImage
│   └── profile_state.md      # ProfileLoaded, ProfileUpdating, ProfileError
├── models/
│   ├── business_profile_model.md
│   ├── profile_dto.md
│   └── profile_response.md
├── repository/
│   └── profile_repository.md
├── services/
│   └── profile_service.md    # http: /profile, /profile/business
├── mappers/
│   └── profile_mapper.md
├── views/
│   ├── profile_screen.md
│   ├── edit_profile_screen.md
│   └── verification_badge_widget.md
└── prefs/
    └── profile_preferences.md  # cache ligera del perfil actual
```

---

### 4.3 Promotions

**Descripción funcional**: gestión de promociones creadas por el negocio (núcleo del perfil Business).

**Responsabilidades**:
- Listar promociones activas.
- Detalle de promoción.
- Crear promoción.
- Actualizar promoción.
- Publicar / cancelar promoción.
- Cache local de promociones.
- Soporte offline a futuro.

**Source tree**:

```
promotions/
├── bloc/
│   ├── promotions_bloc.md
│   ├── promotions_event.md   # LoadPromotions, CreatePromotion, PublishPromotion, CancelPromotion
│   └── promotions_state.md   # PromotionsLoaded, PromotionDetail, PromotionSaving
├── models/
│   ├── promotion_model.md
│   ├── promotion_dto.md
│   └── promotion_response.md
├── repository/
│   └── promotions_repository.md
├── services/
│   └── promotions_service.md # http: /promotions CRUD + publish/cancel
├── mappers/
│   └── promotion_mapper.md
├── views/
│   ├── promotions_list_screen.md
│   ├── promotion_detail_screen.md
│   ├── promotion_form_screen.md
│   └── promotion_item.md
├── prefs/
│   └── promotions_preferences.md  # filtros/orden preferidos
└── db/
    └── promotions_cache.md        # cache local + base offline (futuro)
```

---

### 4.4 Redemption

**Descripción funcional**: canje de promociones por parte del negocio (validación en local del comercio).

**Responsabilidades**:
- Generar un canje (redemption).
- Confirmar un canje.
- Historial de canjes.
- Manejo de QR o código.
- Seguimiento del estado del canje (pending, confirmed, expired).

**Source tree**:

```
redemption/
├── bloc/
│   ├── redemption_bloc.md
│   ├── redemption_event.md   # GenerateRedemption, ConfirmRedemption, LoadHistory
│   └── redemption_state.md   # RedemptionGenerated, RedemptionConfirmed, RedemptionError
├── models/
│   ├── redemption_model.md
│   ├── redemption_dto.md
│   └── redemption_response.md
├── repository/
│   └── redemption_repository.md
├── services/
│   └── redemption_service.md # http: /redemptions generate/confirm/history
├── mappers/
│   └── redemption_mapper.md
├── views/
│   ├── redemption_scan_screen.md   # QR / código
│   ├── redemption_history_screen.md
│   └── redemption_item.md
└── db/
    └── redemption_cache.md         # historial cache (futuro)
```

---

### 4.5 Favorites

**Descripción funcional**: promociones o entidades marcadas como favoritas para acceso rápido.

**Responsabilidades**:
- Guardar promoción en favoritos.
- Quitar promoción de favoritos.
- Listar favoritos.
- Persistencia local.
- Estrategia de sincronización a futuro (si se requiere).

**Source tree**:

```
favorites/
├── bloc/
│   ├── favorites_bloc.md
│   ├── favorites_event.md    # AddFavorite, RemoveFavorite, LoadFavorites
│   └── favorites_state.md    # FavoritesLoaded, FavoritesEmpty
├── models/
│   ├── favorite_model.md
│   └── favorite_dto.md
├── repository/
│   └── favorites_repository.md
├── views/
│   ├── favorites_screen.md
│   └── favorite_item.md
├── prefs/
│   └── favorites_preferences.md   # ids favoritos (persistencia ligera)
└── db/
    └── favorites_cache.md         # sync futuro
```

---

### 4.6 Community

**Descripción funcional**: interacción social alrededor del negocio (reseñas y calificaciones).

**Responsabilidades**:
- Reseñas (reviews).
- Calificaciones (ratings).
- Crear reseña / respuesta del negocio.
- Listar reseñas.
- Moderación o feedback del negocio (si aplica).

**Source tree**:

```
community/
├── bloc/
│   ├── community_bloc.md
│   ├── community_event.md    # LoadReviews, CreateReview, ReplyReview
│   └── community_state.md    # ReviewsLoaded, ReviewSubmitting
├── models/
│   ├── review_model.md
│   ├── rating_model.md
│   └── review_response.md
├── repository/
│   └── community_repository.md
├── services/
│   └── community_service.md  # http: /reviews, /ratings
├── mappers/
│   └── review_mapper.md
└── views/
    ├── reviews_screen.md
    ├── review_form_widget.md
    └── review_item.md
```

---

### 4.7 Settings

**Descripción funcional**: configuración local de la app y preferencias del usuario Business.

**Responsabilidades**:
- Preferencias de notificación.
- Configuración de privacidad.
- Tema (light/dark).
- Idioma (language).
- Zona horaria (timezone).
- Persistencia local con `shared_preferences`.

**Source tree**:

```
settings/
├── bloc/
│   ├── settings_bloc.md
│   ├── settings_event.md     # ChangeTheme, ChangeLanguage, ToggleNotifications
│   └── settings_state.md     # SettingsLoaded
├── models/
│   └── settings_model.md     # theme, language, timezone, notif flags
├── repository/
│   └── settings_repository.md
├── views/
│   ├── settings_screen.md
│   ├── notifications_settings_widget.md
│   └── privacy_settings_widget.md
└── prefs/
    └── settings_preferences.md   # núcleo de persistencia (shared_preferences)
```

---

### 4.8 Analytics

**Descripción funcional**: métricas y dashboard del negocio.

**Responsabilidades**:
- Métricas del negocio.
- Dashboard Business.
- Reportes de abuso (si aplica).
- Summary cards (tarjetas de resumen).
- Modelos listos para gráficos (chart-ready).

**Source tree**:

```
analytics/
├── bloc/
│   ├── analytics_bloc.md
│   ├── analytics_event.md    # LoadDashboard, LoadMetrics
│   └── analytics_state.md    # DashboardLoaded, MetricsLoaded
├── models/
│   ├── metric_model.md
│   ├── summary_card_model.md
│   ├── chart_data_model.md   # estructura chart-ready
│   └── analytics_response.md
├── repository/
│   └── analytics_repository.md
├── services/
│   └── analytics_service.md  # http: /analytics, /metrics
├── mappers/
│   └── analytics_mapper.md
├── views/
│   ├── dashboard_screen.md
│   ├── summary_card_widget.md
│   └── chart_widget.md
└── db/
    └── analytics_cache.md        # cache de métricas (futuro)
```

---

## 5. Core / Shared

Componentes transversales reutilizados por todos los BC. **No contiene lógica de negocio de ningún feature**; solo infraestructura y utilidades compartidas.

**Responsabilidades**:
- Cliente de red base (`http`) configurado (headers, baseUrl, interceptores).
- Configuración de API (endpoints, timeouts, environment).
- Constantes globales.
- Wrappers de resultado (`Result` / `Either`-like) para éxito/error tipado.
- Manejo de excepciones (network, parsing, auth).
- Tema base de la app.
- Widgets reutilizables (botones, loaders, inputs, error views).
- Helpers de preferencias locales (wrapper de `shared_preferences`).
- Helpers de cache (base para `db` futura).

**Source tree**:

```
core/
├── network/
│   ├── api_client.md         # cliente http base
│   ├── api_config.md         # baseUrl, endpoints, timeouts
│   └── api_exceptions.md     # manejo de errores de red
├── prefs/
│   └── prefs_helper.md       # wrapper de shared_preferences
├── db/
│   └── cache_helper.md       # base de cache local (futuro)
├── utils/
│   ├── result.md             # result/wrapper de respuesta
│   ├── constants.md
│   └── validators.md
└── widgets/
    ├── app_button.md
    ├── loading_indicator.md
    └── error_view.md
```

La carpeta `navigation/` (a nivel raíz de `lib/`) define el grafo de rutas y la navegación entre BCs, alimentada por los States emitidos por cada BLoC.

---

## 6. Dependencias y responsabilidad de cada paquete

| Paquete | Capa donde vive | Responsabilidad concreta |
|---|---|---|
| `http` | `services` / `core/network` | Realizar peticiones a la REST API y devolver respuestas crudas. Único canal de red. |
| `bloc` | `bloc` | Definir eventos, estados y la lógica pura de transición. Independiente del UI framework. |
| `flutter_bloc` | `bloc` ↔ `views` | Conectar los BLoCs con el árbol de widgets (`BlocProvider`, `BlocBuilder`, `BlocListener`). Controla estados de UI y navegación lógica. |
| `shared_preferences` | `prefs` / `core/prefs` | Persistir datos ligeros: token de sesión, flags, idioma, tema, preferencias. **No** para datos estructurados pesados. |

Aclaraciones clave:

- **`shared_preferences` = datos ligeros.** **`http` = red.** No se mezclan responsabilidades.
- **BLoC controla los estados de la UI y la navegación lógica.** La UI nunca decide flujo por sí sola.
- Cache estructurado pesado, cuando exista, irá en `db` (no en `shared_preferences`).

---

## 7. Justificación: por qué feature-first / bounded context

Klippr Business crecerá feature por feature (promociones, canjes, comunidad, analítica…). Una arquitectura **feature-first por bounded context** es superior a la organización global por tipo (`models/`, `views/`, `viewmodels/`) por estas razones:

- **Aislamiento de cambios**: cada BC encapsula su `bloc`, `models`, `repository`, `services` y `views`. Modificar Promotions no obliga a tocar Redemption ni Analytics.
- **Escala sin fricción**: agregar un nuevo BC es crear una carpeta con el mismo patrón. La estructura global no se reorganiza.
- **Onboarding claro**: un desarrollador encuentra todo lo de un feature en un solo lugar, no disperso entre carpetas técnicas globales.
- **Cohesión alta, acoplamiento bajo**: el dominio guía la estructura; las dependencias técnicas (red, prefs) se concentran en `core`.
- **Coherencia con BLoC**: cada BC tiene su propio ciclo evento→estado bien delimitado, evitando BLoCs monolíticos.

Por eso **no** se usa una arquitectura global tipo `model/view/viewmodel`, ni gestores de estado distintos a BLoC (**sin Riverpod, Provider ni GetX**).

---

## 8. Notas de implementación futura

- Este árbol todavía **no contiene implementación Dart**. Los `.md` listados son placeholders documentales.
- Orden sugerido de implementación:
  1. `core/` (network, prefs, result wrappers, widgets base, tema).
  2. `iam/` (sesión y token son prerequisito del resto).
  3. `profile/`.
  4. `promotions/` y `redemption/` (núcleo del valor Business).
  5. `favorites/`, `community/`, `settings/`, `analytics/`.
  6. `navigation/` evoluciona junto con cada BC.
- Mantener la **gestión de estado exclusivamente con BLoC** (`bloc` / `flutter_bloc`).
- `db/` se materializa solo cuando un BC necesite cache local real u offline; hasta entonces son placeholders.
- Todo acceso a red pasa por `services` y se expone vía `repository`; las `views` jamás llaman `http` directamente.

### Árbol completo propuesto

```
lib/
├── core/
│   ├── network/
│   ├── prefs/
│   ├── db/
│   ├── utils/
│   └── widgets/
├── iam/
│   ├── bloc/
│   ├── models/
│   ├── repository/
│   ├── services/
│   ├── mappers/
│   ├── views/
│   └── prefs/
├── profile/
│   ├── bloc/
│   ├── models/
│   ├── repository/
│   ├── services/
│   ├── mappers/
│   ├── views/
│   └── prefs/
├── promotions/
│   ├── bloc/
│   ├── models/
│   ├── repository/
│   ├── services/
│   ├── mappers/
│   ├── views/
│   ├── prefs/
│   └── db/
├── redemption/
│   ├── bloc/
│   ├── models/
│   ├── repository/
│   ├── services/
│   ├── mappers/
│   ├── views/
│   └── db/
├── favorites/
│   ├── bloc/
│   ├── models/
│   ├── repository/
│   ├── views/
│   ├── prefs/
│   └── db/
├── community/
│   ├── bloc/
│   ├── models/
│   ├── repository/
│   ├── services/
│   ├── mappers/
│   └── views/
├── settings/
│   ├── bloc/
│   ├── models/
│   ├── repository/
│   ├── views/
│   └── prefs/
├── analytics/
│   ├── bloc/
│   ├── models/
│   ├── repository/
│   ├── services/
│   ├── mappers/
│   ├── views/
│   └── db/
└── navigation/
    └── app_router.md
```

### Resumen de intención por bounded context

| BC | Intención |
|---|---|
| **IAM** | Acceso, registro, sesión, token y permisos por rol. |
| **Profile** | Perfil de usuario y negocio, verificación, metadata, imágenes. |
| **Promotions** | CRUD de promociones, publicar/cancelar, cache y offline futuro. |
| **Redemption** | Generar/confirmar canjes, QR/código, historial y estado. |
| **Favorites** | Guardar/quitar/listar favoritos con persistencia local. |
| **Community** | Reseñas, calificaciones, respuestas del negocio. |
| **Settings** | Notificaciones, privacidad, tema, idioma, timezone (shared_preferences). |
| **Analytics** | Métricas, dashboard, summary cards y modelos chart-ready. |
| **Core / Shared** | Red base, config API, wrappers, excepciones, tema, widgets y helpers. |
