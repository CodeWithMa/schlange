# Define paths and tools
RGBGFX = $(RGBDS)rgbgfx
RGBASM = $(RGBDS)rgbasm
RGBLINK = $(RGBDS)rgblink
RGBFIX = $(RGBDS)rgbfix

RGBASM_WARN = -Weverything -Wnumeric-string=2 -Wtruncation=1

# Define files and settings
GB_PALETTE = "\#FFFFFF,\#cfcfcf,\#686868,\#000000;"
OUTPUT_GB = schlange.gb

# Define object files and other intermediates
OBJ_FILES = main.o input.o title_screen.o util/memory.o util/vblank.o
GFX_BACKGROUND_TILES = gfx/background.2bpp
GFX_BACKGROUND_TILEMAP = gfx/background.tilemap
GFX_TITLE_SCREEN_TILES = gfx/title_screen.2bpp
GFX_TITLE_SCREEN_TILEMAP = gfx/title_screen.tilemap
GFX_SNAKE_HEAD = gfx/snake_head.2bpp

# Default target
all: $(OUTPUT_GB)

# Convert graphics to 2bpp format
$(GFX_BACKGROUND_TILES): gfx/background.png
	$(RGBGFX) -c $(GB_PALETTE) -o $(GFX_BACKGROUND_TILES) --unique-tiles $<

$(GFX_TITLE_SCREEN_TILES): gfx/title_screen.png
	$(RGBGFX) -c $(GB_PALETTE) -o $(GFX_TITLE_SCREEN_TILES) --tilemap $(GFX_TITLE_SCREEN_TILEMAP) --unique-tiles $<

$(GFX_SNAKE_HEAD): gfx/snake_head.png
	$(RGBGFX) -c $(GB_PALETTE) -o $(GFX_SNAKE_HEAD) $<

input.o: input.asm
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

title_screen.o: title_screen.asm $(GFX_TITLE_SCREEN_TILES) $(GFX_TITLE_SCREEN_TILEMAP)
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

util/memory.o: util/memory.asm
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

util/vblank.o: util/vblank.asm
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

# Assemble main assembly file
main.o: main.asm $(GFX_BACKGROUND_TILES) $(GFX_BACKGROUND_TILEMAP) $(GFX_SNAKE_HEAD)
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

# Link object file to create the ROM
$(OUTPUT_GB): $(OBJ_FILES)
	$(RGBLINK) -o $(OUTPUT_GB) $(OBJ_FILES)
	$(RGBFIX) -t "SCHLANGE" -v -p 0xFF $(OUTPUT_GB)

# Clean up build artifacts
clean:
	rm -f $(OBJ_FILES) $(OUTPUT_GB) $(GFX_BACKGROUND_TILES) $(GFX_TITLE_SCREEN_TILES) $(GFX_TITLE_SCREEN_TILEMAP) $(GFX_SNAKE_HEAD)

.PHONY: all clean
