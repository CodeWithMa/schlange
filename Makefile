# Define paths and tools
RGBGFX = $(RGBDS)rgbgfx
RGBASM = $(RGBDS)rgbasm
RGBLINK = $(RGBDS)rgblink
RGBFIX = $(RGBDS)rgbfix

RGBASM_WARN = -Weverything -Wnumeric-string=2 -Wtruncation=1

# Define files and settings
GB_PALETTE = "\#FFFFFF,\#cfcfcf,\#686868,\#000000;"
ROM_NAME = schlange

# Define object files and other intermediates
OBJ_FILES = obj/credits.o obj/font.o obj/game.o obj/highscore.o obj/input.o obj/main.o obj/title_screen.o obj/util/lcd.o obj/util/memory.o obj/util/oam.o obj/util/random.o obj/util/screen.o obj/util/vblank.o
GFX_BACKGROUND_TILES = src/gfx/background.2bpp
GFX_BACKGROUND_TILEMAP = src/gfx/background.tilemap
GFX_FONT_TILES = src/gfx/font.2bpp
GFX_TITLE_SCREEN_TILES = src/gfx/title_screen.2bpp
GFX_TITLE_SCREEN_TILEMAP = src/gfx/title_screen.tilemap
GFX_SNAKE_HEAD = src/gfx/snake_head.2bpp

# Default target
all: $(ROM_NAME).gb

# Convert graphics to 2bpp format
$(GFX_BACKGROUND_TILES): src/gfx/background.png
	$(RGBGFX) -c $(GB_PALETTE) -o $(GFX_BACKGROUND_TILES) --unique-tiles $<

$(GFX_FONT_TILES): src/gfx/font.png
	$(RGBGFX) -c $(GB_PALETTE) -o $(GFX_FONT_TILES) --unique-tiles $<

$(GFX_TITLE_SCREEN_TILES): src/gfx/title_screen.png
	$(RGBGFX) -c $(GB_PALETTE) -o $(GFX_TITLE_SCREEN_TILES) --tilemap $(GFX_TITLE_SCREEN_TILEMAP) --unique-tiles $<

$(GFX_SNAKE_HEAD): src/gfx/snake_head.png
	$(RGBGFX) -c $(GB_PALETTE) -o $(GFX_SNAKE_HEAD) $<

obj/credits.o: src/credits.asm src/font.inc $(GFX_FONT_TILES)
	@mkdir -p ${@D}
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

obj/font.o: src/font.asm src/font.inc src/util/hardware_extensions.inc $(GFX_FONT_TILES)
	@mkdir -p ${@D}
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

obj/game.o: src/game.asm src/font.inc src/util/hardware_extensions.inc $(GFX_BACKGROUND_TILES) $(GFX_BACKGROUND_TILEMAP) $(GFX_SNAKE_HEAD)
	@mkdir -p ${@D}
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

obj/highscore.o: src/highscore.asm src/font.inc
	@mkdir -p ${@D}
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

obj/input.o: src/input.asm
	@mkdir -p ${@D}
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

obj/title_screen.o: src/title_screen.asm src/font.inc $(GFX_TITLE_SCREEN_TILES) $(GFX_TITLE_SCREEN_TILEMAP)
	@mkdir -p ${@D}
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

obj/util/lcd.o: src/util/lcd.asm
	@mkdir -p ${@D}
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

obj/util/memory.o: src/util/memory.asm src/font.inc
	@mkdir -p ${@D}
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

obj/util/oam.o: src/util/oam.asm
	@mkdir -p ${@D}
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

obj/util/random.o: src/util/random.asm
	@mkdir -p ${@D}
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

obj/util/screen.o: src/util/screen.asm
	@mkdir -p ${@D}
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

obj/util/vblank.o: src/util/vblank.asm
	@mkdir -p ${@D}
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

obj/main.o: src/main.asm
	@mkdir -p ${@D}
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

# Link object file to create the ROM
$(ROM_NAME).gb: $(OBJ_FILES)
	$(RGBLINK) -m $(ROM_NAME).map -n $(ROM_NAME).sym -o $(ROM_NAME).gb $(OBJ_FILES)
	$(RGBFIX) -t "SCHLANGE" -v -p 0xFF $(ROM_NAME).gb

# Clean up build artifacts
clean:
	rm -f $(OBJ_FILES) $(ROM_NAME).gb $(ROM_NAME).map $(ROM_NAME).sym $(GFX_BACKGROUND_TILES) $(GFX_FONT_TILES) $(GFX_TITLE_SCREEN_TILES) $(GFX_TITLE_SCREEN_TILEMAP) $(GFX_SNAKE_HEAD)

.PHONY: all clean
