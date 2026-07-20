import os
from PIL import Image, ImageDraw, ImageFont

# Crear icono 1024x1024
size = 1024
img = Image.new('RGBA', (size, size), (10, 10, 30, 255))
draw = ImageDraw.Draw(img)

# Fondo circular
circle_color = (0, 212, 170, 255)  # #00d4aa
draw.ellipse([50, 50, size-50, size-50], fill=circle_color)

# Texto "M"
try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 500)
except:
    font = ImageFont.load_default()

# Centro del texto
bbox = draw.textbbox((0, 0), "M", font=font)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]
x = (size - text_width) / 2
y = (size - text_height) / 2 - 50

draw.text((x, y), "M", font=font, fill=(10, 10, 30, 255))

# Guardar PNG
img.save('icon_1024x1024.png')
print("OK: icon_1024x1024.png creado")
