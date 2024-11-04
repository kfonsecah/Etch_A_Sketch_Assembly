import tkinter as tk
from tkinter import filedialog
from PIL import Image

# Define the available colors and their corresponding hex values
available_colors = {
    '0': (0, 0, 0),          # Negro (Black)
    '1': (0, 0, 139),        # Azul (Dark blue)
    '2': (0, 100, 0),        # Verde (Dark green)
    '3': (0, 255, 255),      # Cian (Cyan)
    '4': (139, 0, 0),        # Rojo (Dark red)
    '5': (128, 0, 128),      # Púrpura (Purple)
    '6': (139, 69, 19),      # Marrón (Brown)
    '7': (169, 169, 169),    # Blanco opaco (Light gray)
    '8': (105, 105, 105),    # Gris (Dark gray)
    '9': (173, 216, 230),    # Azul claro (Light blue)
    'A': (144, 238, 144),    # Verde claro (Light green)
    'B': (173, 216, 230),    # Celeste claro (Light sky blue)
    'C': (255, 182, 193),    # Rojo claro (Light red)
    'D': (255, 20, 147),     # Rosado (Pink)
    'E': (255, 255, 0),      # Amarillo (Yellow)
    'F': (255, 255, 255)     # Blanco brillante (Bright white)
}

#available_colors = {
    # '1': (0, 0, 139),        # Dark blue
   #'2': (0, 100, 0),        # Dark green
    #'3': (139, 69, 19),      # Brown
    #'4': (139, 0, 0),        # Dark red
    #'5': (255, 20, 147),     # Pinkish Purple
    #'6': (255, 255, 0),      # Yellow
    #'7': (169, 169, 169),    # Light gray
    #'8': (105, 105, 105),    # Dark gray
    #'9': (173, 216, 230),    # Light blue
    #'A': (144, 238, 144),    # Light green
    #'B': (0, 255, 255),      # Cyan
    #'C': (255, 182, 193),    # Light red
   # 'D': (255, 165, 0),      # Orange
    #'E': (128, 0, 128),      # Purple
    #'F': (255, 255, 255)     # White
#}

def closest_color(rgb):
    r, g, b = rgb
    return min([(abs(r - cr) ** 2 + abs(g - cg) ** 2 + abs(b - cb) ** 2, hex_value) for hex_value, (cr, cg, cb) in available_colors.items()])[1]

def convert_image_to_hex(image_path, output_path):
    img = Image.open(image_path).convert('RGB')
    width, height = img.size

    # Resize only if the image is larger than the target size
    if width > 398 or height > 300:
        img = img.resize((398, 300))

    with open(output_path, 'w') as f:
        for y in range(img.height):
            for x in range(img.width):
                f.write(f'{closest_color(img.getpixel((x, y)))} ')
            f.write('@\n')
        f.write('%')
        

def main():
    root = tk.Tk()
    root.withdraw()
    image_path = filedialog.askopenfilename(title="Select an Image", filetypes=[("Image files", "*.png;*.jpg;*.bmp")])
    if image_path:
        output_path = image_path.rsplit('.', 1)[0] + '.txt'
        convert_image_to_hex(image_path, output_path)

if __name__ == '__main__':
    main()