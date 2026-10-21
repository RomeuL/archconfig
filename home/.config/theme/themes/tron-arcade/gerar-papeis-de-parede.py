"""Papel de parede em pixel art para o tema Tron Arcade: céu com estrelas, sol listrado,
montanhas em wireframe e a grade neon em perspectiva. Desenha em 640x360 e amplia 4x
(2560x1440) sem suavizar, com dithering de Bayer nos degradês e scanlines de CRT.

Uso: python3 gerar-papeis-de-parede.py backgrounds/   (as variações estão em VARIANTS)"""
import math
import random
import struct
import sys
import zlib

W, H, SCALE = 640, 360, 4
HORIZON = 205
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def hexrgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def gradient(stops, t, x, y):
    """Degradê com poucas cores: escolhe entre duas cores vizinhas pelo padrão de Bayer."""
    t = min(max(t, 0.0), 1.0) * (len(stops) - 1)
    i = min(int(t), len(stops) - 2)
    frac = t - i
    return stops[i + 1] if frac > (BAYER[y % 4][x % 4] + 0.5) / 16 else stops[i]


def render(p):
    rnd = random.Random(p["seed"])
    sky = [hexrgb(c) for c in p["sky"]]
    floor = [hexrgb(c) for c in p["floor"]]
    sun = [hexrgb(c) for c in p["sun"]]
    grid, grid_dim = hexrgb(p["grid"]), hexrgb(p["grid_dim"])
    ridge, ridge_fill = hexrgb(p["ridge"]), hexrgb(p["ridge_fill"])
    img = [[(0, 0, 0)] * W for _ in range(H)]

    # Céu e chão
    for y in range(H):
        for x in range(W):
            if y < HORIZON:
                img[y][x] = gradient(sky, y / HORIZON, x, y)
            else:
                img[y][x] = gradient(floor, (y - HORIZON) / (H - HORIZON), x, y)

    # Estrelas (algumas em cruz, maiores)
    for _ in range(p["stars"]):
        x, y = rnd.randrange(W), rnd.randrange(int(HORIZON * 0.75))
        color = hexrgb(rnd.choice(p["star_colors"]))
        img[y][x] = color
        if rnd.random() < 0.08 and 1 <= x < W - 1 and 1 <= y < HORIZON - 1:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                img[y + dy][x + dx] = color

    # Sol: metade de cima de um círculo, com faixas que engrossam perto do horizonte
    cx, cy, r = W // 2, HORIZON - 6, p["sun_radius"]
    for y in range(cy - r, HORIZON):
        rel = (y - (cy - r)) / r  # 0 no topo, ~1 no horizonte
        if rel > 0.45:
            band = int((rel - 0.45) * 26)
            if (y - (cy - r)) % 8 < band * 0.6 + 1:
                continue
        half = math.sqrt(max(0, r * r - (y - cy) ** 2))
        for x in range(int(cx - half), int(cx + half) + 1):
            img[y][x] = gradient(sun, rel, x, y)

    # Montanhas: duas cordilheiras em wireframe, com a crista acesa
    for layer, (height, freq, offset) in enumerate(((46, 0.031, 1.7), (30, 0.053, 4.2))):
        top = []
        for x in range(W):
            h = height * (0.55 + 0.25 * math.sin(x * freq + offset) + 0.2 * math.sin(x * freq * 2.7 + offset * 3))
            if abs(x - cx) < r * 0.9:  # vale no meio, deixa o sol aparecer
                h *= 0.25 + 0.75 * (abs(x - cx) / (r * 0.9)) ** 2
            top.append(HORIZON - int(h) // 2 * 2)  # degraus de 2 px: cara de pixel art
        for x in range(W):
            for y in range(top[x], HORIZON):
                img[y][x] = ridge_fill
            img[top[x]][x] = ridge
            if x and top[x] != top[x - 1]:  # degrau vertical também aceso
                for y in range(min(top[x], top[x - 1]), max(top[x], top[x - 1])):
                    img[y][x] = ridge

    # Grade: perto do horizonte (longe) fica apagada, para não virar um borrão de linhas
    far = 26
    def line_color(y):
        return grid_dim if y - HORIZON < far else grid

    # Linhas horizontais cada vez mais espaçadas (pula as que ficariam coladas)
    d, last = 3.0, HORIZON
    while HORIZON + d < H:
        y = HORIZON + int(d)
        if y - last >= 3:
            for x in range(W):
                img[y][x] = line_color(y)
            last = y
        d *= 1.3
    # Linhas que fogem para o centro: liga os pixels de uma linha da imagem para a outra,
    # senão as linhas quase deitadas viram pontilhado
    # Só o leque que chega embaixo (as de fora da tela ficam deitadas e viram uma faixa
    # sólida); perto do horizonte, onde ficam a menos de 4 px, desenha uma a cada 2 ou 4
    step, count = 48, int(1.5 * W / 48)
    for i in range(-count, count + 1):
        xb = cx + i * step
        prev = None
        for y in range(HORIZON + 1, H):
            t = (y - HORIZON) / (H - HORIZON)
            x = round(cx + (xb - cx) * t)
            spacing = step * t
            skip = 1 if spacing >= 4 else 2 if spacing >= 2 else 4
            if i % skip == 0:
                run = range(min(prev, x), max(prev, x) + 1) if prev is not None else (x,)
                for xx in run:
                    if 0 <= xx < W:
                        img[y][xx] = line_color(y)
            prev = x
    for x in range(W):  # linha do horizonte
        img[HORIZON][x] = hexrgb(p["horizon"])
    return img


def write_png(img, path):
    rows = []
    for y, row in enumerate(img):
        line = b"".join(bytes(px) * SCALE for px in row)
        dark = bytes(int(v * 0.82) for v in line)  # scanline de CRT na última linha de cada pixel
        rows += [b"\x00" + line] * (SCALE - 1) + [b"\x00" + dark]
    raw = zlib.compress(b"".join(rows), 9)
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W * SCALE, H * SCALE, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", raw) + chunk(b"IEND", b""))


VARIANTS = {
    "1-grade-por-do-sol.png": dict(
        seed=7, stars=160, star_colors=["#ffffff", "#7df2ff", "#ffd23f"],
        sky=["#03040a", "#0a0820", "#1c0b3d", "#3d0f55", "#6a1460"],
        floor=["#0a0418", "#05060f", "#020306"],
        sun=["#ffe14d", "#ffb23f", "#ff7a1a", "#ff2e88"], sun_radius=78,
        grid="#00e5ff", grid_dim="#06506a", ridge="#00e5ff", ridge_fill="#0a0616", horizon="#ff2e88"),
    "2-grade-noite.png": dict(
        seed=21, stars=260, star_colors=["#ffffff", "#7df2ff", "#c8f8ff"],
        sky=["#010205", "#030712", "#06122a", "#0a2240", "#0e3a55"],
        floor=["#03101a", "#020810", "#010306"],
        sun=["#ffffff", "#c8f8ff", "#7df2ff", "#00e5ff"], sun_radius=64,
        grid="#ff9e1b", grid_dim="#5a3008", ridge="#00e5ff", ridge_fill="#020810", horizon="#00e5ff"),
}

if __name__ == "__main__":
    out = sys.argv[1]
    for name, params in VARIANTS.items():
        write_png(render(params), f"{out}/{name}")
        print(name)
