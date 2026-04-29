from PIL import Image, ImageDraw

def round_corners(input_path, output_path, radius):
    img = Image.open(input_path).convert("RGBA")

    mask = Image.new("L", img.size, 0)
    draw = ImageDraw.Draw(mask)

    draw.rounded_rectangle(
        [(0, 0), img.size],
        radius=radius,
        fill=255
    )

    img.putalpha(mask)

    img.save(output_path, format="PNG")


if __name__ == "__main__":
    # укажи свои файлы здесь
    input_file = "input.png"
    output_file = "output.png"
    
    round_corners(input_file, output_file, radius=100)