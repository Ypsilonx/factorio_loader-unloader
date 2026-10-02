"""Geometrie Storage optimizeru (1 jednotka = 1 dlaždice, střed na počátku, šipka k cíli ve směru -Y).

Díly: podvozek, bočnice se šrouby, pochozí deska se šipkami, převodovka s chladicími žebry na straně
zdroje (+Y) a ústí s gumovými pásky na obou čelech.
"""

import math
import random

import bpy

import so_materials as sm


def box(name, size, location, mat, parent, bevel=0.012, rotation=(0.0, 0.0, 0.0)):
    """Kvádr dané velikosti (x, y, z) se zkosenými hranami; rotation ve stupních."""
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    obj.rotation_euler = tuple(math.radians(a) for a in rotation)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        mod = obj.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 3
        mod.limit_method = "ANGLE"
    obj.data.materials.append(mat)
    obj.parent = parent
    return obj


def cylinder(name, radius, depth, location, mat, parent, vertices=16, rotation=(0.0, 0.0, 0.0)):
    """Válec (šroub, víčko); rotation ve stupních."""
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, vertices=vertices, location=location,
                                        rotation=tuple(math.radians(a) for a in rotation))
    obj = bpy.context.active_object
    obj.name = name
    obj.data.materials.append(mat)
    obj.parent = parent
    return obj


def hex_bolt(name, location, mat, parent):
    """Šestihranný šroub s podložkou."""
    x, y, z = location
    return [
        cylinder(name + "_washer", 0.026, 0.005, (x, y, z + 0.0025), mat, parent, vertices=16),
        cylinder(name + "_head", 0.019, 0.013, (x, y, z + 0.011), mat, parent, vertices=6),
    ]


def materials():
    """Vytvoří materiály modelu; vrátí slovník podle role dílu."""
    return {
        "body": sm.weathered_metal("SO_body", (0.12, 0.115, 0.105), rust=0.5, wear=0.8),
        "frame": sm.weathered_metal("SO_frame", (0.11, 0.095, 0.08), rust=0.75, wear=0.9, metallic=0.45),
        "deck": sm.weathered_metal("SO_deck", (0.07, 0.07, 0.072), rust=0.35, wear=1.0, roughness=0.4,
                                   tread_plate=True),
        "housing": sm.chipped_paint("SO_housing", (0.16, 0.13, 0.09)),
        "bolt": sm.weathered_metal("SO_bolt", (0.3, 0.29, 0.27), rust=0.8, wear=1.0, metallic=0.7),
        "rubber": sm.rubber("SO_rubber"),
        "ins_red": sm.chipped_paint("SO_ins_red", (0.5, 0.03, 0.02), chipping=0.7),
        "ins_green": sm.chipped_paint("SO_ins_green", (0.04, 0.38, 0.04), chipping=0.7),
        "void": sm.void("SO_void"),
        "stripe": sm.chipped_paint("SO_stripe", (0.85, 0.85, 0.85), under=(0.06, 0.06, 0.06), rusty=False,
                                   chipping=0.57),
    }


def mouth(prefix, end, m, parent, rng):
    """Ústí na čele (end = -1 jih/cíl, +1 sever/zdroj): tmavý otvor, horní lišta a gumové pásky."""
    face = end * 0.43
    parts = [
        box(prefix + "_void", (0.54, 0.03, 0.12), (0, face, 0.07), m["void"], parent, bevel=0.0),
        box(prefix + "_lip", (0.62, 0.05, 0.035), (0, face + end * 0.01, 0.15), m["frame"], parent, bevel=0.008),
    ]
    for i in range(7):
        x = -0.24 + i * 0.08
        swing = rng.uniform(-9.0, 9.0)
        parts.append(box(f"{prefix}_strip_{i}", (0.07, 0.008, 0.115), (x, face + end * 0.02, 0.075),
                         m["rubber"], parent, bevel=0.002, rotation=(swing, 0.0, rng.uniform(-3.0, 3.0))))
    return parts


def terminal(m, parent):
    """Svorkovnice obvodové sítě na převodovce: krabička a dva izolátory (červený a zelený drát).

    VAZBA NA HRU: vrcholy izolátorů (x 0.175 / 0.245, y 0.32, z 0.385) musí odpovídat TERMINAL
    v Storage_optimizer/prototypes/wires.lua – tam se z nich počítají body, kam hra kreslí dráty.
    """
    parts = [box("SO_TerminalBox", (0.13, 0.11, 0.035), (0.21, 0.32, 0.3275), m["housing"], parent, bevel=0.006)]
    for color, x in (("red", 0.175), ("green", 0.245)):
        parts.append(cylinder(f"SO_Post_{color}", 0.012, 0.03, (x, 0.32, 0.36), m["bolt"], parent, vertices=12))
        parts.append(cylinder(f"SO_Insulator_{color}", 0.019, 0.016, (x, 0.32, 0.377), m["ins_" + color], parent,
                              vertices=16))
    return parts


def build(scene):
    """Postaví model pod pomocný objekt SO_Root; vrátí (root, díly základu, šipky)."""
    rng = random.Random(7)  # pevné semínko → každé přegenerování vypadá stejně
    m = materials()
    stretch = bpy.data.objects.new("SO_Stretch", None)
    # Kamera pod 45° zkracuje hloubku o cos 45°; roztažení Y o √2 vrátí dlaždicím čtvercový tvar jako ve hře.
    stretch.scale = (1.0, math.sqrt(2.0), 1.0)
    scene.collection.objects.link(stretch)
    root = bpy.data.objects.new("SO_Root", None)
    root.parent = stretch
    scene.collection.objects.link(root)

    base = [box("SO_Chassis", (0.8, 0.86, 0.18), (0, 0, 0.09), m["body"], root, bevel=0.025)]
    for side in (-1, 1):
        x = side * 0.39
        base.append(box(f"SO_Rail_{side}", (0.095, 0.92, 0.27), (x, 0, 0.135), m["frame"], root, bevel=0.018))
        for i, y in enumerate((-0.37, -0.12, 0.12, 0.37)):
            base += hex_bolt(f"SO_RailBolt_{side}_{i}", (x, y, 0.27), m["bolt"], root)

    # Pochozí deska se šipkami (strana cíle) a převodovka (strana zdroje).
    base.append(box("SO_Deck", (0.66, 0.6, 0.016), (0, -0.09, 0.186), m["deck"], root, bevel=0.004))
    for i, (x, y) in enumerate(((-0.29, -0.36), (0.29, -0.36), (-0.29, 0.18), (0.29, 0.18))):
        base += hex_bolt(f"SO_DeckBolt_{i}", (x, y, 0.194), m["bolt"], root)
    base.append(box("SO_Housing", (0.62, 0.21, 0.13), (0, 0.32, 0.245), m["housing"], root, bevel=0.022))
    for i in range(5):
        base.append(box(f"SO_Rib_{i}", (0.022, 0.19, 0.03), (-0.24 + i * 0.075, 0.32, 0.322), m["housing"], root,
                        bevel=0.006))
    base += terminal(m, root)
    base.append(cylinder("SO_Cap", 0.045, 0.03, (0.0, 0.215, 0.25), m["bolt"], root, vertices=20,
                         rotation=(90.0, 0.0, 0.0)))

    base += mouth("SO_MouthTarget", -1, m, root, rng)
    base += mouth("SO_MouthSource", 1, m, root, rng)

    chevrons = []
    for i, y in enumerate((0.1, -0.07, -0.24)):
        for side in (-1, 1):
            # Dvě ramena šipky tvoří „V“ s hrotem ve směru -Y (k cíli); pravé rameno je o chlup výš,
            # aby se v místě překryvu nepraly dvě plochy v jedné rovině.
            chevrons.append(box(f"SO_Chevron_{i}_{side}", (0.068, 0.25, 0.014),
                                (side * 0.083, y + 0.02, 0.2 + max(side, 0) * 0.002), m["stripe"], root, bevel=0.004,
                                rotation=(0.0, 0.0, side * -45.0)))
    return root, base, chevrons
