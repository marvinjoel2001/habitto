#!/bin/bash

# Script para iniciar el backend de Habitto en dos puertos
# Puerto 8000: WebSockets (Daphne)
# Puerto 8001: HTTP (Django runserver)

echo "🚀 Iniciando Backend de Habitto..."
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -d "../habitto_bk" ]; then
    echo "❌ Error: No se encuentra el directorio habitto_bk"
    echo "   Asegúrate de estar en el directorio correcto"
    exit 1
fi

# Verificar Redis
echo "🔍 Verificando Redis..."
if ! redis-cli ping > /dev/null 2>&1; then
    echo "⚠️  Redis no está corriendo. Intentando iniciar..."
    if command -v brew > /dev/null 2>&1; then
        brew services start redis
    else
        echo "❌ Por favor inicia Redis manualmente:"
        echo "   macOS: brew services start redis"
        echo "   Linux: sudo systemctl start redis"
        exit 1
    fi
fi
echo "✅ Redis está corriendo"
echo ""

# Cambiar al directorio del backend
cd ../habitto_bk

# Verificar entorno virtual
if [ ! -d "venv" ]; then
    echo "❌ Error: No se encuentra el entorno virtual"
    echo "   Crea uno con: python -m venv venv"
    exit 1
fi

# Activar entorno virtual
echo "🔧 Activando entorno virtual..."
source venv/bin/activate

# Verificar que daphne esté instalado
if ! python -c "import daphne" 2>/dev/null; then
    echo "⚠️  Daphne no está instalado. Instalando..."
    pip install daphne
fi

echo ""
echo "✅ Todo listo. Iniciando servidores..."
echo ""
echo "📡 WebSockets: http://0.0.0.0:8000"
echo "🌐 HTTP API:   http://0.0.0.0:8001"
echo ""
echo "Para detener: Ctrl+C en ambas terminales"
echo ""
echo "================================================"
echo ""

# Crear un script temporal para la segunda terminal
cat > /tmp/habitto_http.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
echo "🌐 Iniciando servidor HTTP en puerto 8001..."
python manage.py runserver 0.0.0.0:8001
EOF

chmod +x /tmp/habitto_http.sh

# Iniciar servidor HTTP en una nueva terminal
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    osascript -e 'tell app "Terminal" to do script "cd '"$(pwd)"' && bash /tmp/habitto_http.sh"'
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v gnome-terminal > /dev/null 2>&1; then
        gnome-terminal -- bash -c "cd $(pwd) && bash /tmp/habitto_http.sh; exec bash"
    elif command -v xterm > /dev/null 2>&1; then
        xterm -e "cd $(pwd) && bash /tmp/habitto_http.sh" &
    else
        echo "⚠️  No se pudo abrir una nueva terminal automáticamente"
        echo "   Por favor abre una nueva terminal y ejecuta:"
        echo "   cd $(pwd) && source venv/bin/activate && python manage.py runserver 0.0.0.0:8001"
    fi
fi

# Esperar un momento para que la otra terminal se abra
sleep 2

# Iniciar servidor WebSocket en esta terminal
echo "📡 Iniciando servidor WebSocket en puerto 8000..."
daphne -b 0.0.0.0 -p 8000 bk_habitto.asgi:application
