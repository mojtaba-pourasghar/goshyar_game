import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

RES_DRAWABLE = "c:/MyData/Projects/Android/Goshyar/goshyar_game/app/src/main/res/drawable"
ASSETS_MASCOT = "c:/MyData/Projects/Android/Goshyar/goshyar_game/app/src/main/assets/mascot"

os.makedirs(RES_DRAWABLE, exist_ok=True)
os.makedirs(ASSETS_MASCOT, exist_ok=True)

def draw_gooshi_mascot(pose="idle", size=(512, 512)):
    w, h = size
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx, cy = w // 2, h // 2 + 20
    
    bear_orange = (255, 122, 0, 255)
    bear_light = (255, 200, 140, 255)
    hoodie_teal = (13, 148, 136, 255)
    hoodie_light = (20, 184, 166, 255)
    hp_cyan = (6, 182, 212, 255)
    hp_dark = (8, 145, 178, 255)
    hp_cushion = (30, 41, 59, 255)
    
    # Body & Hoodie
    draw.ellipse([cx - 100, cy + 20, cx + 100, cy + 220], fill=hoodie_teal)
    draw.ellipse([cx - 80, cy + 40, cx + 80, cy + 200], fill=hoodie_light)
    for i, sw_h in enumerate([20, 35, 50, 35, 20]):
        x = cx - 30 + i * 15
        draw.line([(x, cy + 110 - sw_h // 2), (x, cy + 110 + sw_h // 2)], fill=(255, 255, 255, 230), width=6)
        
    # Poses
    if pose in ["happy", "celebrating"]:
        draw.polygon([(cx - 80, cy + 60), (cx - 140, cy - 20), (cx - 110, cy - 30), (cx - 60, cy + 40)], fill=hoodie_teal)
        draw.polygon([(cx + 80, cy + 60), (cx + 140, cy - 20), (cx + 110, cy - 30), (cx + 60, cy + 40)], fill=hoodie_teal)
        draw.ellipse([cx - 155, cy - 40, cx - 115, cy], fill=bear_orange)
        draw.ellipse([cx + 115, cy - 40, cx + 155, cy], fill=bear_orange)
    elif pose == "encouraging":
        draw.polygon([(cx + 80, cy + 60), (cx + 140, cy + 30), (cx + 130, cy + 10), (cx + 60, cy + 40)], fill=hoodie_teal)
        draw.ellipse([cx + 125, cy + 5, cx + 155, cy + 35], fill=bear_orange)
    
    # Ears
    draw.ellipse([cx - 120, cy - 140, cx - 50, cy - 70], fill=bear_orange)
    draw.ellipse([cx - 105, cy - 125, cx - 65, cy - 85], fill=bear_light)
    draw.ellipse([cx + 50, cy - 140, cx + 120, cy - 70], fill=bear_orange)
    draw.ellipse([cx + 65, cy - 125, cx + 105, cy - 85], fill=bear_light)
    
    # Head
    draw.ellipse([cx - 110, cy - 120, cx + 110, cy + 60], fill=bear_orange)
    draw.ellipse([cx - 55, cy - 20, cx + 55, cy + 45], fill=bear_light)
    draw.ellipse([cx - 20, cy - 15, cx + 20, cy + 10], fill=(40, 20, 10, 255))
    draw.ellipse([cx - 8, cy - 12, cx + 2, cy - 4], fill=(255, 255, 255, 220))
    
    # Mouth
    if pose in ["happy", "celebrating", "encouraging"]:
        draw.chord([cx - 25, cy, cx + 25, cy + 35], start=0, end=180, fill=(200, 40, 40, 255))
    elif pose == "surprised":
        draw.ellipse([cx - 15, cy + 5, cx + 15, cy + 35], fill=(50, 20, 10, 255))
    else:
        draw.arc([cx - 22, cy - 5, cx + 22, cy + 25], start=20, end=160, fill=(50, 20, 10, 255), width=5)
        
    # Eyes
    if pose in ["listening", "sleeping"]:
        draw.arc([cx - 65, cy - 45, cx - 25, cy - 15], start=180, end=360, fill=(40, 20, 10, 255), width=6)
        draw.arc([cx + 25, cy - 45, cx + 65, cy - 15], start=180, end=360, fill=(40, 20, 10, 255), width=6)
    else:
        draw.ellipse([cx - 65, cy - 65, cx - 25, cy - 15], fill=(30, 20, 10, 255))
        draw.ellipse([cx + 25, cy - 65, cx + 65, cy - 15], fill=(30, 20, 10, 255))
        draw.ellipse([cx - 55, cy - 60, cx - 38, cy - 42], fill=(255, 255, 255, 255))
        draw.ellipse([cx + 35, cy - 60, cx + 52, cy - 42], fill=(255, 255, 255, 255))
        
    # Cheeks
    draw.ellipse([cx - 95, cy - 10, cx - 65, cy + 10], fill=(255, 120, 150, 120))
    draw.ellipse([cx + 65, cy - 10, cx + 95, cy + 10], fill=(255, 120, 150, 120))
    
    # Headphones
    draw.arc([cx - 115, cy - 145, cx + 115, cy - 35], start=190, end=350, fill=hp_cyan, width=22)
    draw.ellipse([cx - 135, cy - 75, cx - 95, cy + 15], fill=hp_dark)
    draw.ellipse([cx - 130, cy - 70, cx - 100, cy + 10], fill=hp_cyan)
    draw.ellipse([cx - 125, cy - 60, cx - 105, cy], fill=hp_cushion)
    
    draw.ellipse([cx + 95, cy - 75, cx + 135, cy + 15], fill=hp_dark)
    draw.ellipse([cx + 100, cy - 70, cx + 130, cy + 10], fill=hp_cyan)
    draw.ellipse([cx + 105, cy - 60, cx + 125, cy], fill=hp_cushion)

    return img

poses = ["idle", "listening", "thinking", "happy", "celebrating", "encouraging", "surprised", "sleeping"]
for p in poses:
    img = draw_gooshi_mascot(pose=p)
    img.save(os.path.join(RES_DRAWABLE, f"mascot_{p}.png"))
    img.save(os.path.join(ASSETS_MASCOT, f"gooshi_{p}.png"))
    print("Saved mascot pose:", p)
