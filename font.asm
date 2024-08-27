INCLUDE "hardware.inc"
INCLUDE "font.inc"

SECTION "Font", ROM0

FontTiles: INCBIN "gfx/font.2bpp"
FontTilesEnd:

DEF FONT_TILES_SIZE_CALCULATED EQU FontTilesEnd - FontTiles
STATIC_ASSERT FONT_TILES_SIZE_CALCULATED == FONT_TILES_SIZE, "Font was changed without updating font.inc!"

LoadFontTiles::
    ld de, FontTiles
    ld hl, _VRAM9000
    ld bc, FONT_TILES_SIZE
    call Memcopy
    ret
