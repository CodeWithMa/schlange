INCLUDE "src/include/hardware.inc/hardware.inc"
INCLUDE "src/include/font.inc"

DEF TEXT_START_ADDRESS EQU $9821
DEF ROW_SIZE EQU $20

SECTION "Highscore Screen", ROM0

ShowHighscore::
    ; Do not turn the LCD off outside of VBlank
    call WaitForVBlankInterrupt

    call TurnLcdOff

    ; Initialize variables

    ; Load tiles and tilemap
    call LoadFontTiles
    call ClearScreen0

    ; Write text to background
    ld de, TEXT_START_ADDRESS
    ld hl, HighscoreText
    call DrawTextTiles

    ; Draw saved scores
    ld de, TEXT_START_ADDRESS + ROW_SIZE * 2
    call DrawHighscores

    call TurnLcdOnNoObj

    ; Put in function?
    ; During the first (blank) frame, initialize display registers
    ; Set Palettes
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

WaitInHighscoreScreen:
    call WaitForVBlankInterrupt

    call UpdateKeys

    ; Return if the A button is pressed
    ld a, [wNewKeys]
    and a, PADF_A
    ret nz

    jp WaitInHighscoreScreen

HighscoreText: db "HIGHSCORE", 255
