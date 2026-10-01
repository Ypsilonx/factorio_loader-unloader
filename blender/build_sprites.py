"""Procedurální model Storage optimizeru a render všech spritů pro Factorio.

Spuštění: v Blenderu (Scripting → Run Script) nebo přes MCP:
    exec(open(r"<repo>/blender/build_sprites.py", encoding="utf-8").read())

Moduly: so_materials.py (materiály s patinou), so_model.py (geometrie), so_render.py (kamera, render, pixely).

Výstupy (do složky modu):
    graphics/entity/storage-optimizer-{base,mask,shadow}.png   4 směry vedle sebe (N, E, S, W), 128×128 px/směr
    graphics/icons/storage-optimizer-{base,mask}.png           ikona 64×64
    thumbnail.png                                              náhled pro mod portál 144×144
Vrstva *mask* obsahuje jen šipky (chevrony) ve stupních šedi – hra je obarví podle tieru (tint).
"""

import importlib
import math
import os
import sys

import bpy
import numpy as np

# Kořen repozitáře; při jiném umístění nastav proměnnou prostředí SO_ROOT.
ROOT = os.environ.get("SO_ROOT", r"D:/61_Programing/factorio_loader-unloader")
HERE = os.path.join(ROOT, "blender")
MOD = os.path.join(ROOT, "Storage_optimizer")
WORK = os.path.join(HERE, "renders")
if HERE not in sys.path:
    sys.path.insert(0, HERE)

import so_materials  # noqa: E402
import so_model  # noqa: E402
import so_render  # noqa: E402

# Při opakovaném spuštění v běžícím Blenderu načíst aktuální verze modulů.
for _module in (so_materials, so_model, so_render):
    importlib.reload(_module)
R = so_render

SCENE_NAME = "StorageOptimizer"
FRAME_PX = 128          # 2 dlaždice na snímek, ve hře scale 0.5 → 64 px na dlaždici
ICON_PX = 64
THUMB_PX = 144

# Natočení modelu pro směry entity (N, E, S, W). Model má šipku k cíli ve směru -Y (dolů na obrazovce),
# což odpovídá směru „sever“ (zdroj na severu, cíl na jihu).
DIRECTIONS = [("north", 0.0), ("east", -90.0), ("south", 180.0), ("west", 90.0)]

# Barvy tierů pro náhled – stejné jako TINTS v Storage_optimizer/prototypes/entity.lua (sRGB 0–1).
PREVIEW_TINTS = [(1.0, 0.85, 0.25), (1.0, 0.35, 0.3), (0.35, 0.65, 1.0), (0.55, 1.0, 0.45)]
THUMB_TINT = (1.0, 0.75, 0.2)


def reset_scene():
    """Připraví samostatnou scénu (nezasahuje do ostatních scén otevřeného souboru)."""
    scene = bpy.data.scenes.get(SCENE_NAME)
    if scene:
        for obj in list(scene.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
    else:
        scene = bpy.data.scenes.new(SCENE_NAME)
    bpy.context.window.scene = scene
    return scene


def render_layer(scene, name, mode, parts):
    """Vyrenderuje jednu vrstvu do pracovní složky a vrátí ji zmenšenou na cílové rozlišení."""
    path = os.path.join(WORK, name + ".png")
    R.render_pass(scene, path, mode, *parts)
    pixels = R.downsample(R.load_pixels(path))
    return R.shadow_only(pixels) if mode == "shadow" else pixels


def render_entity(scene, root, parts):
    """4 směry × 3 vrstvy složené do pásů N, E, S, W."""
    sheets = {"base": [], "mask": [], "shadow": []}
    for direction, angle in DIRECTIONS:
        root.rotation_euler[2] = math.radians(angle)
        for mode in sheets:
            sheets[mode].append(render_layer(scene, f"entity-{direction}-{mode}", mode, parts))
    out_dir = os.path.join(MOD, "graphics", "entity")
    os.makedirs(out_dir, exist_ok=True)
    for mode, frames in sheets.items():
        R.save_pixels(np.concatenate(frames, axis=1), os.path.join(out_dir, f"storage-optimizer-{mode}.png"))
    return {mode: np.concatenate(frames, axis=1) for mode, frames in sheets.items()}


def render_preview(sheets):
    """Kontrolní náhled jako ve hře: řádek na tier, na terénu, s polovičním stínem (není součástí modu)."""
    rows = []
    for color in PREVIEW_TINTS:
        ground = np.zeros_like(sheets["base"])
        ground[..., :3] = (0.33, 0.27, 0.18)  # přibližná barva písčitého terénu Nauvis
        ground[..., 3] = 1.0
        shade = sheets["shadow"].copy()
        shade[..., 3] *= 0.5
        rows.append(R.over(R.over(R.over(ground, shade), sheets["base"]), R.tint(sheets["mask"], color)))
    R.save_pixels(np.concatenate(rows, axis=0), os.path.join(WORK, "preview.png"))


def render_icons(scene, root, parts):
    """Ikona 64×64: šipka doprava, vrstvy base a mask."""
    root.rotation_euler[2] = math.radians(90.0)
    out_dir = os.path.join(MOD, "graphics", "icons")
    os.makedirs(out_dir, exist_ok=True)
    for mode in ("base", "mask"):
        R.save_pixels(render_layer(scene, "icon-" + mode, mode, parts),
                      os.path.join(out_dir, f"storage-optimizer-{mode}.png"))


def render_thumbnail(scene, root, parts):
    """Náhled 144×144: obarvené šipky a stín na tmavém pozadí."""
    root.rotation_euler[2] = math.radians(90.0)
    base = render_layer(scene, "thumb-base", "base", parts)
    mask = render_layer(scene, "thumb-mask", "mask", parts)
    shadow = render_layer(scene, "thumb-shadow", "shadow", parts)
    bg = np.zeros_like(base)
    bg[..., :3] = (0.11, 0.1, 0.09)
    bg[..., 3] = 1.0
    shadow[..., 3] *= 0.6
    R.save_pixels(R.over(R.over(R.over(bg, shadow), base), R.tint(mask, THUMB_TINT)),
                  os.path.join(MOD, "thumbnail.png"))


def main():
    """Postaví scénu, vyrenderuje všechny vrstvy a uloží kopii .blend souboru do repozitáře."""
    os.makedirs(WORK, exist_ok=True)
    scene = reset_scene()
    root, base, chevrons = so_model.build(scene)
    ground = R.add_ground(scene)
    parts = (base, chevrons, ground)

    R.setup_render(scene, FRAME_PX)
    camera = R.setup_camera_and_lights(scene, ortho_scale=2.0)
    render_preview(render_entity(scene, root, parts))

    R.setup_render(scene, ICON_PX)
    camera.data.ortho_scale = 1.15
    render_icons(scene, root, parts)

    R.setup_render(scene, THUMB_PX)
    camera.data.ortho_scale = 1.25
    render_thumbnail(scene, root, parts)

    camera.data.ortho_scale = 2.0
    root.rotation_euler[2] = 0.0
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "storage_optimizer.blend"), copy=True)


main()
