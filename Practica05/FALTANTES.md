# Práctica 05: faltantes y ediciones

**Entrega:** viernes 6 de noviembre de 2026 · **Base:** Práctica 02, commit `bedc10e` (18 sep 2026)

## Ya copiado de Practica02 (sin cambios)

| Copiado | Qué es |
|---|---|
| `backend/` | Flask + MySQL + JWT + bcrypt: registro, login, sesión y CRUD de usuarios con roles |
| `docker-compose.yml` | MySQL + backend + frontend |
| `frontend/` | Web en Vue. **Opcional:** la P5 no lo pide; puedes quitarlo del compose |
| `.gitignore`, `.env` | `.env` es solo local: git ya lo ignora en esta carpeta |

**No copiado:** `android/`, porque el cliente Kotlin solo corre en Android y el PDF dice que no demuestra iOS. Sirve de guía para portar las pantallas a Flutter. Tampoco copié `images/` ni el README.

Orden sugerido: 0 → 1 → 2 → 3 → 4 → 6 → 5 → 7 → 8. Haz pronto la parte de Google Cloud (paso 5) y consigue la Mac (paso 7), porque son trámites que tardan.

---

## 0. Preparación rápida
- [ ] Primer commit **sin cambios**: "Practica 05 - Copia del backend de la Práctica 02". Así el historial separa lo reutilizado de lo nuevo.
- [ ] Etiqueta de la P2 para enlazarla en el README: `git tag practica02-final bedc10e` y `git push origin practica02-final`.
- [ ] ⚠️ `Practica02/.env` **sí está en GitHub** con contraseñas y claves JWT, y el PDF prohíbe subir secretos:
  - cambia los valores en `Practica05/.env` (no reutilices los publicados)
  - crea `.env.example` con las mismas claves y valores de ejemplo
  - opcional: `git rm --cached Practica02/.env` (deja de subirse, aunque sigue en el historial)
- [ ] `docker-compose.yml`: renombra los `container_name` (`login_mysql` → `p5_mysql`, etc.) o haz `docker compose down` en la P2, porque chocan.
- [ ] `backend/requirements.txt` está en **UTF-16**: pásalo a UTF-8 cuando agregues paquetes.
- [ ] `config.py` lee `MYSQL_DB`, pero el compose manda `MYSQL_DATABASE`. Hoy funciona solo porque coincide con el valor por defecto; unifica el nombre.

## 1. Backend (Flask): lo nuevo
Se reutilizan sin tocar: `POST /api/register`, `POST /api/login`, `GET /api/me`, `GET|POST /api/users`, `PUT|DELETE /api/users/{id}`.

- [ ] **Duración del token:** el JWT expira a los **15 min** por defecto. Sube `JWT_ACCESS_TOKEN_EXPIRES` (p. ej. 7 días) o agrega un refresh token; si no, no se puede "restaurar la sesión".
- [ ] **Modelos** en `models.py`:
  - `User`: `google_sub` (único, opcional), `auth_provider`, y `password_hash` opcional (las cuentas de Google no tienen contraseña)
  - `SearchHistory(id, user_id, query, created_at, client_id ÚNICO)`
  - `Favorite(user_id, work_key, title, author, cover_id, subjects, updated_at)` con `UNIQUE(user_id, work_key)` para que no haya duplicados
- [ ] `db.create_all()` no modifica tablas que ya existen: usa `docker compose down -v` para recrear la BD.
- [ ] `POST /api/auth/google`: recibe el `id_token`, lo valida con `google-auth` (`id_token.verify_oauth2_token`, audience = Web client ID), crea o vincula al usuario y devuelve el mismo JWT de siempre.
- [ ] Historial: `GET /api/history`, `POST /api/history` (si el `client_id` se repite, lo ignora), `DELETE /api/history`.
- [ ] Favoritos: `GET /api/favorites`, `PUT /api/favorites/{work_key}` (idempotente), `DELETE /api/favorites/{work_key}`.
- [ ] Admin, con `@admin_required` (la validación es en el backend, no solo en la interfaz): `GET /api/admin/users/{id}/history` y `GET /api/admin/users/{id}/favorites`.
- [ ] Los endpoints personales filtran por `get_jwt_identity()`, nunca por un `user_id` que mande el cliente.
- [ ] **HTTPS**: hoy el backend es `http://:5000`. Lo más rápido es agregar un servicio `cloudflare/cloudflared` al compose (`tunnel --url http://backend:5000`). Da una URL `https://….trycloudflare.com`, es gratis y no pide cuenta. Esa misma URL le sirve al iPhone o al simulador de la Mac para llegar al backend.

## 2. App Flutter (una sola, para Android e iOS)
- [ ] `flutter create` en `Practica05/app` (minSdk 24, iOS 15.0).
- [ ] Paquetes: `http` o `dio`, `sqflite`, `flutter_secure_storage`, `google_sign_in`, `connectivity_plus`, `uuid`.
- [ ] URL del backend y client IDs por `--dart-define` o en un archivo ignorado por git, no escritos en el código.
- [ ] Android: permiso `INTERNET` en `main/AndroidManifest.xml` (Flutter solo lo agrega en debug). Con HTTPS ya no hace falta el cleartext de la P2.
- [ ] Portar desde Kotlin: Login, Registro, Perfil y Usuarios (CRUD de admin).
- [ ] Sesión: JWT en `flutter_secure_storage`; al abrir la app se restaura con `GET /api/me`; botón de cerrar sesión.
- [ ] En cada lista, mostrar estos estados sin que la app se cierre: cargando (con el **tiempo en ms**), vacío, error HTTP, error de red y JSON mal formado.
- [ ] Indicador en línea / sin conexión y "Última actualización: …".

## 3. API pública: Open Library
- [ ] Búsqueda: `https://openlibrary.org/search.json?q=…&fields=key,title,author_name,cover_i,subject,first_publish_year&limit=20`
- [ ] Detalle: `/works/{id}.json` · Portadas: `https://covers.openlibrary.org/b/id/{cover_i}-M.jpg`
- [ ] Manejar sin resultados, errores, `429` (límite de consultas) y falta de red o tiempo agotado.
- [ ] Guardar en SQLite los resultados y detalles consultados para verlos sin conexión.

## 4. Base local + sincronización
- [ ] Tablas SQLite, todas con `user_id` para separar los datos por cuenta: `cache_busquedas`, `obras`, `historial`, `favoritos`, `pendientes(op_id, tipo, payload, intentos)`, `recomendaciones`, `meta(ultima_sync)`.
- [ ] Sincronizar al iniciar y al recuperar la red (con `connectivity_plus` y un ping a la API):
  1. subir los pendientes
  2. bajar historial y favoritos
  3. guardar la fecha
- [ ] Reintentos con espera creciente: 2 s, 4 s, 8 s… hasta 5 intentos.
- [ ] Favorito marcado sin red: se guarda en local y en `pendientes`, y se envía al volver la conexión. No se duplica gracias al PUT idempotente + `UNIQUE` + `op_id`.
- [ ] Documentar los conflictos. Ejemplo: "primero se aplican los pendientes locales y después el servidor es la fuente de verdad", y qué datos siguen disponibles al cerrar y reabrir la app.

## 5. Google Sign-In
- [ ] En Google Cloud Console: crear el proyecto, configurar la pantalla de consentimiento (con tus correos como *test users*) y crear 3 clientes OAuth:
  - **Web:** lo usa el backend para validar el token
  - **Android:** paquete + SHA-1, que sale de
    `keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android`
  - **iOS:** bundle id
- [ ] iOS: `GIDClientID` y el URL scheme (`REVERSED_CLIENT_ID`) en `Info.plist`.
- [ ] En Flutter: obtener el `idToken` con `serverClientId` = Web client ID, mandarlo a `POST /api/auth/google` y guardar el JWT propio que regresa.
- [ ] Demostrar en **ambas** plataformas: entrar → cerrar y reabrir la app (la sesión sigue) → cerrar sesión.

## 6. Pantallas: historial, favoritos, recomendaciones, admin
- [ ] **Historial** por usuario: al tocar una búsqueda se repite; se puede borrar.
- [ ] **Favoritos**: marcar y desmarcar desde los resultados y el detalle; siguen ahí después de reiniciar.
- [ ] **Recomendaciones** con una regla reproducible:
  1. contar los temas (`subject`) y autores de favoritos (peso 2) y de búsquedas (peso 1)
  2. buscar el tema con más puntos en Open Library
  3. quitar los libros que ya son favoritos
  4. mostrar al menos 3, cada uno con su motivo ("Porque guardaste X · tema: Fantasy")
  - Sin historial ni favoritos: mostrar un mensaje y sugerencias generales.
  - Guardarlas en SQLite para verlas sin conexión.
- [ ] **Admin**: elegir un usuario y ver su historial y favoritos. Probar también una cuenta normal que recibe `403`.

## 7. iOS (requiere Mac)
- [ ] Mac con Xcode; deployment target 15.0 (Podfile y Xcode); `pod install`.
- [ ] Repetir en iOS las mismas pruebas que en Android. Se permite simulador, pero hay que identificarlo.

## 8. Entregables
- [ ] **README en español e inglés** con:
  - requisitos y cómo correr en Android e iOS
  - `docker compose up`
  - configuración de API y OAuth sin secretos (`.env.example`, `--dart-define`)
  - cómo funciona la sincronización
  - enlace a la P2 (`practica02-final` / `bedc10e`) y tabla de **endpoints reutilizados vs. nuevos**
- [ ] **Informe técnico:** introducción, arquitectura (qué es común y qué es nativo), endpoints, modelo de datos, persistencia, autenticación, recomendaciones, resultados, conclusiones y bibliografía APA.
- [ ] **Matriz de pruebas** en Android **y** iOS. Columnas: dispositivo o simulador, versión del sistema, pasos, resultado esperado, resultado obtenido, captura. Escenarios mínimos:
  - consulta REST
  - búsqueda pública
  - estado vacío / error
  - entrar con Google y cerrar sesión
  - favoritos
  - recomendaciones
  - reinicio de la app
  - modo sin conexión
  - reconexión + sincronización
  - admin permitido / acceso denegado
- [ ] **Evidencias** (capturas o video) de las 2 plataformas: búsqueda, login, favoritos, recomendaciones, modo sin conexión, sincronización y admin. Incluir el cambio de conectividad en tiempo real.
- [ ] **Issues** en GitHub para cada defecto reproducible, enlazados desde la matriz.
- [ ] Contribuciones de los integrantes + declaración de las herramientas de IA usadas.
- [ ] **Exposición** de máximo 10 min: demo en Android e iOS y explicación del código compartido vs. nativo.
- [ ] Commits frecuentes dentro de `Practica05/` (el profesor pide historial verificable).
