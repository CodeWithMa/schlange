# Schlange Gameboy ROM

This repository contains the source code and assets for "Schlange," a Game Boy game developed using the [RGBDS](https://github.com/gbdev/rgbds) toolchain.

## Features

- Classic snake gameplay on the Game Boy.
- Custom graphics with unique tiles for the snake and background.
- Built with assembly language for authentic retro hardware.

## Requirements

- [RGBDS](https://github.com/gbdev/rgbds) toolchain installed and accessible in your system path.

## Building the ROM

To build the ROM, clone this repository and run `make` in the project directory:

```bash
git clone https://github.com/CodeWithMa/schlange.git
cd schlange
make
```

This will generate `schlange.gb`.

## Project Structure

- `main.asm`: Main game logic.
- `gfx/`: Folder containing PNG images and converted `.2bpp` files for graphics.
