INCLUDE "hardware.inc"

SECTION "Header", ROM0[$100]
    jp EntryPoint
    ds $150 - @, 0 ; Make room for the header

EntryPoint:

Main:
    ; Load and show title screen
    ; This call will return when
    ; the start button was pressed
    call ShowTitleScreen

    ; TODO What do I do after starting the game?
    call StartGame

    jp Main

; Extract in utils
DebugLoop::
    jp DebugLoop
