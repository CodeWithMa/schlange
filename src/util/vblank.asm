INCLUDE "src/include/hardware.inc/hardware.inc"

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

WaitForVBlankInterrupt::
    ld   hl, wVBlankInterruptFlag  ; hl = pointer to vblank_flag
    xor  a                ; a = 0
.wait
    halt                  ; suspend CPU - wait for ANY enabled interrupt
    cp   a, [hl]          ; is the vblank_flag still zero?
    jr   z, .wait         ; keep waiting if zero
    ld   [hl], a          ; set the vblank_flag back to zero
    ret

SECTION "Frame Counter", WRAM0
wFrameCounter:: db

SECTION "VBlank Interrupt Flag", WRAM0
wVBlankInterruptFlag:: db
