## Alcance
- Conectar los botones de “like” (corazón), “rechazar” (X) y “favorito” (estrella) del Home a la API de backend según la documentación actualizada.
- Usar el feed basado en matching para obtener `match.id` de cada propiedad y registrar feedback al hacer swipe o tocar los botones.
- Alinear la creación/actualización del SearchProfile con los endpoints documentados.

## Endpoints y Payloads (según documentación)
- `GET /api/recommendations/?type=property` → devuelve elementos `{ type, match }` con `match.id`, `subject_id` (ID de Property), `score`, `status`.
- `POST /api/matches/{id}/like/` → registra “like” y puede generar mensaje/notificación.
- `POST /api/matches/{id}/reject/` → rechaza el match; opcionalmente enviar `POST /api/match_feedback/` con `{ match, user, feedback_type: "dislike", reason }`.
- `POST /api/profiles/add_favorite/` → body `{ "property_id": <int> }`.
- `POST /api/profiles/remove_favorite/` → body `{ "property_id": <int> }`.
- `POST /api/search_profiles/` → crear/actualizar perfil de búsqueda del usuario autenticado con campos: `latitude/longitude`, `budget_min/max`, `desired_types`, `bedrooms_min/max`, `amenities`, `roommate_preference`, `roommate_preferences`, `vibes`, `preferred_zones`, `age`, `children_count`.
- `GET /api/properties/{id}/` → obtener detalle de la Property para renderizar la card a partir de `subject_id` del match.

## Diseño de Integración
- **Nuevo servicio MatchingService** (cliente):
  - `getPropertyRecommendations()` → llama `GET /api/recommendations/?type=property` y retorna lista de `{ matchId, propertyId }`.
  - `likeMatch(matchId)` → `POST /api/matches/{id}/like/`.
  - `rejectMatch(matchId)` → `POST /api/matches/{id}/reject/`.
  - `sendFeedback(matchId, type, reason?)` → `POST /api/match_feedback/`.
- **Nuevo servicio FavoritesService**:
  - `addFavorite(propertyId)` → `POST /api/profiles/add_favorite/`.
  - `removeFavorite(propertyId)` → `POST /api/profiles/remove_favorite/`.
- **Ajuste ProfileService (SearchProfile)**:
  - Cambiar a `POST /api/search_profiles/` con los campos documentados.

## Cambios en Home (ubicaciones exactas)
- **Feed**: `lib/features/home/presentation/pages/home_page.dart`
  - En `_loadAllProperties()` (líneas 311–365):
    - Sustituir carga por `PropertyService` para usar `MatchingService.getPropertyRecommendations()`.
    - Por cada match: llamar `GET /api/properties/{subject_id}/` y construir `HomePropertyCardData`.
    - Mantener un mapa `{ propertyId → matchId }` para acciones.
- **Gestos de swipe**: `PropertySwipeDeckState` (líneas 723–747 y 634–649):
  - Swipe derecha → `likeMatch(matchId)` antes de animar salida; mostrar `MatchModal` si éxito.
  - Swipe izquierda → `rejectMatch(matchId)` antes de animar salida; mantener overlay de X.
  - Botón “volver” (rotar izquierda) → opcional: `sendFeedback(matchId, 'neutral', 'undo')` del último elemento si se requiere deshacer.
- **Botones inferiores**: `HomeContent` (líneas 447–486):
  - Corazón (líneas 462–478): obtener `matchId` del `_currentTopProperty` y llamar `likeMatch(matchId)`; si OK, lanzar `MatchModal` y luego `swipeRight()`.
  - X (líneas 455–459): obtener `matchId` y llamar `rejectMatch(matchId)`; luego ejecutar `swipeLeft()` (ya existente).
  - Estrella (líneas 481–484): alternar favorito con `addFavorite(propertyId)`/`removeFavorite(propertyId)` usando el `propertyId` del top.

## Estados y Errores
- Mostrar feedback visual:
  - En éxito de like → burst de corazones + modal; en fallo → `SnackBar` con error.
  - En rechazo → overlay X; en fallo → `SnackBar` y no avanzar la card.
  - Favoritos → cambiar color/estado del icono estrella; en fallo → `SnackBar`.
- Timeouts y reintentos: usar `ApiService` existente; manejar `response['success']` vs `error` conforme.

## Creación/Actualización de SearchProfile
- Página `create_search_profile_page.dart`:
  - Mapear controles UI a payload del `POST /api/search_profiles/`.
  - Enviar coordenadas desde Mapbox si disponibles (`latitude/longitude`).
  - Guardar respuesta y notificar al usuario; volver al Home para que el feed use recomendaciones con mejor score.

## Verificación y Pruebas
- Ejecutar pruebas manuales:
  - Sin perfil de búsqueda: feed básico; con perfil creado: feed por recomendación.
  - Like/X por botón y por gesto; confirmar cambios en backend (notificación/mensaje si aplica).
  - Favoritos: agregar/quitar y verificar efecto visual y persistencia.
- Analizar logs y respuestas de API para asegurar que se usan los endpoints correctos.

## Entregables
- Servicios nuevos y ajustes de `HomeContent`/`PropertySwipeDeck` conectados a API.
- Manejo de estados visuales y errores.
- Alineación de `SearchProfile` con documentación.

¿Confirmo este plan para proceder con la implementación en el código?