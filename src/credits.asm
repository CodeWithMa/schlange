INCLUDE "src/hardware.inc/hardware.inc"
INCLUDE "src/font.inc"

DEF TEXT_START_ADDRESS EQU $9821
DEF ROW_SIZE EQU $20

SECTION "Credits Screen", ROM0

ShowCredits::
    ; Do not turn the LCD off outside of VBlank
    call WaitVBlank

    call TurnLcdOff

    ; Initialize variables

    ; Load tiles and tilemap
    call LoadFontTiles
    call ClearScreen0

    ; Write text to background
    ld de, TEXT_START_ADDRESS
    ld hl, CreditsText
    call DrawTextTiles

    ; Write credits
    ld de, TEXT_START_ADDRESS + ROW_SIZE * 2
    ld hl, SuperDiskText
    call DrawTextTiles

    ld de, TEXT_START_ADDRESS + ROW_SIZE * 3
    ld hl, SuperDiskText2
    call DrawTextTiles

    ld de, TEXT_START_ADDRESS + ROW_SIZE * 5
    ld hl, IssotmText
    call DrawTextTiles

    ld de, TEXT_START_ADDRESS + ROW_SIZE * 7
    ld hl, GbdevText
    call DrawTextTiles

    ld de, TEXT_START_ADDRESS + ROW_SIZE * 8
    ld hl, GbdevText2
    call DrawTextTiles

    ld de, TEXT_START_ADDRESS + ROW_SIZE * 9
    ld hl, GbdevText3
    call DrawTextTiles

    ld de, TEXT_START_ADDRESS + ROW_SIZE * 10
    ld hl, GbdevText4
    call DrawTextTiles

    ld de, TEXT_START_ADDRESS + ROW_SIZE * 12
    ld hl, TilemapStudioText
    call DrawTextTiles

    ld de, TEXT_START_ADDRESS + ROW_SIZE * 13
    ld hl, TilemapStudioText2
    call DrawTextTiles

    ld de, TEXT_START_ADDRESS + ROW_SIZE * 15
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

WaitInCreditsScreen:
    ; TODO Use interrupts
    ; and halt. in interupt set variable to check
    ; if main loop should go to load the game
    ld a, [rLY]
    cp 144
    jp nc, WaitInCreditsScreen

    call WaitVBlank

    call UpdateKeys

    ; Return if the A button is pressed
    ld a, [wNewKeys]
    and a, PADF_A
    ret nz

    jp WaitInCreditsScreen

CreditsText: db "CREDITS", 255

SuperDiskText: db "SUPERDISK", 255
SuperDiskText2: db " /HUGETRACKER", 255

IssotmText: db "ISSOTM/FORTISSIMO", 255

GbdevText: db "GBDEV", 255
GbdevText2: db " /RGBDS", 255
GbdevText3: db " /HARDWARE.INC", 255
GbdevText4: db " /GB-ASM-TUTORIAL", 255

TilemapStudioText: db "RANGI42", 255
TilemapStudioText2: db " /TILEMAP-STUDIO", 255

TodoText: db "TODO", 255
