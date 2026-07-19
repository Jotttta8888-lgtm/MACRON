#!/bin/bash
# ============================================================
# MACRON - Script de Arreglo Rapido
# Para cuando la instalacion anterior fallo
# ============================================================

set -e

MACRON_DIR="$HOME/Documents/MACRON"
MODELS_DIR="$HOME/.macron/models"

echo "========================================"
echo "  MACRON - Arreglo Rapido"
echo "========================================"
echo ""

# 1. Crear directorios faltantes
echo "[1/5] Creando directorios..."
mkdir -p "$MACRON_DIR"
mkdir -p "$MODELS_DIR"
mkdir -p "$HOME/.macron/data"
mkdir -p "$HOME/.macron/logs"
mkdir -p "$HOME/.macron/cache"
echo "  OK"

# 2. Verificar/copiar archivos Python
echo "[2/5] Verificando archivos Python..."

# Buscar archivos en ubicaciones comunes
FOUND=0
for src in \
    "$HOME/Desktop/MACRON PROYECT" \
    "$HOME/Desktop/MACRON" \
    "$HOME/Downloads" \
    "$HOME/Downloads/MACRON" \
    "$HOME/Documents/MACRON"
do
    if [ -d "$src" ]; then
        echo "  Encontrado directorio: $src"
        for file in MACRON_FUNCIONALIDADES_v2.py MACRON_TESTS_v2.1.py MACRON_WEB_UI_v2.1.py; do
            if [ -f "$src/$file" ] && [ ! -f "$MACRON_DIR/$file" ]; then
                cp "$src/$file" "$MACRON_DIR/"
                echo "    Copiado: $file"
                FOUND=$((FOUND+1))
            fi
        done
    fi
done

if [ $FOUND -eq 0 ]; then
    echo "  ADVERTENCIA: No se encontraron archivos MACRON para copiar"
    echo "  Descarga los archivos desde /mnt/agents/output/ y colocalos en:"
    echo "    $MACRON_DIR/"
fi

# 3. Crear entorno virtual si no existe
echo "[3/5] Verificando entorno virtual..."
VENV_DIR="$MACRON_DIR/venv"
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
    echo "  venv creado"
else
    echo "  venv ya existe"
fi

# 4. Descargar modelos dlib desde mirrors alternativos
echo "[4/5] Descargando modelos dlib..."
cd "$MODELS_DIR"

# Funcion para descargar con fallback
download_model() {
    local filename=$1
    local urls=(
        "https://huggingface.co/spaces/mikeee/model-downloads/resolve/main/${filename}.bz2"
        "https://github.com/davisking/dlib-models/raw/master/${filename}.bz2"
        "https://raw.githubusercontent.com/davisking/dlib-models/master/${filename}.bz2"
    )

    if [ -f "$filename" ]; then
        echo "  $filename ya existe"
        return 0
    fi

    for url in "${urls[@]}"; do
        echo "  Intentando: $url"
        if curl -L --max-time 30 -o "${filename}.bz2" "$url" 2>/dev/null; then
            # Verificar que es un archivo bzip2 valido
            if file "${filename}.bz2" | grep -q "bzip2"; then
                bunzip2 "${filename}.bz2"
                echo "  OK - $filename descargado"
                return 0
            else
                rm -f "${filename}.bz2"
                echo "  Archivo invalido, probando siguiente mirror..."
            fi
        fi
    done

    echo "  ERROR: No se pudo descargar $filename"
    echo "  Descarga manual desde: http://dlib.net/files/${filename}.bz2"
    return 1
}

download_model "shape_predictor_68_face_landmarks.dat"
download_model "dlib_face_recognition_resnet_model_v1.dat"

# 5. Verificar
echo "[5/5] Verificando..."
cd "$MACRON_DIR"

if [ -f "MACRON_FUNCIONALIDADES_v2.py" ]; then
    echo "  MACRON_FUNCIONALIDADES_v2.py: OK"
else
    echo "  MACRON_FUNCIONALIDADES_v2.py: FALTA"
fi

if [ -f "$MODELS_DIR/shape_predictor_68_face_landmarks.dat" ]; then
    echo "  shape_predictor: OK"
else
    echo "  shape_predictor: FALTA"
fi

if [ -f "$MODELS_DIR/dlib_face_recognition_resnet_model_v1.dat" ]; then
    echo "  face_recognition: OK"
else
    echo "  face_recognition: FALTA"
fi

echo ""
echo "========================================"
echo "  ARREGLO COMPLETADO"
echo "========================================"
echo ""
echo "Proximos pasos:"
echo "  1. source $VENV_DIR/bin/activate"
echo "  2. cd $MACRON_DIR"
echo "  3. python3 -c \"from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator; m = MacronOrchestrator()\""
echo ""
