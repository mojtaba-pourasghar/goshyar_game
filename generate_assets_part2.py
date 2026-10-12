import os
import math
from PIL import Image, ImageDraw

RES_DRAWABLE = "c:/MyData/Projects/Android/Goshyar/goshyar_game/app/src/main/res/drawable"
MIPMAP_HDPI = "c:/MyData/Projects/Android/Goshyar/goshyar_game/app/src/main/res/mipmap-hdpi"

os.makedirs(RES_DRAWABLE, exist_ok=True)
os.makedirs(MIPMAP_HDPI, exist_ok=True)

def create_background(bg_type="sunny_forest", size=(800, 1200)):
    w, h = size
    img = Image.new("RGBA", (w, h), (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    if bg_type == "sunny_forest":
        for y in range(h // 2):
            r = int(185 + (220 - 185) * (y / (h // 2)))
            g = int(220 + (245 - 220) * (y / (h // 2)))
            b = 255
            draw.line([(0, y), (w, y)], fill=(r, g, b, 255))
            
        draw.ellipse([w - 180, 80, w - 40, 220], fill=(255, 230, 80, 255))
        for cx, cy, cw, ch in [(100, 120, 220, 80), (450, 180, 260, 90)]:
            draw.ellipse([cx, cy, cx + cw, cy + ch], fill=(255, 255, 255, 230))
            
        draw.ellipse([-100, h // 2 - 100, w // 2 + 100, h // 2 + 300], fill=(120, 200, 110, 255))
        draw.ellipse([w // 3, h // 2 - 80, w + 150, h // 2 + 350], fill=(90, 180, 90, 255))
        draw.ellipse([-150, h // 2 + 100, w + 150, h + 200], fill=(76, 175, 80, 255))

    elif bg_type == "night_forest":
        for y in range(h):
            r = int(15 + (40 - 15) * (y / h))
            g = int(20 + (50 - 20) * (y / h))
            b = int(60 + (90 - 60) * (y / h))
            draw.line([(0, y), (w, y)], fill=(r, g, b, 255))
            
        draw.ellipse([80, 80, 200, 200], fill=(255, 245, 200, 255))
        draw.ellipse([120, 70, 220, 190], fill=(20, 30, 70, 255))
        
        import random
        random.seed(42)
        for _ in range(40):
            sx, sy = random.randint(20, w - 20), random.randint(20, h // 2)
            sr = random.randint(2, 5)
            draw.ellipse([sx, sy, sx + sr, sy + sr], fill=(255, 255, 220, 230))
            
        draw.ellipse([-100, h // 2, w // 2 + 150, h + 200], fill=(25, 45, 75, 255))
        draw.ellipse([w // 4, h // 2 + 50, w + 150, h + 250], fill=(15, 30, 55, 255))

    return img

create_background("sunny_forest").save(os.path.join(RES_DRAWABLE, "bg_sunny_forest.png"))
create_background("night_forest").save(os.path.join(RES_DRAWABLE, "bg_night_forest.png"))

def create_animal_icon(animal_name, size=(256, 256)):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size[0] // 2, size[1] // 2
    
    draw.ellipse([12, 12, size[0] - 12, size[1] - 12], fill=(255, 255, 255, 240), outline=(255, 150, 0, 255), width=8)
    
    if animal_name == "lion":
        draw.ellipse([cx - 75, cy - 75, cx + 75, cy + 75], fill=(230, 120, 20, 255))
        draw.ellipse([cx - 50, cy - 50, cx + 50, cy + 50], fill=(255, 190, 60, 255))
        draw.ellipse([cx - 25, cy - 20, cx - 10, cy - 5], fill=(30, 30, 30, 255))
        draw.ellipse([cx + 10, cy - 20, cx + 25, cy - 5], fill=(30, 30, 30, 255))
    elif animal_name == "cow":
        draw.ellipse([cx - 55, cy - 55, cx + 55, cy + 35], fill=(245, 245, 245, 255))
        draw.ellipse([cx - 45, cy - 5, cx + 45, cy + 45], fill=(255, 180, 190, 255))
        draw.ellipse([cx - 25, cy - 25, cx - 12, cy - 12], fill=(30, 30, 30, 255))
        draw.ellipse([cx + 12, cy - 25, cx + 25, cy - 12], fill=(30, 30, 30, 255))
    elif animal_name == "rabbit":
        draw.ellipse([cx - 35, cy - 100, cx - 10, cy - 20], fill=(240, 240, 240, 255))
        draw.ellipse([cx + 10, cy - 100, cx + 35, cy - 20], fill=(240, 240, 240, 255))
        draw.ellipse([cx - 45, cy - 35, cx + 45, cy + 45], fill=(245, 245, 245, 255))
    elif animal_name == "cat":
        draw.polygon([(cx - 50, cy - 60), (cx - 20, cy - 20), (cx - 50, cy - 10)], fill=(255, 140, 0, 255))
        draw.polygon([(cx + 50, cy - 60), (cx + 20, cy - 20), (cx + 50, cy - 10)], fill=(255, 140, 0, 255))
        draw.ellipse([cx - 45, cy - 35, cx + 45, cy + 45], fill=(255, 160, 20, 255))
    elif animal_name == "dog":
        draw.ellipse([cx - 65, cy - 40, cx - 30, cy + 20], fill=(120, 70, 30, 255))
        draw.ellipse([cx + 30, cy - 40, cx + 65, cy + 20], fill=(120, 70, 30, 255))
        draw.ellipse([cx - 45, cy - 35, cx + 45, cy + 45], fill=(180, 110, 50, 255))
    else: # bird
        draw.ellipse([cx - 40, cy - 30, cx + 30, cy + 35], fill=(60, 160, 240, 255))
        draw.polygon([(cx + 15, cy - 30), (cx + 45, cy - 20), (cx + 15, cy - 10)], fill=(255, 180, 20, 255))

    return img

animals = ["lion", "cow", "rabbit", "cat", "dog", "bird"]
for a in animals:
    create_animal_icon(a).save(os.path.join(RES_DRAWABLE, f"anim_{a}.png"))

def create_gold_star(size=(256, 256)):
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size[0] // 2, size[1] // 2
    pts = []
    for i in range(10):
        r = 100 if i % 2 == 0 else 45
        angle = i * math.pi / 5 - math.pi / 2
        pts.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    draw.polygon(pts, fill=(255, 200, 20, 255), outline=(230, 150, 0, 255), width=6)
    return img

create_gold_star().save(os.path.join(RES_DRAWABLE, "ic_gold_star.png"))

# Create launcher icon
ic_launcher = create_gold_star(size=(72, 72))
ic_launcher.save(os.path.join(MIPMAP_HDPI, "ic_launcher.png"))

print("Generated all images successfully!")
