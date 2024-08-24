INCLUDE "hardware.inc"

SECTION "Title Screen", ROM0

ShowTitleScreen::

LoadTitleScreen:

    ; Load title screen tiles
    ld de, TitleScreenTiles
    ld hl, _VRAM9000
    ld bc, TitleScreenTilesEnd - TitleScreenTiles
    call Memcopy

    ; Load title screen tilemap
    ld de, TitleScreenTilemap
    ld hl, _SCRN0
    ld bc, TitleScreenTilemapEnd - TitleScreenTilemap
    call Memcopy

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

    call WaitVBlank

    call UpdateKeys

    ; Check start button
    ld a, [wCurKeys]
    and a, PADF_START
    ret nz

    jp WaitInTitleScreen

TitleScreenTiles: INCBIN "gfx/title_screen.2bpp"
TitleScreenTilesEnd:

TitleScreenTilemap: INCBIN "gfx/title_screen.tilemap"
TitleScreenTilemapEnd:
