INCLUDE "src/hardware.inc/hardware.inc"

SECTION "Random Utils", ROM0

; Get a random tile address
; @return hl: tile address
GetRandomTileAddress::
    ; first empty tile address is $9821
    ; add random number to it
    ld a, 0
    ld b, a
    ld a, [wRandomSeed]
    ld c, a
    ld hl, $9821
    add hl, bc

    ; This loads the value from the Game Boy's Divider Register (rDIV) into the A register.
    ; The Divider Register is a timer that's constantly incrementing at 16384Hz when the Game Boy is running.
    ; Its value is essentially unpredictable at any given moment, making it a good source of randomness.
    ld b, a
    ld a, [rDIV]
    add a, b

    ld [wRandomSeed], a

    ; adding 8 bit is not enough to reach the end
    ; of the playing field so add every odd frame
    ; an additional amount to reach the end
    and a, 1
    jr z, AddMoreEnd

AddMore:
    ld a, 0
    ld b, a
    ld a, 242
    ld c, a
    add hl, bc

AddMoreEnd:
    ret

; WRAM

SECTION "Random Seed", WRAM0
wRandomSeed: db
