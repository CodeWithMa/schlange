INCLUDE "src/include/hardware.inc/hardware.inc"

DEF START_GAME_MENU_INDEX EQU 0
DEF HIGHSCORE_MENU_INDEX EQU 1
DEF CREDITS_MENU_INDEX EQU 2

SECTION "VBlank Interrupt", ROM0[$0040]
VBlankInterrupt:
	push af
	push bc
	push de
	push hl
	jp VBlankHandler

SECTION "VBlank Handler", ROM0
VBlankHandler:
    ; set interrupt flag
    ld a, 1
    ld [wVBlankInterruptFlag], a

    ; increment frame counter
    ld a, [wFrameCounter]
    inc a
    ld [wFrameCounter], a

    call hUGE_TickSound

    ;call UpdateKeys

	; Now we just have to `pop` those registers and return!
	pop hl
	pop de
	pop bc
	pop af

	reti

SECTION "Header", ROM0[$100]
    jp EntryPoint
    ds $150 - @, 0 ; Make room for the header

EntryPoint:

    ; initialize global variables
    ld a, 0
    ld [wFrameCounter], a
    ld [wCurKeys], a
    ld [wNewKeys], a
    
    ; enable the VBlank interrupt
    ld a, IEF_VBLANK
	ldh [rIE], a

    ; clear rIF
    ld a, 0
    ldh [rIF], a

    ; enable interrupts
    ei

    call SetupFortissimo

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
    ; TODO Show Game Over Screen?
    jp Main

CallShowHighscore:
    call ShowHighscore
    jp Main

CallShowCredits:
    call ShowCredits
    jp Main

SetupFortissimo:
    ; You must do this at least once during game startup.
	xor a
	ldh [hUGE_MutedChannels], a

	; Turn on the APU, and set the panning & volume to reasonable defaults.
	ld a, AUDENA_ON
	ldh [rNR52], a
	ld a, $FF
	ldh [rNR51], a
	ld a, $77
	ldh [rNR50], a

    ld de, IevanPolkkaSong ; This is the song descriptor that was passed to `teNOR`.
	call hUGE_SelectSong

    ret

; Extract in utils
DebugLoop::
    jr DebugLoop
