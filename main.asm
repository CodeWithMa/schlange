INCLUDE "hardware.inc"

DEF START_GAME_MENU_INDEX EQU 0
DEF HIGHSCORE_MENU_INDEX EQU 1
DEF CREDITS_MENU_INDEX EQU 2

SECTION "Header", ROM0[$100]
    jp EntryPoint
    ds $150 - @, 0 ; Make room for the header

EntryPoint:

Main:
    ; Load and show title screen
    ; This call will return when
    ; a menu item was selected
    call ShowTitleScreen

    ; Check what menu item was selected
    ld a, [wSelectedMenuItem]

    cp a, START_GAME_MENU_INDEX
    jp z, CallStartGame

    cp a, HIGHSCORE_MENU_INDEX
    jp z, CallShowHighscore

    cp a, CREDITS_MENU_INDEX
    jp z, CallShowCredits

    jp Main

CallStartGame:
    call StartGame
    jp Main

CallShowHighscore:
    call ShowHighscore
    jp Main

CallShowCredits:
    call ShowCredits
    jp Main

; Extract in utils
DebugLoop::
    jp DebugLoop
