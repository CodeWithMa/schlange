INCLUDE "hardware.inc"
INCLUDE "font.inc"

DEF TEXT_START_ADDRESS EQU $9821
DEF ROW_SIZE EQU $20

SECTION "Highscore Screen", ROM0

ShowHighscore::
    ; Do not turn the LCD off outside of VBlank
    call WaitVBlank

    call TurnLcdOff

    ; Initialize variables

    ; Load tiles and tilemap
    ;call LoadHighScoreTiles
    call LoadFontTiles
    call LoadHighScoreTilemap

    ; Write text to background
    ld de, TEXT_START_ADDRESS
    ld hl, HighscoreText
    call DrawTextTiles

    ; TODO Load scores and display each on its own row
    ; Placeholder for now
    ld de, TEXT_START_ADDRESS + ROW_SIZE * 2
    ld hl, TodoText
    call DrawTextTiles

    ld de, TEXT_START_ADDRESS + ROW_SIZE * 3
    ld hl, TodoText
    call DrawTextTiles

    ld de, TEXT_START_ADDRESS + ROW_SIZE * 4
    ld hl, TodoText
    call DrawTextTiles

    call TurnLcdOnNoObj

    ; Put in function?
    ; During the first (blank) frame, initialize display registers
    ; Set Palettes
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

WaitInHighscoreScreen:
    ; TODO Use interrupts
    ; and halt. in interupt set variable to check
    ; if main loop should go to load the game
    ld a, [rLY]
    cp 144
    jp nc, WaitInHighscoreScreen

    call WaitVBlank

    call UpdateKeys

    ; Return if the A button is pressed
    ld a, [wNewKeys]
    and a, PADF_A
    ret nz

    jp WaitInHighscoreScreen

; LoadHighScoreTiles:
;     ld de, HighScoreTiles
;     ld hl, _VRAM9000 + FONT_TILES_SIZE
;     ld bc, HIGHSCORE_TILES_SIZE
;     call Memcopy
;     ret

LoadHighScoreTilemap:
    ; ld de, HighScoreTilemap
    ; ld hl, _SCRN0
    ; ld bc, HighScoreTilemapEnd - HighScoreTilemap
    ; call MemcopyWithFontOffset

    ; For now clear the whole screen
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

HighscoreText: db "HIGHSCORE", 255
TodoText: db "TODO", 255
