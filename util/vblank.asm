INCLUDE "hardware.inc"

SECTION "VBlank Utils", ROM0

WaitVBlank::
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank
    ret

WaitNotVBlank:
    ld a, [rLY]
    cp 144
    jp nc, WaitNotVBlank
    ret

; First wait until it is not VBlank
; Then wait for VBlank so we know it is the beginnig of VBlank
WaitForBeginningOfVBlank::
    call WaitNotVBlank
    call WaitVBlank
    ret
