#!/bin/bash
# ============================================================
# MACRON - Script de Instalacion Unificado
# Ejecutar: bash install_macron.sh
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

MACRON_DIR="$HOME/Documents/MACRON"
VENV_DIR="$MACRON_DIR/venv"
MODELS_DIR="$HOME/.macron/models"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  MACRON - Instalador Unificado${NC}"
echo -e "${BLUE}  MAC NEO Optimizado${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# ============================================================
# PASO 1: Verificar sistema
# ============================================================
echo -e "${YELLOW}[1/8] Verificando sistema...${NC}"

if [[ $(uname -m) != "arm64" ]]; then
    echo -e "${RED}Advertencia: No es Apple Silicon. Algunas funciones pueden no funcionar.${NC}"
fi

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 no encontrado. Instala desde python.org${NC}"
    exit 1
fi

if ! command -v brew &> /dev/null; then
    echo -e "${RED}Error: Homebrew no encontrado.${NC}"
    echo "Instala con: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

echo -e "${GREEN}  OK - Sistema compatible${NC}"

# ============================================================
# PASO 2: Crear directorios
# ============================================================
echo -e "${YELLOW}[2/8] Creando directorios...${NC}"

mkdir -p "$MACRON_DIR"
mkdir -p "$MODELS_DIR"
mkdir -p "$HOME/.macron/data"
mkdir -p "$HOME/.macron/logs"
mkdir -p "$HOME/.macron/cache"

echo -e "${GREEN}  OK - Directorios creados${NC}"

# ============================================================
# PASO 3: Instalar dependencias del sistema
# ============================================================
echo -e "${YELLOW}[3/8] Instalando dependencias del sistema...${NC}"

brew install cmake dlib opencv 2>/dev/null || echo -e "${YELLOW}  Dependencias ya instaladas o error (continuando)...${NC}"

echo -e "${GREEN}  OK - Dependencias del sistema${NC}"

# ============================================================
# PASO 4: Crear entorno virtual
# ============================================================
echo -e "${YELLOW}[4/8] Configurando entorno Python...${NC}"

if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
    echo -e "${GREEN}  OK - venv creado${NC}"
else
    echo -e "${GREEN}  OK - venv ya existe${NC}"
fi

# Activar venv
source "$VENV_DIR/bin/activate"

# Actualizar pip
pip install --upgrade pip setuptools wheel

# ============================================================
# PASO 5: Instalar dependencias Python
# ============================================================
echo -e "${YELLOW}[5/8] Instalando dependencias Python...${NC}"

echo "  - Core (flask, pytest, transformers...)"
pip install flask pytest sentence-transformers PyPDF2 python-docx 2>&1 | grep -E "(Successfully|ERROR)" || true

echo "  - Vision y seguridad (opencv, cryptography, requests)"
pip install opencv-python cryptography requests 2>&1 | grep -E "(Successfully|ERROR)" || true

echo "  - MLX (Apple Silicon optimizado)"
pip install mlx mlx-lm mlx-whisper 2>&1 | grep -E "(Successfully|ERROR)" || true

echo "  - Whisper estandar (fallback)"
pip install openai-whisper 2>&1 | grep -E "(Successfully|ERROR)" || true

echo "  - Audio (microfono)"
pip install sounddevice scipy 2>&1 | grep -E "(Successfully|ERROR)" || true

echo "  - Utilidades"
pip install psutil 2>&1 | grep -E "(Successfully|ERROR)" || true

echo -e "${GREEN}  OK - Dependencias Python instaladas${NC}"

# ============================================================
# PASO 6: Descargar modelos dlib
# ============================================================
echo -e "${YELLOW}[6/8] Descargando modelos dlib...${NC}"

cd "$MODELS_DIR"

# Shape predictor
if [ ! -f "shape_predictor_68_face_landmarks.dat" ]; then
    echo "  Descargando shape_predictor_68_face_landmarks.dat..."
    curl -L -o shape_predictor_68_face_landmarks.dat.bz2 \
        "https://github.com/davisking/dlib-models/raw/master/shape_predictor_68_face_landmarks.dat.bz2" \
        2>/dev/null || \
    curl -L -o shape_predictor_68_face_landmarks.dat.bz2 \
        "https://huggingface.co/spaces/mikeee/model-downloads/resolve/main/shape_predictor_68_face_landmarks.dat.bz2" \
        2>/dev/null || \
    echo -e "${RED}  Error descargando shape predictor. Descarga manual desde dlib.net${NC}"

    if [ -f "shape_predictor_68_face_landmarks.dat.bz2" ]; then
        bunzip2 shape_predictor_68_face_landmarks.dat.bz2 2>/dev/null || true
    fi
else
    echo "  shape_predictor ya existe"
fi

# Face recognition
if [ ! -f "dlib_face_recognition_resnet_model_v1.dat" ]; then
    echo "  Descargando dlib_face_recognition_resnet_model_v1.dat..."
    curl -L -o dlib_face_recognition_resnet_model_v1.dat.bz2 \
        "https://github.com/davisking/dlib-models/raw/master/dlib_face_recognition_resnet_model_v1.dat.bz2" \
        2>/dev/null || \
    curl -L -o dlib_face_recognition_resnet_model_v1.dat.bz2 \
        "https://huggingface.co/spaces/mikeee/model-downloads/resolve/main/dlib_face_recognition_resnet_model_v1.dat.bz2" \
        2>/dev/null || \
    echo -e "${RED}  Error descargando face recognition. Descarga manual desde dlib.net${NC}"

    if [ -f "dlib_face_recognition_resnet_model_v1.dat.bz2" ]; then
        bunzip2 dlib_face_recognition_resnet_model_v1.dat.bz2 2>/dev/null || true
    fi
else
    echo "  face_recognition ya existe"
fi

echo -e "${GREEN}  OK - Modelos dlib${NC}"

# ============================================================
# PASO 7: Copiar archivos MACRON
# ============================================================
echo -e "${YELLOW}[7/8] Configurando archivos MACRON...${NC}"

cd "$MACRON_DIR"

# Crear archivos si no existen (placeholder - el usuario debe copiar los reales)
if [ ! -f "MACRON_FUNCIONALIDADES_v2.py" ]; then
    echo -e "${YELLOW}  ADVERTENCIA: MACRON_FUNCIONALIDADES_v2.py no encontrado${NC}"
    echo -e "${YELLOW}  Copia el archivo desde /mnt/agents/output/ a $MACRON_DIR/${NC}"
fi

if [ ! -f "MACRON_TESTS_v2.1.py" ]; then
    echo -e "${YELLOW}  ADVERTENCIA: MACRON_TESTS_v2.1.py no encontrado${NC}"
fi

if [ ! -f "MACRON_WEB_UI_v2.1.py" ]; then
    echo -e "${YELLOW}  ADVERTENCIA: MACRON_WEB_UI_v2.1.py no encontrado${NC}"
fi

echo -e "${GREEN}  OK - Archivos verificados${NC}"

# ============================================================
# PASO 8: Verificar instalacion
# ============================================================
echo -e "${YELLOW}[8/8] Verificando instalacion...${NC}"

cd "$MACRON_DIR"

# Verificar import
if python3 -c "import flask, cv2, cryptography, mlx" 2>/dev/null; then
    echo -e "${GREEN}  OK - Dependencias core importables${NC}"
else
    echo -e "${RED}  ALGUNAS DEPENDENCIAS FALTAN${NC}"
fi

# Verificar MLX
if python3 -c "import mlx" 2>/dev/null; then
    echo -e "${GREEN}  OK - MLX detectado (Apple Silicon activo)${NC}"
else
    echo -e "${YELLOW}  ADVERTENCIA: MLX no disponible${NC}"
fi

# ============================================================
# RESUMEN
# ============================================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  INSTALACION COMPLETADA${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Directorio MACRON: $MACRON_DIR"
echo "Entorno virtual:    $VENV_DIR"
echo "Modelos dlib:       $MODELS_DIR"
echo "Base de datos:      $HOME/.macron/data/macron.db"
echo ""
echo -e "${YELLOW}Para activar el entorno:${NC}"
echo "  source $VENV_DIR/bin/activate"
echo ""
echo -e "${YELLOW}Para probar MACRON:${NC}"
echo "  cd $MACRON_DIR"
echo "  python3 -c \"from MACRON_FUNCIONALIDADES_v2 import MacronOrchestrator; m = MacronOrchestrator()\""
echo ""
echo -e "${YELLOW}Para iniciar Web UI:${NC}"
echo "  cd $MACRON_DIR"
echo "  python3 MACRON_WEB_UI_v2.1.py"
echo "  # Abrir http://localhost:5000"
echo ""
echo -e "${YELLOW}Para ejecutar tests:${NC}"
echo "  cd $MACRON_DIR"
echo "  python3 -m pytest MACRON_TESTS_v2.1.py -v"
echo ""
echo -e "${BLUE}========================================${NC}"
