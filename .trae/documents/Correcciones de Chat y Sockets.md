# Correcciones de Chat y Sockets (Frontend Flutter + Backend Django)

## Resumen de cambios

- Resolución dinámica de URLs HTTP/WS en `lib/config/app_config.dart`:
  - `httpBaseUri()` devuelve `http://localhost:8001` (iOS/macOS/desktop) o `http://10.0.2.2:8001` (emulador Android).
  - `wsScheme()` y `wsHost()` calculan esquema y host para WebSocket.
  - `buildWsUri(subpath, token)` construye URLs WS consistentes con puerto `8000` y añade `?token=<JWT>`.
- `ApiService` ahora usa `httpBaseUri()` como `baseUrl` para asegurar rutas HTTP consistentes.
- `ChatPage` y `ConversationPage` usan `AppConfig.buildWsUri(...)` y `wsInboxPath` para conectar a:
  - Inbox: `ws://<host>:8000/ws/chat/inbox/<user_id>/` (fallback: `/ws/notifications/<user_id>/`).
  - Conversaciones: `ws://<host>:8000/ws/chat/<room_id>/` con variaciones de slash final.
- Pruebas añadidas:
  - `test/chat_ws_url_test.dart`: verifica construcción de URLs WS para inbox y sala.
  - `test/widget_test.dart` actualizado a smoke test de `HabittoApp`.

## Configuración esperada del backend

- Script de arranque (`start_backend.sh`):
  - HTTP (Django): `0.0.0.0:8001`.
  - WebSockets (Daphne): `0.0.0.0:8000`.
  - Redis requerido para Channels.
- Rutas WebSocket:
  - `ws://<host>:8000/ws/chat/<room_id>/` para sala entre dos usuarios (`room_id = min-max`).
  - `ws://<host>:8000/ws/chat/inbox/<user_id>/` para notificaciones de conversaciones.
  - Fallback de inbox: `/ws/notifications/<user_id>/`.

## Autenticación y autorización

- HTTP: encabezado `Authorization: Bearer <access>` con refresh automático.
- WS: token JWT en query `?token=<access>`; el servidor valida identidad y cierra conexión si no coincide el `user_id`.

## Pruebas y validación

- Conexión estable: reconexión exponencial en inbox (`ChatPage`) tras cierre/errores.
- Envío/recepción: `ConversationPage` envía payload JSON y actualiza UI al recibir eco del servidor.
- Manejo de desconexiones: notificación visual y reconexión programada en inbox.
- Escalabilidad básica: construcción de URLs WS consistente para múltiples salas e inbox.

## Pasos de ejecución local

1. Iniciar backend con `./start_backend.sh` (requiere Redis activo).
2. Ejecutar tests del frontend: `flutter test -r compact`.
3. Ejecutar app:
   - Android emulador: base HTTP `10.0.2.2:8001` y WS `10.0.2.2:8000`.
   - iOS/macOS: base HTTP `localhost:8001` y WS `localhost:8000`.

## Notas

- Si el backend sirve HTTP en `8000` en vez de `8001`, ajuste `httpBaseUri()` en `AppConfig` para ese puerto.
- Para producción, use `wss` detrás de proxy inverso con certificados y asegure la validación de JWT en Channels.
