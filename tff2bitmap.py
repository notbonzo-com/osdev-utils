from PIL import Image, ImageDraw, ImageFont
TTF_PATH = "font.ttf"
FONT_SIZE = 8
CHAR_START = 32
CHAR_END = 127
ARRAY_NAME = "myFont8x8"

def render(font, char):
    img = Image.new("L", (8, 8), color=0)
    draw = ImageDraw.Draw(img)

    offset_x, offset_y = 0, 0
    draw.text((offset_x, offset_y), char, font=font, fill=255)

    rows = []
    for y in range(8):
        row_val = 0
        for x in range(8):
            pixel = img.getpixel((x, y))
            bit = 1 if pixel > 128 else 0
            row_val = (row_val << 1) | bit
        rows.append(row_val)
    return rows

font = ImageFont.truetype(TTF_PATH, FONT_SIZE)
all_chars = []
for codepoint in range(CHAR_START, CHAR_END):
    char = chr(codepoint)
    rows = render(font, char)
    all_chars.append((char, rows))

print(f"// Created using NotBonzo's (c) TFF2BitmapMonochrome generator")
print(f"// All rights reserved")
print(f"// Character range: {CHAR_START}..{CHAR_END - 1}")
print(f"// Generated from font: {TTF_PATH}")
print(f"// Format: {ARRAY_NAME}[char_index][8]")
print(f"static const unsigned char {ARRAY_NAME}[][8] = {{")

for (char, rows) in all_chars:
    row_strs = [f"0b{row:08b}" for row in rows]
    print("    { " + ", ".join(row_strs) + " }, // '{}'".format(char if char.isprintable() else f"\\x{ord(char):02X}"))
print("};")
