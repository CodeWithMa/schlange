INCLUDE "hardware.inc"
INCLUDE "font.inc"

DEF FIRST_MENU_TEXT_START_ADDRESS EQU $9928
DEF ROW_SIZE EQU $20

SECTION "Title Screen", ROM0

ShowTitleScreen::

    call LoadTitleScreenTiles
    call LoadFontTiles
    call LoadTitleScreenTilemap

    ; Write menu text to background
    ld de, FIRST_MENU_TEXT_START_ADDRESS
    ld hl, StartText
    call DrawTextTiles

    ; Write second menu text to background
    ld de, FIRST_MENU_TEXT_START_ADDRESS + ROW_SIZE
    ld hl, TodoText
    call DrawTextTiles

    ; Put in function?
    ; Turn the LCD on
    ; TODO turn objon if start screen has object in the future
    ;ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld a, LCDCF_ON | LCDCF_BGON
    ld [rLCDC], a

    ; Put in function?
    ; During the first (blank) frame, initialize display registers
    ; Set Palettes
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

WaitInTitleScreen:
    ; TODO Wait for start button press
    ; TODO Use interrupts
    ; and halt. in interupt set variable to check
    ; if main loop should go to load the game
    ld a, [rLY]
    cp 144
    jp nc, WaitInTitleScreen

    ; TODO Do I need this wait?
    call WaitVBlank

    call UpdateKeys

    ; Check start button
    ld a, [wCurKeys]
    and a, PADF_START
    ret nz

    jp WaitInTitleScreen

LoadTitleScreenTiles:
    ld de, TitleScreenTiles
    ld hl, _VRAM9000 + FONT_TILES_SIZE
    ld bc, TITLE_SCREEN_TILES_SIZE
    call Memcopy
    ret

LoadTitleScreenTilemap:
    ld de, TitleScreenTilemap
    ld hl, _SCRN0
    ld bc, TitleScreenTilemapEnd - TitleScreenTilemap
    call MemcopyWithFontOffset
    ret

; Draws text to the background
; @param de: Address to start drawing the tiles on
; @param hl: Address to the start of the text to draw
DrawTextTiles:
    ; Stop at the end of the string
    ld a, [hli]
    cp 255
    ret z

    ld [de], a
    inc de

    jp DrawTextTiles

TitleScreenTiles: INCBIN "gfx/title_screen.2bpp"
TitleScreenTilesEnd:
DEF TITLE_SCREEN_TILES_SIZE EQU TitleScreenTilesEnd - TitleScreenTiles
DEF TITLE_SCREEN_NUMBER_OF_TILES EQU TITLE_SCREEN_TILES_SIZE / 16
STATIC_ASSERT FONT_NUMBER_OF_TILES + TITLE_SCREEN_NUMBER_OF_TILES < 129, "Number of total background tiles is too large!"

TitleScreenTilemap: INCBIN "gfx/title_screen.tilemap"
TitleScreenTilemapEnd:

StartText: db "START", 255
TodoText: db "TODO", 255
