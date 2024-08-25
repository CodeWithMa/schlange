# Schlange Gameboy ROM

This repository contains the source code and assets for "Schlange", a Game Boy game developed using the [RGBDS](https://github.com/gbdev/rgbds) toolchain.

## Features

- Classic snake gameplay on the Game Boy.
- Custom graphics with unique tiles for the snake and background.
- Built with assembly language for authentic retro hardware.

## Download

Download the [latest dev build](https://github.com/CodeWithMa/schlange/releases/tag/v0.0.0-latest) to get the very latest ROM, up-to-date with the dev branch.

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

## Links

- [https://rgbds.gbdev.io/docs/v0.8.0/gbz80.7](https://rgbds.gbdev.io/docs/v0.8.0/gbz80.7)
- [https://evie.gbdev.io/blog/interrupts.html](https://evie.gbdev.io/blog/interrupts.html)
- [https://gbdev.io/gb-asm-tutorial/index.html](https://gbdev.io/gb-asm-tutorial/index.html)
- [https://gbdev.io/pandocs](https://gbdev.io/pandocs)
- [https://github.com/gbdev/rgbds](https://github.com/gbdev/rgbds)
- [https://mgba.io/](https://mgba.io/)
- [https://sameboy.github.io/](https://sameboy.github.io/)
- [https://github.com/Rangi42/tilemap-studio](https://github.com/Rangi42/tilemap-studio)
