INCLUDE "src/include/hardware.inc/hardware.inc"
INCLUDE "src/include/font.inc"

DEF TEXT_CENTER_START_ADDRESS EQU $9825
DEF TEXT_START_ADDRESS EQU $9821
DEF ROW_SIZE EQU $20

SECTION "Game Over Screen", ROM0

ShowGameOver::
    ; Do not turn the LCD off outside of VBlank
    call WaitForVBlankInterrupt

    call TurnLcdOff

    ; Initialize variables

    ; Load tiles and tilemap
    call LoadFontTiles

    call ClearScreen0

    ; Write game over text to background
    ld de, TEXT_CENTER_START_ADDRESS
    ld hl, GameOverText
    call DrawTextTiles

    ; Score text
    ld de, TEXT_START_ADDRESS + ROW_SIZE * 2
    ld hl, TodoText
    call DrawTextTiles

    call DrawScoreOfLastGame

    call TurnLcdOnNoObj

    ; Put in function?
    ; During the first (blank) frame, initialize display registers
    ; Set Palettes
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

WaitInGameOverScreen:
    call WaitForVBlankInterrupt

    call UpdateKeys

    ; Return if the A button is pressed
    ld a, [wNewKeys]
    and a, PADF_A
    ret nz

    jp WaitInGameOverScreen

DrawScoreOfLastGame:
    
    ; TODO address where the text starts
    ; calculate? or just hardcode
    ld hl, (TEXT_START_ADDRESS + ROW_SIZE * 2) + 8

    ; Font is loaded so that the values map to tile ids of the numbers

    ld a, [wApplesCounter]
    ld [hld], a
    ld a, [wApplesCounterSecondDigit]
    ld [hld], a
    ld a, [wApplesCounterThirdDigit]
    ld [hl], a
    
    ret

GameOverText: db "GAME OVER", 255
TodoText: db "SCORE", 255
