INCLUDE "src/include/hardware.inc/hardware.inc"

SECTION "Util OAM", ROM0

ClearOam::
    ; ClearOam
    ld a, 0
    ld b, 160
    ld hl, _OAMRAM
ClearOamLoop:
    ld [hli], a
    dec b
    jp nz, ClearOamLoop
    ret
