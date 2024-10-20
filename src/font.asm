INCLUDE "src/include/hardware.inc/hardware.inc"
INCLUDE "src/include/font.inc"
INCLUDE "src/include/hardware_extensions.inc"

SECTION "Font", ROM0

FontTiles: INCBIN "obj/gfx/font.2bpp"

; Load the complete font. Starting with the numbers.
; After that comes the alphabet. After loading some tiles
; in memory are duplicates of each other. For example the
; 0 is the same as the O and I is the same as 1.
LoadFontTiles::
    call LoadFontNumberTilesInOrder
    
    ld de, FontTiles + TILE_DATA_SIZE * 0 ; A -> Z
    ld hl, _VRAM9000 + TILE_DATA_SIZE * 10
    ld bc, TILE_DATA_SIZE * 26
    call Memcopy
    
    ; Also copy symbols like + - : . etc.
    ld de, FontTiles + TILE_DATA_SIZE * 33 ; / -> EMPTY
    ld hl, _VRAM9000 + TILE_DATA_SIZE * 36
    ld bc, TILE_DATA_SIZE * 6
    call Memcopy

    ret

; This will load the number tiles in order
LoadFontNumberTilesInOrder:
    ld de, FontTiles + TILE_DATA_SIZE * 14 ; 0
    ld hl, _VRAM9000 + TILE_DATA_SIZE * 0
    ld bc, TILE_DATA_SIZE
    call Memcopy

    ld de, FontTiles + TILE_DATA_SIZE * 8 ; 1
    ld hl, _VRAM9000 + TILE_DATA_SIZE * 1
    ld bc, TILE_DATA_SIZE
    call Memcopy

    ld de, FontTiles + TILE_DATA_SIZE * 26 ; 2 -> 4
    ld hl, _VRAM9000 + TILE_DATA_SIZE * 2
    ld bc, TILE_DATA_SIZE * 3
    call Memcopy

    ld de, FontTiles + TILE_DATA_SIZE * 18 ; 5
    ld hl, _VRAM9000 + TILE_DATA_SIZE * 5
    ld bc, TILE_DATA_SIZE
    call Memcopy

    ld de, FontTiles + TILE_DATA_SIZE * 29 ; 6 -> 9
    ld hl, _VRAM9000 + TILE_DATA_SIZE * 6
    ld bc, TILE_DATA_SIZE * 4
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

ClearScreen0::
    ld hl, _SCRN0
    ld bc, _SCRN1 - _SCRN0 ; Size of one screen
:
    ld a, FONT_EMPTY_TILE_ID
    ld [hli], a

    dec bc
    ld a, b
    or a, c
    jp nz, :-

    ret
