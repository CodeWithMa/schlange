INCLUDE "hardware.inc"
INCLUDE "font.inc"

DEF FIRST_MENU_TEXT_START_ADDRESS EQU $9928
DEF ROW_SIZE EQU $20
DEF CURSOR_TILE_ID EQU 52

DEF MENU_MAX_INDEX EQU 2

SECTION "Title Screen", ROM0

ShowTitleScreen::

    ; Initialize variables
    ld a, 0
    ld [wSelectedMenuItem], a

    ; Load tiles and tilemap
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

    ; Write second menu text to background
    ld de, FIRST_MENU_TEXT_START_ADDRESS + ROW_SIZE * 2
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
    ; TODO Check selected menu item
    ld a, [wCurKeys]
    and a, PADF_START
    ret nz

    ; Check up or down to move cursor
    call MoveMenuCursor

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

MoveMenuCursor:
    ld a, [wNewKeys]

    cp a, PADF_UP
    jp z, MoveMenuCursorUp

    cp a, PADF_DOWN
    jp z, MoveMenuCursorDown

    ret

MoveMenuCursorUp:
    ld a, [wSelectedMenuItem]
    
    ; return if the first item is selected
    cp a, 0
    ret z

    ; save new index
    dec a
    ld [wSelectedMenuItem], a

    call DrawCursorAtMenuIndex

    ; Remove previous cursor by
    ; adding 32 from hl to get previous background address
    ld bc, ROW_SIZE
    add hl, bc
    ld [hl], FONT_EMPTY_TILE_ID

    ret

MoveMenuCursorDown:
    ld a, [wSelectedMenuItem]

    ; return if last item is selected
    cp a, MENU_MAX_INDEX
    ret z

    ; Remove previous cursor 
    call CalculateMenuAddressAtIndex
    ld [hl], FONT_EMPTY_TILE_ID

    ; Draw new cursor
    ld bc, ROW_SIZE
    add hl, bc
    ld [hl], CURSOR_TILE_ID

    ; save new index
    inc a
    ld [wSelectedMenuItem], a

    ret

; @param a: selected menu index
DrawCursorAtMenuIndex:
    call CalculateMenuAddressAtIndex
    ld [hl], CURSOR_TILE_ID
    ret

; @param a: index
; @return hl: background address
CalculateMenuAddressAtIndex:
    ld bc, FIRST_MENU_TEXT_START_ADDRESS - 1

    ; Multiply the menu index a by $20 (32) which is how long each row is
    ; Because a will overflow if selected index is > 7 (8 * 32 is 256)
    ; put a in hl
    ld h, 0
    ld l, a

    add hl, hl ; * 2
    add hl, hl ; * 4
    add hl, hl ; * 8
    add hl, hl ; * 16
    add hl, hl ; * 32

    add hl, bc

    ret

TitleScreenTiles: INCBIN "gfx/title_screen.2bpp"
TitleScreenTilesEnd:
DEF TITLE_SCREEN_TILES_SIZE EQU TitleScreenTilesEnd - TitleScreenTiles
DEF TITLE_SCREEN_NUMBER_OF_TILES EQU TITLE_SCREEN_TILES_SIZE / 16
STATIC_ASSERT FONT_NUMBER_OF_TILES + TITLE_SCREEN_NUMBER_OF_TILES < 129, "Number of total background tiles is too large!"

TitleScreenTilemap: INCBIN "gfx/title_screen.tilemap"
TitleScreenTilemapEnd:

StartText: db "START", 255
TodoText: db "TODO", 255

SECTION "Selected Menu Item", WRAM0
wSelectedMenuItem: db
