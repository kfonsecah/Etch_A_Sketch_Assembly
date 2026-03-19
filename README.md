# TXTS — x86 Assembly Paint Program

TXTS is a graphical drawing application written entirely in x86 Assembly (MASM), running in DOS real mode under the VGA 640×480 16-color graphics mode (`INT 10h`, mode `12h`). It provides a canvas, a color palette, mouse support, keyboard movement, file save/load in a custom hex format, and image importing — all built from scratch without any external libraries.

---

## How it works

The program initializes in VGA mode `12h` and draws the entire interface pixel by pixel using BIOS interrupt `INT 10h` (function `0Ch` for writing pixels, `0Dh` for reading them). The main loop polls the mouse continuously via `INT 33h` and processes keyboard input via `INT 16h`, then re-enters the loop indefinitely until the user presses `Esc`.

```
Program start
      ↓
Set VGA mode 12h (640×480, 16 colors)
      ↓
Draw UI (rectangles, color squares, arrows, borders)
      ↓
Initialize mouse (INT 33h)
      ↓
MAIN_LOOP:
    Poll mouse → paint pixel / select color / click button
    Poll keyboard → WASD movement / text capture / Esc exit
      ↓
    Loop forever
```

All drawing operations are macros that expand inline — there are no function calls for basic rendering. `PINTA_PIXEL`, `DIBUJAR_CUADRADO`, `DIBUJAR_RECTANGULO`, `DIBUJAR_BORDE_RECTANGULO`, and `RELLENAR_PANTALLA` all invoke `INT 10h` directly in tight loops.

---

## Interface layout

The screen is divided into fixed regions defined by hard-coded pixel coordinates:

- **Drawing canvas** — `(136, 90)` to `(533, 389)`, 398×300 pixels, white background
- **Left color palette** — 6 color squares at `x=75`, stacked vertically from `y=100` to `y=380`
- **Right color palette** — 6 more color squares at `x=564`, same vertical range
- **Bottom toolbar** — save, load, text field, and insert image buttons
- **Direction arrows** — four clickable squares at the bottom right for pixel movement
- **Active color indicator** — a square at `(355, 445)` showing the currently selected draw color
- **Previous background color** — a smaller square at `(335, 460)` showing the last flood-fill color

---

## Color palette

The program supports 16 colors mapped to the VGA palette indices `0h` through `Fh`. Colors are assigned to the 12 clickable palette squares. Clicking a square sets `color_pixel` to that color's VGA index, which is then used for all subsequent drawing operations.

| Index | Color          |
|-------|----------------|
| `0`   | Black          |
| `1`   | Dark blue      |
| `2`   | Dark green     |
| `3`   | Cyan           |
| `4`   | Dark red       |
| `5`   | Purple         |
| `6`   | Brown          |
| `7`   | Light gray     |
| `8`   | Dark gray      |
| `9`   | Light blue     |
| `A`   | Light green    |
| `B`   | Light sky blue |
| `C`   | Light red      |
| `D`   | Pink           |
| `E`   | Yellow         |
| `F`   | Bright white   |

---

## Drawing tools

**Mouse painting** — holding the left mouse button while the cursor is inside the canvas writes the current color at that pixel position. The mouse position is read each frame with `INT 33h` function `03h`.

**WASD movement** — pressing W, A, S, or D moves a single pixel cursor around the canvas and paints as it moves, for precision drawing without the mouse.

**Direction button painting** — the four arrow buttons at the bottom of the screen move the pixel cursor one step in the corresponding direction on each click.

**Flood fill** — clicking the square at `(390, 445)` reads every pixel in the canvas, replaces all pixels matching the previous background color with the current draw color, and updates the background color indicator.

---

## File format

Saved files are plain text with a custom encoding. Each pixel's VGA color index is written as a single hex digit (`0`–`F`), with pixels separated by spaces. Each row ends with `@\n` and the file ends with `%`.

```
0 0 0 F F F 0 0 @
0 F F F F F 0 0 @
0 0 0 F F F 0 0 @
%
```

This format is also what `image_converter.py` produces — the Python script reads any PNG, JPG, or BMP image, resizes it to fit the canvas (398×300 maximum), and maps each pixel to its nearest VGA palette color, writing the result in the same single-hex-digit-per-pixel format.

**Saving** — clicking "Guardar Bosquejo" creates a `.txt` file named after whatever is in the text field, then iterates over every pixel in the canvas with `INT 10h` function `0Dh` and writes the hex digit to the file using DOS `INT 21h` function `40h`.

**Loading** — clicking "Cargar Bosquejo" opens the named file, reads it character by character, converts each hex digit back to a VGA color index, and paints the pixel at the corresponding canvas position.

**Inserting images** — clicking "Insertar Imagen" works the same as loading but places the image starting at the current cursor position `(current_x, current_y)` rather than always at the canvas origin.

---

## Image converter

`image_converter.py` is a companion Python script that converts standard image files into the `.txt` format the assembler program can load.

```bash
pip install pillow
python image_converter.py
```

A file dialog opens to select the source image. The script resizes it to at most 398×300 pixels (preserving the original if it is already smaller), maps each pixel to the nearest VGA color using Euclidean distance in RGB space, and saves the result as a `.txt` file alongside the original.

---

## Project structure

```
txts/
├── main.asm             # Full program source (MASM syntax)
├── image_converter.py   # Python image-to-hex converter
└── .gitignore
```

The program assembles to a single `.exe` (`TXTS.EXE`) using MASM and runs under DOS or a DOS emulator such as DOSBox.

---


## Known limitations

- The text field accepts up to 10 characters; longer filenames are not supported
- There is no undo — cleared or overwritten pixels cannot be recovered except by reloading a saved file
- The flood fill reads and rewrites every pixel in the canvas sequentially, which is slow at full canvas size
- The image insert does not clip — if the loaded image is wider than the remaining canvas space from `current_x`, pixels past column 534 are skipped silently

---

*This is an academic project developed to apply low-level programming concepts from a Computer Organization and Assembly Language course.*
