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

; Draws text to the background
; @param de: Address to start drawing the tiles on
; @param hl: Address to the start of the text to draw
DrawTextTiles::
    ; Stop at the end of the string
    ld a, [hli]
    cp 255
    ret z

    ld [de], a
    inc de

    jp DrawTextTiles
