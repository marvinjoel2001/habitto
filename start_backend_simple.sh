#!/bin/bash

# Script simple para iniciar solo el servidor WebSocket
# Usa Daphne que puede manejar tanto HTTP como WebSockets en un solo puerto

echo "🚀 Iniciando Backend de Habitto (modo simple)..."
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d "../habitto_bk" ]; then
    echo "❌ Error: No se encuentra el directorio habitto_bk"
    exit 1
fi

# Verificar Redis
echo "🔍 Verificando Redis..."
if ! redis-cli ping > /dev/null 2>&1; then
    echo "⚠️  Redis no está corriendo. Intentando iniciar..."
    if command -v brew > /dev/null 2>&1; then
        brew services start redis
    else
        echo "❌ Por favor inicia Redis manualmente"
        exit 1
    fi
fi
echo "✅ Redis está corriendo"
echo ""

# Cambiar al directorio del backend
cd ../habitto_bk

# Activar entorno virtual
echo "🔧 Activando entorno virtual..."
source venv/bin/activate

# Verificar que daphne esté instalado
if ! python -c "import daphne" 2>/dev/null; then
    echo "⚠️  Daphne no está instalado. Instalando..."
    pip install daphne
fi

echo ""
echo "✅ Iniciando servidor en puerto 8000..."
echo "📡 WebSockets: ws://0.0.0.0:8000/ws/"
echo "🌐 HTTP API:   http://0.0.0.0:8000/api/"
echo ""
echo "⚠️  NOTA: Si usas este modo, actualiza el frontend:"
echo "   - baseUrl: 'http://10.0.2.2:8000'"
echo "   - wsPort: 8000"
echo ""
echo "Para detener: Ctrl+C"
echo ""

daphne -b 0.0.0.0 -p 8000 bk_habitto.asgi:application
