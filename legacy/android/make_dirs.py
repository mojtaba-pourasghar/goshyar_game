import os

dirs = [
    "gradle/wrapper",
    "app/src/main/java/ir/brandimo/goshyar/audio",
    "app/src/main/java/ir/brandimo/goshyar/data",
    "app/src/main/java/ir/brandimo/goshyar/ui/splash",
    "app/src/main/java/ir/brandimo/goshyar/ui/intro",
    "app/src/main/java/ir/brandimo/goshyar/ui/menu",
    "app/src/main/java/ir/brandimo/goshyar/ui/categories",
    "app/src/main/java/ir/brandimo/goshyar/ui/games",
    "app/src/main/java/ir/brandimo/goshyar/ui/dialogs",
    "app/src/main/java/ir/brandimo/goshyar/ui/profile",
    "app/src/main/java/ir/brandimo/goshyar/ui/achievements",
    "app/src/main/java/ir/brandimo/goshyar/ui/settings",
    "app/src/main/java/ir/brandimo/goshyar/ui/offline",
    "app/src/main/java/ir/brandimo/goshyar/ui/parent",
    "app/src/main/java/ir/brandimo/goshyar/ui/views",
    "app/src/main/res/drawable",
    "app/src/main/res/layout",
    "app/src/main/res/values",
    "app/src/main/res/mipmap-hdpi",
    "app/src/main/assets/sounds",
    "app/src/main/assets/mascot"
]

base = "c:/MyData/Projects/Android/Goshyar/goshyar_game"
for d in dirs:
    path = os.path.join(base, d)
    os.makedirs(path, exist_ok=True)
    print("Created:", path)
