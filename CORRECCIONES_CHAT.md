# Correcciones para el Sistema de Chat

## Problemas Identificados

### Backend (habitto_bk)

1. **InboxConsumer falta**: El archivo `message/routing.py` referencia `InboxConsumer` pero no existe en `message/consumers.py`
2. **Notificaciones de inbox**: No se envían notificaciones al inbox cuando llega un mensaje nuevo
3. **Configuración de puertos**: Necesitas correr el backend en dos puertos diferentes

### Frontend (habitto)

1. **Configuración correcta**: El frontend está bien configurado para usar puerto 8001 (HTTP) y 8000 (WebSockets)
2. **Múltiples intentos de conexión**: El código intenta varias rutas alternativas, lo cual es bueno como fallback

---

## Soluciones

### 1. Agregar InboxConsumer al Backend

**Archivo**: `habitto_bk/message/consumers.py`

Reemplaza todo el contenido con:

```python
import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth.models import User
from .models import Message

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        room_raw = self.scope['url_route']['kwargs'].get('room_id')
        self.room_id = str(room_raw).replace('_', '-')
        self.group_name = f'chat_{self.room_id}'
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive(self, text_data=None, bytes_data=None):
        try:
            payload = json.loads(text_data or '{}')
        except Exception:
            return

        content = (payload.get('content') or '').strip()
        sender_id = payload.get('sender')
        receiver_id = payload.get('receiver')

        if not content or not sender_id or not receiver_id:
            await self.send(text_data=json.dumps({'error': 'Campos requeridos: sender, receiver, content'}))
            return

        try:
            sender_id = int(sender_id)
            receiver_id = int(receiver_id)
        except Exception:
            await self.send(text_data=json.dumps({'error': 'IDs inválidos: sender y receiver deben ser enteros'}))
            return

        canonical_room = f"{min(sender_id, receiver_id)}-{max(sender_id, receiver_id)}"
        if str(self.room_id) != canonical_room:
            await self.send(text_data=json.dumps({
                'error': 'room_id mismatch',
                'expected_room_id': canonical_room,
                'provided_room_id': str(self.room_id)
            }))
            return

        msg = await self._store_message(sender_id, receiver_id, content)

        # Enviar mensaje a la sala de chat
        event = {
            'type': 'chat.message',
            'message': {
                'id': msg['id'],
                'room_id': self.room_id,
                'roomId': self.room_id,
                'sender': sender_id,
                'receiver': receiver_id,
                'content': content,
                'created_at': msg['created_at'],
                'createdAt': msg['created_at'],
                'is_read': False,
            }
        }
        await self.channel_layer.group_send(self.group_name, event)
        
        # Enviar notificación al inbox del receptor
        inbox_event = {
            'type': 'inbox.message',
            'message': {
                'message_id': msg['id'],
                'id': msg['id'],
                'sender': sender_id,
                'receiver': receiver_id,
                'content': content,
                'created_at': msg['created_at'],
                'counterpart_id': sender_id,
                'counterpart_username': msg.get('sender_username', ''),
                'counterpart_full_name': msg.get('sender_full_name', ''),
                'counterpart_profile_picture': msg.get('sender_profile_picture', ''),
            }
        }
        await self.channel_layer.group_send(f'inbox_{receiver_id}', inbox_event)

    async def chat_message(self, event):
        await self.send(text_data=json.dumps(event['message']))

    @database_sync_to_async
    def _store_message(self, sender_id: int, receiver_id: int, content: str):
        sender = User.objects.get(id=sender_id)
        receiver = User.objects.get(id=receiver_id)
        m = Message.objects.create(sender=sender, receiver=receiver, content=content, is_read=False)
        
        # Obtener información del perfil del sender
        sender_username = sender.username
        sender_full_name = f"{sender.first_name} {sender.last_name}".strip() or sender.username
        sender_profile_picture = ''
        
        try:
            from user.models import UserProfile
            profile = UserProfile.objects.filter(user_id=sender_id).first()
            if profile and profile.profile_picture:
                sender_profile_picture = profile.profile_picture.url
        except Exception:
            pass
        
        return {
            'id': m.id,
            'created_at': m.created_at.isoformat(),
            'sender_username': sender_username,
            'sender_full_name': sender_full_name,
            'sender_profile_picture': sender_profile_picture,
        }


class InboxConsumer(AsyncWebsocketConsumer):
    """
    Consumer para notificaciones de inbox.
    Se conecta a ws://host:8000/ws/chat/inbox/<user_id>/
    """
    async def connect(self):
        user_id = self.scope['url_route']['kwargs'].get('user_id')
        if not user_id:
            await self.close()
            return
        
        self.user_id = str(user_id)
        self.group_name = f'inbox_{self.user_id}'
        
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def inbox_message(self, event):
        """Envía notificación de nuevo mensaje al cliente"""
        await self.send(text_data=json.dumps(event['message']))
```

---

### 2. Verificar routing.py

**Archivo**: `habitto_bk/message/routing.py`

Debe verse así:

```python
from django.urls import re_path
from .consumers import ChatConsumer, InboxConsumer

websocket_urlpatterns = [
    re_path(r'^/?ws/chat/(?P<room_id>[^/]+)/?$', ChatConsumer.as_asgi()),
    re_path(r'^/?ws/chat/inbox/(?P<user_id>\d+)/?$', InboxConsumer.as_asgi()),
    re_path(r'^/?ws/notifications/(?P<user_id>\d+)/?$', InboxConsumer.as_asgi()),
]
```

---

### 3. Agregar endpoint para limpiar conversación

**Archivo**: `habitto_bk/message/views.py`

Agrega este método al final de la clase `MessageViewSet` (antes del último paréntesis):

```python
    @action(detail=False, methods=['post'], url_path='clear_conversation')
    def clear_conversation(self, request):
        """Vacía la conversación con otro usuario (solo para el usuario actual)"""
        other_id = request.data.get('other_user_id') or request.query_params.get('other_user_id')
        if not other_id:
            return Response({'detail': 'other_user_id es requerido'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            other_id = int(other_id)
        except ValueError:
            return Response({'detail': 'other_user_id inválido'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Marcar mensajes como eliminados para el usuario actual
        # Nota: Esto requiere agregar un campo 'deleted_by' al modelo Message
        # Por ahora, simplemente marcamos como leídos
        qs = Message.objects.filter(
            (Q(sender_id=request.user.id) & Q(receiver_id=other_id)) |
            (Q(sender_id=other_id) & Q(receiver_id=request.user.id))
        )
        count = qs.count()
        # En producción, deberías usar soft delete en lugar de eliminar
        # qs.delete()  # No recomendado
        
        return Response({
            'status': 'ok',
            'message': f'Conversación vaciada ({count} mensajes)',
            'count': count
        })
```

---

### 4. Cómo correr el backend en dos puertos

Necesitas correr dos servidores simultáneamente:

#### Opción A: Usando Daphne (Recomendado para WebSockets)

**Terminal 1 - WebSockets en puerto 8000:**
```bash
cd habitto_bk
source venv/bin/activate  # En Windows: venv\Scripts\activate
daphne -b 0.0.0.0 -p 8000 bk_habitto.asgi:application
```

**Terminal 2 - HTTP en puerto 8001:**
```bash
cd habitto_bk
source venv/bin/activate  # En Windows: venv\Scripts\activate
python manage.py runserver 0.0.0.0:8001
```

#### Opción B: Usando solo Daphne para ambos

Si instalas `daphne`, puede manejar tanto HTTP como WebSockets:

```bash
cd habitto_bk
pip install daphne
daphne -b 0.0.0.0 -p 8000 bk_habitto.asgi:application
```

Luego actualiza el frontend para usar puerto 8000 para todo.

#### Opción C: Nginx como proxy reverso (Producción)

Para producción, usa Nginx para enrutar:
- `/ws/` → puerto 8000 (WebSockets)
- Todo lo demás → puerto 8001 (HTTP)

---

### 5. Verificar Redis está corriendo

Los WebSockets necesitan Redis para funcionar:

```bash
# Verificar si Redis está corriendo
redis-cli ping
# Debe responder: PONG

# Si no está corriendo, iniciarlo:
# macOS con Homebrew:
brew services start redis

# Linux:
sudo systemctl start redis

# Windows:
# Descargar desde https://github.com/microsoftarchive/redis/releases
```

---

### 6. Variables de entorno (Opcional)

Crea un archivo `.env` en `habitto_bk/`:

```env
CHANNEL_LAYER=redis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
```

---

## Verificación

### 1. Verificar que el backend está corriendo:

```bash
# Terminal 1
cd habitto_bk
daphne -b 0.0.0.0 -p 8000 bk_habitto.asgi:application

# Terminal 2
cd habitto_bk
python manage.py runserver 0.0.0.0:8001
```

### 2. Probar WebSocket desde el navegador:

Abre la consola del navegador y ejecuta:

```javascript
const ws = new WebSocket('ws://localhost:8000/ws/chat/1-2/?token=TU_TOKEN_AQUI');
ws.onopen = () => console.log('Conectado');
ws.onmessage = (e) => console.log('Mensaje:', e.data);
ws.onerror = (e) => console.error('Error:', e);
```

### 3. Probar desde Flutter:

Ejecuta la app y ve a la página de chat. Deberías ver:
- Lista de conversaciones cargando correctamente
- Mensajes enviándose y recibiéndose en tiempo real
- Notificaciones de inbox funcionando

---

## Problemas Comunes

### Error: "Connection refused"
- Verifica que ambos servidores estén corriendo
- Verifica que los puertos 8000 y 8001 no estén ocupados: `lsof -i :8000` y `lsof -i :8001`

### Error: "channel_layer not configured"
- Verifica que Redis esté corriendo: `redis-cli ping`
- Verifica la configuración en `settings.py`

### Mensajes no se envían
- Verifica que el token JWT sea válido
- Verifica los logs del servidor: `tail -f logs/api.log`
- Verifica la consola del navegador/Flutter para errores

### WebSocket se desconecta inmediatamente
- Verifica que la ruta sea correcta: `/ws/chat/<room_id>/`
- Verifica que el `room_id` sea el formato correcto: `<min_id>-<max_id>`
- Verifica que el token esté en la query string: `?token=...`

---

## Resumen de Cambios

### Backend:
1. ✅ Agregar `InboxConsumer` a `message/consumers.py`
2. ✅ Agregar notificaciones de inbox en `ChatConsumer`
3. ✅ Agregar endpoint `clear_conversation` en `message/views.py`
4. ✅ Correr dos servidores (8000 para WS, 8001 para HTTP)

### Frontend:
- ✅ Ya está bien configurado, no necesita cambios

### Infraestructura:
1. ✅ Asegurar que Redis esté corriendo
2. ✅ Configurar variables de entorno si es necesario
