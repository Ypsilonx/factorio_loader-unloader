"""Procedurální model Storage optimizeru a render všech spritů pro Factorio.

Spuštění: v Blenderu (Scripting → Run Script) nebo přes MCP:
    exec(open(r"<repo>/blender/build_sprites.py", encoding="utf-8").read())

Výstupy (do složky modu):
    graphics/entity/storage-optimizer-{base,mask,shadow}.png   4 směry vedle sebe (N, E, S, W), 128×128 px/směr
    graphics/icons/storage-optimizer-{base,mask}.png           ikona 64×64
    thumbnail.png                                              náhled pro mod portál 144×144
Vrstva *mask* obsahuje jen šipky (chevrony) ve stupních šedi – hra je obarví podle tieru (tint).
"""

import math
import os

import bpy
import numpy as np

# Kořen repozitáře; při jiném umístění nastav proměnnou prostředí SO_ROOT.
ROOT = os.environ.get("SO_ROOT", r"D:/61_Programing/factorio_loader-unloader")
MOD = os.path.join(ROOT, "Storage_optimizer")
WORK = os.path.join(ROOT, "blender", "renders")

SCENE_NAME = "StorageOptimizer"
FRAME_PX = 128          # 2 dlaždice na snímek, ve hře scale 0.5 → 64 px na dlaždici
ICON_PX = 64
THUMB_PX = 144
SAMPLES = 48

# Natočení modelu pro směry entity (N, E, S, W). Model má šipku k cíli ve směru -Y (dolů na obrazovce),
# což odpovídá směru „sever“ (zdroj na severu, cíl na jihu).
DIRECTIONS = [("north", 0.0), ("east", -90.0), ("south", 180.0), ("west", 90.0)]

# Barvy materiálů (lineární RGB) – laditelné hodnoty vzhledu.
COLORS = {
    "steel_dark": (0.11, 0.105, 0.1),
    "steel_mid": (0.2, 0.15, 0.11),
    "rivet": (0.45, 0.42, 0.38),
    "plate": (0.06, 0.06, 0.062),
    "slot": (0.005, 0.005, 0.005),
    "stripe": (0.9, 0.9, 0.9),
    "thumb_stripe": (0.9, 0.6, 0.05),
}

# Barvy tierů pro náhled – stejné jako TINTS v Storage_optimizer/prototypes/entity.lua (sRGB 0–1).
PREVIEW_TINTS = [(1.0, 0.85, 0.25), (1.0, 0.35, 0.3), (0.35, 0.65, 1.0), (0.55, 1.0, 0.45)]


def material(name, color, roughness=0.6, metallic=0.3):
    """Vrátí (případně vytvoří) Principled materiál s danou barvou."""
    mat = bpy.data.materials.get("SO_" + name) or bpy.data.materials.new("SO_" + name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return mat


def box(name, size, location, mat, parent, bevel=0.012, rotation_z=0.0):
    """Vytvoří kvádr dané velikosti (x, y, z) s mírně zkosenými hranami."""
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    obj.rotation_euler[2] = math.radians(rotation_z)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        mod = obj.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    obj.data.materials.append(mat)
    obj.parent = parent
    return obj


def rivet(name, location, mat, parent):
    """Vytvoří malý nýt (nízký válec)."""
    bpy.ops.mesh.primitive_cylinder_add(radius=0.018, depth=0.012, vertices=12, location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.data.materials.append(mat)
    obj.parent = parent
    return obj


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


def build_model(scene):
    """Postaví model; vrátí (root pro otáčení, části základu, chevrony, podložka pro stín)."""
    stretch = bpy.data.objects.new("SO_Stretch", None)
    # Kamera pod 45° zkracuje hloubku o cos 45°; roztažení Y o √2 vrátí dlaždicím čtvercový tvar jako ve hře.
    stretch.scale = (1.0, math.sqrt(2.0), 1.0)
    scene.collection.objects.link(stretch)
    root = bpy.data.objects.new("SO_Root", None)
    root.parent = stretch
    scene.collection.objects.link(root)

    m = {key: material(key, value) for key, value in COLORS.items()}
    m["slot"].node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 1.0
    m["stripe"].node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = 0.1

    base = []
    base.append(box("SO_Block", (0.84, 0.84, 0.2), (0, 0, 0.1), m["steel_dark"], root, bevel=0.03))
    for side in (-1, 1):
        x = side * 0.385
        base.append(box(f"SO_Rail_{side}", (0.085, 0.9, 0.29), (x, 0, 0.145), m["steel_mid"], root, bevel=0.02))
        for i, y in enumerate((-0.36, 0.0, 0.36)):
            base.append(rivet(f"SO_RailRivet_{side}_{i}", (x, y, 0.293), m["rivet"], root))
    base.append(box("SO_Plate", (0.64, 0.8, 0.02), (0, 0, 0.205), m["plate"], root, bevel=0.004))
    for end in (-1, 1):
        y = end * 0.425
        base.append(box(f"SO_Slot_{end}", (0.56, 0.02, 0.12), (0, y, 0.1), m["slot"], root, bevel=0.0))
        for side in (-1, 1):
            base.append(rivet(f"SO_PlateRivet_{end}_{side}", (side * 0.29, end * 0.37, 0.218), m["rivet"], root))

    chevrons = []
    for i, y in enumerate((0.2, 0.0, -0.2)):
        for side in (-1, 1):
            # Dvě ramena šipky tvoří „V“ s hrotem ve směru -Y (k cíli).
            chevrons.append(box(
                f"SO_Chevron_{i}_{side}", (0.07, 0.26, 0.015),
                (side * 0.085, y + 0.02, 0.222), m["stripe"], root, bevel=0.004, rotation_z=side * -45.0,
            ))

    bpy.ops.mesh.primitive_plane_add(size=6.0, location=(0, 0, 0))
    ground = bpy.context.active_object
    ground.name = "SO_Ground"
    ground.is_shadow_catcher = True
    return root, base, chevrons, ground


def setup_render(scene, px):
    """Nastaví Cycles, průhledné pozadí a standardní převod barev (bez filmového tónování)."""
    scene.render.engine = "CYCLES"
    scene.cycles.samples = SAMPLES
    scene.cycles.use_denoising = True
    scene.render.film_transparent = True
    scene.render.resolution_x = px
    scene.render.resolution_y = px
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    world = bpy.data.worlds.get("SO_World") or bpy.data.worlds.new("SO_World")
    world.use_nodes = True
    nodes = world.node_tree.nodes
    # Blender 5 zakládá nový svět bez uzlů – pozadí a výstup případně doplníme.
    background = next((n for n in nodes if n.type == "BACKGROUND"), None) or nodes.new("ShaderNodeBackground")
    output = next((n for n in nodes if n.type == "OUTPUT_WORLD"), None) or nodes.new("ShaderNodeOutputWorld")
    if not output.inputs["Surface"].is_linked:
        world.node_tree.links.new(background.outputs["Background"], output.inputs["Surface"])
    background.inputs["Color"].default_value = (0.35, 0.35, 0.37, 1.0)
    background.inputs["Strength"].default_value = 0.6
    scene.world = world


def setup_camera_and_light(scene, ortho_scale):
    """Ortografická kamera pod 45° (jako ve Factoriu) a slunce svítící zleva shora (stín doprava)."""
    cam_data = bpy.data.cameras.new("SO_Camera")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = ortho_scale
    camera = bpy.data.objects.new("SO_Camera", cam_data)
    camera.location = (0.0, -10.0, 10.0)
    camera.rotation_euler = (math.radians(45.0), 0.0, 0.0)
    scene.collection.objects.link(camera)
    scene.camera = camera

    sun_data = bpy.data.lights.new("SO_Sun", "SUN")
    sun_data.energy = 5.0
    sun_data.angle = math.radians(3.0)
    sun = bpy.data.objects.new("SO_Sun", sun_data)
    sun.rotation_euler = (math.radians(-12.0), math.radians(-48.0), 0.0)
    scene.collection.objects.link(sun)
    return camera


def render_pass(scene, path, mode, base, chevrons, ground):
    """Vyrenderuje jednu vrstvu: 'base' (bez šipek), 'mask' (jen šipky), 'shadow' (jen stín), 'full'."""
    for obj in base:
        obj.hide_render = False
        obj.is_holdout = mode == "mask"
        obj.visible_camera = mode != "shadow"
    for obj in chevrons:
        obj.hide_render = mode == "base"
        obj.is_holdout = False
        obj.visible_camera = mode != "shadow"
    ground.hide_render = mode not in ("shadow", "full")
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def load_pixels(path):
    """Načte PNG jako numpy pole (výška, šířka, 4) s řádky shora dolů."""
    img = bpy.data.images.load(path, check_existing=False)
    w, h = img.size
    pixels = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    bpy.data.images.remove(img)
    return pixels


def save_pixels(pixels, path):
    """Uloží numpy pole (výška, šířka, 4; řádky shora dolů) jako PNG."""
    h, w = pixels.shape[:2]
    img = bpy.data.images.new("SO_tmp", width=w, height=h, alpha=True)
    img.pixels[:] = pixels[::-1].reshape(-1)
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)


def shadow_only(pixels):
    """Ze stínového renderu ponechá jen alfu (černý stín, jak ho Factorio kreslí přes draw_as_shadow)."""
    out = np.zeros_like(pixels)
    out[..., 3] = pixels[..., 3]
    return out


def render_entity(scene, root, base, chevrons, ground):
    """Vyrenderuje 4 směry × 3 vrstvy a složí je do pásů N, E, S, W."""
    sheets = {"base": [], "mask": [], "shadow": []}
    for direction, angle in DIRECTIONS:
        root.rotation_euler[2] = math.radians(angle)
        for mode in sheets:
            path = os.path.join(WORK, f"entity-{direction}-{mode}.png")
            render_pass(scene, path, mode, base, chevrons, ground)
            frame = load_pixels(path)
            sheets[mode].append(shadow_only(frame) if mode == "shadow" else frame)
    out_dir = os.path.join(MOD, "graphics", "entity")
    os.makedirs(out_dir, exist_ok=True)
    for mode, frames in sheets.items():
        save_pixels(np.concatenate(frames, axis=1), os.path.join(out_dir, f"storage-optimizer-{mode}.png"))


def render_icons(scene, root, base, chevrons, ground):
    """Ikona 64×64: šipka doprava, vrstvy base a mask."""
    root.rotation_euler[2] = math.radians(90.0)
    out_dir = os.path.join(MOD, "graphics", "icons")
    os.makedirs(out_dir, exist_ok=True)
    for mode in ("base", "mask"):
        render_pass(scene, os.path.join(out_dir, f"storage-optimizer-{mode}.png"), mode, base, chevrons, ground)


def render_thumbnail(scene, root, base, chevrons, ground):
    """Náhled 144×144 se žlutými šipkami na tmavém pozadí."""
    stripe = bpy.data.materials["SO_stripe"].node_tree.nodes["Principled BSDF"].inputs["Base Color"]
    original = tuple(stripe.default_value)
    stripe.default_value = (*COLORS["thumb_stripe"], 1.0)
    root.rotation_euler[2] = math.radians(90.0)
    path = os.path.join(WORK, "thumbnail-full.png")
    render_pass(scene, path, "full", base, chevrons, ground)
    stripe.default_value = original
    fg = load_pixels(path)
    bg = np.zeros_like(fg)
    bg[..., :3] = (0.025, 0.027, 0.03)
    bg[..., 3] = 1.0
    alpha = fg[..., 3:4]
    out = bg.copy()
    out[..., :3] = fg[..., :3] * alpha + bg[..., :3] * (1.0 - alpha)
    save_pixels(out, os.path.join(MOD, "thumbnail.png"))


def srgb_to_linear(c):
    """Převod sRGB (0–1) na lineární hodnoty pro skládání vrstev."""
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(c):
    """Převod lineárních hodnot zpět na sRGB (0–1)."""
    c = np.clip(c, 0.0, 1.0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def over(dst, src):
    """Složí vrstvu src přes dst (obě sRGB RGBA, alfa nepremultiplikovaná) jako ve hře."""
    a = src[..., 3:4]
    out = dst.copy()
    out[..., :3] = src[..., :3] * a + dst[..., :3] * (1.0 - a)
    out[..., 3:4] = a + dst[..., 3:4] * (1.0 - a)
    return out


def render_preview():
    """Náhled jako ve hře: řada směrů × tiery na terénu – základ, obarvená maska a stín (jen pro kontrolu)."""
    entity_dir = os.path.join(MOD, "graphics", "entity")
    base = load_pixels(os.path.join(entity_dir, "storage-optimizer-base.png"))
    mask = load_pixels(os.path.join(entity_dir, "storage-optimizer-mask.png"))
    shadow = load_pixels(os.path.join(entity_dir, "storage-optimizer-shadow.png"))
    rows = []
    for tint in PREVIEW_TINTS:
        ground = np.zeros_like(base)
        ground[..., :3] = (0.33, 0.27, 0.18)  # přibližná barva písčitého terénu Nauvis
        ground[..., 3] = 1.0
        shade = shadow.copy()
        shade[..., 3] *= 0.5  # Factorio kreslí stíny poloprůhledně
        tinted = mask.copy()
        tinted[..., :3] = linear_to_srgb(srgb_to_linear(mask[..., :3]) * srgb_to_linear(np.array(tint)))
        rows.append(over(over(over(ground, shade), base), tinted))
    save_pixels(np.concatenate(rows, axis=0), os.path.join(WORK, "preview.png"))


def main():
    """Postaví scénu, vyrenderuje všechny vrstvy a uloží kopii .blend souboru do repozitáře."""
    os.makedirs(WORK, exist_ok=True)
    scene = reset_scene()
    root, base, chevrons, ground = build_model(scene)
    setup_render(scene, FRAME_PX)
    camera = setup_camera_and_light(scene, ortho_scale=2.0)
    render_entity(scene, root, base, chevrons, ground)
    render_preview()

    setup_render(scene, ICON_PX)
    camera.data.ortho_scale = 1.2
    render_icons(scene, root, base, chevrons, ground)

    setup_render(scene, THUMB_PX)
    camera.data.ortho_scale = 1.3
    render_thumbnail(scene, root, base, chevrons, ground)

    camera.data.ortho_scale = 2.0
    root.rotation_euler[2] = 0.0
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(ROOT, "blender", "storage_optimizer.blend"), copy=True)


main()
