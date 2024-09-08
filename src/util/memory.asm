INCLUDE "src/font.inc"

SECTION "Memory Copy", ROM0

; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length
Memcopy::
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, Memcopy
    ret

; Copy bytes from one area to another.
; Add the number of tiles to the loaded tile id.
; @param de: Source
; @param hl: Destination
; @param bc: Length
MemcopyWithFontOffset::
    ld a, [de]
    add a, FONT_NUMBER_OF_TILES
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, MemcopyWithFontOffset
    ret
