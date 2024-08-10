# Define paths and tools
RGBGFX = $(RGBDS)/rgbgfx
RGBASM = $(RGBDS)/rgbasm
RGBLINK = $(RGBDS)/rgblink
RGBFIX = $(RGBDS)/rgbfix

# Define files and settings
GB_PALETTE = "\#FFFFFF,\#cfcfcf,\#686868,\#000000;"
OUTPUT_GB = schlange.gb

# Define object files and other intermediates
OBJ_FILES = main.o
GFX_BACKGROUND_TILES = gfx/background.2bpp
GFX_BACKGROUND_TILEMAP = gfx/background.tilemap
GFX_SNAKE_HEAD = gfx/snake_head.2bpp
GFX_SNAKE_BODY = gfx/snake_body.2bpp

# Default target
all: $(OUTPUT_GB)

# Convert graphics to 2bpp format
$(GFX_BACKGROUND_TILES): gfx/background.png
	$(RGBGFX) -c $(GB_PALETTE) -o $(GFX_BACKGROUND_TILES) --tilemap $(GFX_BACKGROUND_TILEMAP) --unique-tiles $<

$(GFX_SNAKE_HEAD): gfx/snake_head.png
	$(RGBGFX) -c $(GB_PALETTE) -o $(GFX_SNAKE_HEAD) $<

$(GFX_SNAKE_BODY): gfx/snake_body.png
	$(RGBGFX) -c $(GB_PALETTE) -o $(GFX_SNAKE_BODY) --unique-tiles $<

# Assemble main assembly file
main.o: main.asm $(GFX_BACKGROUND_TILES) $(GFX_SNAKE_HEAD) $(GFX_SNAKE_BODY)
	$(RGBASM) -o $@ $<

# Link object file to create the ROM
$(OUTPUT_GB): $(OBJ_FILES)
	$(RGBLINK) -o $(OUTPUT_GB) $(OBJ_FILES)
	$(RGBFIX) -v -p 0xFF $(OUTPUT_GB)

# Clean up build artifacts
clean:
	rm -f $(OBJ_FILES) $(OUTPUT_GB) $(GFX_BACKGROUND_TILES) $(GFX_SNAKE_HEAD) $(GFX_SNAKE_BODY) $(GFX_BACKGROUND_TILEMAP)

.PHONY: all clean
