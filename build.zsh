export RGBDS=~/Programming/ROMS/rgbds/
"$RGBDS"/rgbgfx -c "#FFFFFF,#cfcfcf,#686868,#000000;" -o gfx/background.2bpp --tilemap gfx/background.tilemap --unique-tiles gfx/background.png
"$RGBDS"/rgbgfx -c "#FFFFFF,#cfcfcf,#686868,#000000;" -o gfx/snake_head.2bpp gfx/snake_head.png
"$RGBDS"/rgbgfx -c "#FFFFFF,#cfcfcf,#686868,#000000;" -o gfx/snake_body.2bpp gfx/snake_body.png
"$RGBDS"/rgbasm -o main.o main.asm
"$RGBDS"/rgblink -o schlange.gb main.o
"$RGBDS"/rgbfix -v -p 0xFF schlange.gb
