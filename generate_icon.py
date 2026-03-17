#!/usr/bin/env python3
"""Generate a 1024x1024 app icon for Contrail."""

from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math

SIZE = 1024
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# === Background: deep navy gradient ===
for y in range(SIZE):
    t = y / SIZE
    # Dark navy at top → slightly lighter deep blue at bottom
    r = int(8 + 12 * t)
    g = int(18 + 22 * t)
    b = int(40 + 50 * t)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b, 255))

# === Subtle radial glow in center-upper area ===
glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
glow_draw = ImageDraw.Draw(glow)
cx, cy = SIZE // 2, SIZE // 2 - 60
max_r = 380
for radius in range(max_r, 0, -1):
    t = 1 - (radius / max_r)
    alpha = int(30 * t * t)
    glow_draw.ellipse(
        [cx - radius, cy - radius, cx + radius, cy + radius],
        fill=(0, 180, 216, alpha)
    )
glow = glow.filter(ImageFilter.GaussianBlur(radius=40))
img = Image.alpha_composite(img, glow)
draw = ImageDraw.Draw(img)

# === Radar arcs (subtle) ===
arc_center_x = SIZE // 2
arc_center_y = SIZE + 200  # arcs emanate from below
for i, r in enumerate([500, 650, 800, 950]):
    alpha = int(20 - i * 4)
    arc_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    arc_draw = ImageDraw.Draw(arc_layer)
    arc_draw.arc(
        [arc_center_x - r, arc_center_y - r, arc_center_x + r, arc_center_y + r],
        200, 340,
        fill=(0, 180, 216, alpha),
        width=2
    )
    img = Image.alpha_composite(img, arc_layer)
draw = ImageDraw.Draw(img)

# === Aircraft silhouette (stylized, viewed from above) ===
ac_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
ac_draw = ImageDraw.Draw(ac_layer)

# Aircraft position
ax, ay = SIZE // 2 + 30, SIZE // 2 - 60

# Fuselage
fuselage_pts = [
    (ax, ay - 100),      # nose
    (ax + 14, ay - 60),
    (ax + 14, ay + 100),
    (ax + 8, ay + 130),  # tail
    (ax - 8, ay + 130),
    (ax - 14, ay + 100),
    (ax - 14, ay - 60),
]
ac_draw.polygon(fuselage_pts, fill=(220, 235, 250, 255))

# Wings (swept back)
wing_pts_r = [
    (ax + 14, ay - 10),
    (ax + 140, ay + 50),
    (ax + 145, ay + 58),
    (ax + 14, ay + 30),
]
wing_pts_l = [
    (ax - 14, ay - 10),
    (ax - 140, ay + 50),
    (ax - 145, ay + 58),
    (ax - 14, ay + 30),
]
ac_draw.polygon(wing_pts_r, fill=(200, 218, 240, 255))
ac_draw.polygon(wing_pts_l, fill=(200, 218, 240, 255))

# Tail fin (horizontal stabilizer)
tail_r = [
    (ax + 8, ay + 100),
    (ax + 55, ay + 120),
    (ax + 55, ay + 126),
    (ax + 8, ay + 115),
]
tail_l = [
    (ax - 8, ay + 100),
    (ax - 55, ay + 120),
    (ax - 55, ay + 126),
    (ax - 8, ay + 115),
]
ac_draw.polygon(tail_r, fill=(180, 200, 225, 255))
ac_draw.polygon(tail_l, fill=(180, 200, 225, 255))

img = Image.alpha_composite(img, ac_layer)
draw = ImageDraw.Draw(img)

# === Contrails (the signature element) ===
contrail_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
contrail_draw = ImageDraw.Draw(contrail_layer)

# Two contrails from the engines
engine_offsets = [-45, 45]
for offset in engine_offsets:
    ex = ax + offset
    ey = ay + 60

    # Draw contrail as series of circles getting wider and more transparent
    trail_length = 500
    for i in range(trail_length):
        t = i / trail_length
        # Trail goes down-left (suggesting aircraft moving up-right)
        tx = ex - t * 180
        ty = ey + i * 1.1

        if ty > SIZE + 20:
            break

        # Width increases, alpha decreases
        width = 3 + t * 28
        # Cyan to white, fading out
        alpha = int(140 * (1 - t) ** 1.5)
        r_c = int(180 + 75 * t)
        g_c = int(220 + 35 * t)
        b_c = int(240 + 15 * t)

        contrail_draw.ellipse(
            [tx - width / 2, ty - width / 4, tx + width / 2, ty + width / 4],
            fill=(r_c, g_c, b_c, alpha)
        )

contrail_layer = contrail_layer.filter(ImageFilter.GaussianBlur(radius=6))
img = Image.alpha_composite(img, contrail_layer)
draw = ImageDraw.Draw(img)

# === Engineering data elements (subtle floating data) ===
data_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
data_draw = ImageDraw.Draw(data_layer)

# Small data readouts scattered around the aircraft
data_points = [
    (ax + 180, ay - 30, "M 0.82"),
    (ax - 200, ay + 20, "FL350"),
    (ax + 160, ay + 90, "q 12.4"),
]

try:
    font = ImageFont.truetype("/System/Library/Fonts/SFNSMono.ttf", 22)
except:
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Menlo.ttc", 22)
    except:
        font = ImageFont.load_default()

for dx, dy, text in data_points:
    # Small cyan text
    data_draw.text((dx, dy), text, fill=(0, 180, 216, 90), font=font)

data_layer = data_layer.filter(ImageFilter.GaussianBlur(radius=1))
img = Image.alpha_composite(img, data_layer)

# === Rounded corners (iOS app icon mask) ===
# iOS applies its own mask, but we create with clean edges
final = img.convert("RGB")

# Save
output_path = "/Users/lielmachluf/Documents/SkyRadar/SkyRadar/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
final.save(output_path, "PNG", quality=100)
print(f"Icon saved to {output_path}")
print(f"Size: {final.size}")
