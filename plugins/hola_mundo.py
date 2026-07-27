# NAME: Hola Mundo
# DESC: Plugin de ejemplo que saluda
import sys
nombre = sys.argv[1] if len(sys.argv) > 1 else "Mundo"
print(f"Hola, {nombre}! Desde el plugin de MACRON.")
