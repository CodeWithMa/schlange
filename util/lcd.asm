INCLUDE "hardware.inc/hardware.inc"

SECTION "LCD Utils", ROM0

; Turn the LCD off
TurnLcdOff::
    ld a, 0
    ld [rLCDC], a
    ret

TurnLcdOn::
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld [rLCDC], a
    ret

TurnLcdOnNoObj::
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a
    ret
