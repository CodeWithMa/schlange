# Define paths and tools
RGBGFX  = $(RGBDS)rgbgfx
RGBASM  = $(RGBDS)rgbasm
RGBLINK = $(RGBDS)rgblink
RGBFIX  = $(RGBDS)rgbfix

RGBASM_WARN = -Weverything -Wnumeric-string=2 -Wtruncation=1

# Define files and settings
GB_PALETTE = "\#FFFFFF,\#cfcfcf,\#686868,\#000000;"
ROM_NAME = schlange

# Directories
OBJ_DIR = obj
UTIL_DIR = $(OBJ_DIR)/util
SRC_DIR = src
GFX_SRC_DIR = $(SRC_DIR)/gfx
GFX_OBJ_DIR = $(OBJ_DIR)/gfx

# Object files
OBJ_FILES = \
	$(OBJ_DIR)/credits.o \
	$(OBJ_DIR)/font.o \
	$(OBJ_DIR)/game.o \
	$(OBJ_DIR)/highscore.o \
	$(OBJ_DIR)/input.o \
	$(OBJ_DIR)/main.o \
	$(UTIL_DIR)/lcd.o \
	$(UTIL_DIR)/memory.o \
	$(UTIL_DIR)/oam.o \
	$(UTIL_DIR)/random.o \
	$(UTIL_DIR)/screen.o \
	$(UTIL_DIR)/vblank.o \
	$(OBJ_DIR)/title_screen.o

# Graphics files
GFX_BACKGROUND_TILES = $(GFX_OBJ_DIR)/background.2bpp
GFX_FONT_TILES = $(GFX_OBJ_DIR)/font.2bpp
GFX_TITLE_SCREEN_TILES = $(GFX_OBJ_DIR)/title_screen.2bpp
GFX_TITLE_SCREEN_TILEMAP = $(GFX_OBJ_DIR)/title_screen.tilemap
GFX_SNAKE_HEAD = $(GFX_OBJ_DIR)/snake_head.2bpp

# Default target
all: dirs $(ROM_NAME).gb

# Create necessary directories
dirs:
	@mkdir -p $(OBJ_DIR) $(UTIL_DIR) $(GFX_OBJ_DIR)

# Pattern rule for assembling object files
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

$(UTIL_DIR)/%.o: $(SRC_DIR)/util/%.asm
	$(RGBASM) $(RGBASM_WARN) -o $@ $<

# Convert graphics to 2bpp format
$(GFX_OBJ_DIR)/%.2bpp: $(GFX_SRC_DIR)/%.png
	$(RGBGFX) -c $(GB_PALETTE) -o $@ --unique-tiles $<

# Special cases for tilemaps
$(GFX_OBJ_DIR)/title_screen.2bpp: $(GFX_SRC_DIR)/title_screen.png
	$(RGBGFX) -c $(GB_PALETTE) -o $@ --tilemap $(GFX_OBJ_DIR)/title_screen.tilemap --unique-tiles $<

# Add dependencies for graphics before assembling object files
$(OBJ_DIR)/font.o: $(SRC_DIR)/font.asm $(GFX_FONT_TILES)
$(OBJ_DIR)/game.o: $(SRC_DIR)/game.asm $(GFX_BACKGROUND_TILES) $(GFX_SNAKE_HEAD)
$(OBJ_DIR)/title_screen.o: $(SRC_DIR)/title_screen.asm $(GFX_TITLE_SCREEN_TILES) $(GFX_TITLE_SCREEN_TILEMAP)

# Link object files to create the ROM
$(ROM_NAME).gb: $(OBJ_FILES)
	$(RGBLINK) -m $(ROM_NAME).map -n $(ROM_NAME).sym -o $@ $^
	$(RGBFIX) -t "SCHLANGE" -v -p 0xFF $@

# Clean up build artifacts
clean:
	rm -r $(OBJ_DIR) $(ROM_NAME).gb $(ROM_NAME).map $(ROM_NAME).sym

.PHONY: all clean dirs
