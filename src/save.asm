INCLUDE "src/include/hardware.inc/hardware.inc"

DEF CHECKSUM1 EQU 123
DEF CHECKSUM2 EQU 111
DEF CHECKSUM3 EQU 222
DEF HIGHSCORES_ROWS EQU 14
DEF HIGHSCORES_ITEM_SIZE EQU 6
DEF HIGHSCORES_SIZE EQU HIGHSCORES_ROWS * HIGHSCORES_ITEM_SIZE

; Section for initializing, loading and saving save data
SECTION "Save Data Methods", ROM0

EnableSaveAccess:
    ld a, CART_SRAM_ENABLE
    ld [rRAMG], a
    ret

DisableSaveAccess:
    ld a, CART_SRAM_DISABLE
    ld [rRAMG], a
    ret

InitializeSaveData::

    call EnableSaveAccess

    ; Call CheckForExistingSaveData and skip init if it is already done
    call CheckForExistingSaveData
    jp z, :+
    jp :++
:
    call DisableSaveAccess
    ret
:

    ld a, CHECKSUM1
    ld [sCheckSum1], a

    ld a, CHECKSUM2
    ld [sCheckSum2], a

    ld a, CHECKSUM3
    ld [sCheckSum3], a

    ; Initialize array
    ld a, 0
    ld hl, sHighScores
REPT HIGHSCORES_SIZE
    ld [hli], a
ENDR

    call DisableSaveAccess

    ret

; Check for existing save data
CheckForExistingSaveData:

    ld a, [sCheckSum1]
    cp a, CHECKSUM1 
    jp z, :+
    ret

:
    ld a, [sCheckSum2]
    cp a, CHECKSUM2
    jp z, :+
    ret

:
    ld a, [sCheckSum3]
    cp a, CHECKSUM3
    ret

SaveScoreOfLastGame::
    
    call EnableSaveAccess

    ; Find position in score array to place new score
    ; Move every score below that one down but not the last one
    ; Then save the new one
    
    ; TODO

    ; Load first score
    ld hl, sHighScores

    call CompareScore

    ; Compare will return hl set to where the new score should be saved
    call SaveScore

    call DisableSaveAccess

    ret

; Code below will save score to array item pointed to by hl
; @param hl: first byte of item in array to save the new score to
SaveScore:

    ; TODO first name char
    ld a, 1
    ld [hli], a

    ; TODO second name char
    ld a, 2
    ld [hli], a

    ; TODO third name char
    ld a, 3
    ld [hli], a

    ld a, [wApplesCounterThirdDigit]
    ld [hli], a

    ld a, [wApplesCounterSecondDigit]
    ld [hli], a

    ld a, [wApplesCounter]
    ld [hl], a

    ret

; @param hl: first byte of high score item to compare in the array
CompareScore:

    ; Move to first byte of the score (first 3 bytes are the name)
    inc hl
    inc hl
    inc hl

    ld a, [wApplesCounterThirdDigit]
    cp a, [hl]
    jr c, CheckSecondDigit ; If less than high score, continue to second digit
    jr z, CheckSecondDigit ; If equal, continue to second digit
    ; Move back to fist byte of item
    dec hl
    dec hl
    dec hl
    jr NewScoreIsGreater ; If greater, jump to NewScoreIsGreater

CheckSecondDigit:
    ; Move to the second digit in the high score array
    inc hl

    ; Load second digit of the current score
    ld a, [wApplesCounterSecondDigit]
    cp a, [hl]             ; Compare with high score second digit
    jr c, CheckFirstDigit  ; If less, go to next digit
    jr z, CheckFirstDigit  ; If equal, go to next digit
    ; Move back to fist byte of item
    dec hl
    dec hl
    dec hl
    dec hl
    jr NewScoreIsGreater ; If greater, jump to NewScoreIsGreater

CheckFirstDigit:
    ; Move to the first digit in the high score array
    inc hl

    ; Load first digit of the current score
    ld a, [wApplesCounter]
    cp a, [hl]             ; Compare with high score first digit
    jr c, ScoreIsLower     ; If less, score is lower
    ; I handle ScoreIsEqual the same as NewScoreIsGreater
    ; NewScoreIsGreater expects hl to be at the start of the item,
    ; which means I need to dec hl and can not jump directly from here
    ; I can just comment it here and it should work
    ;jr z, ScoreIsEqual     ; If equal, score matches the high score
    
    ; Move back to fist byte of item
    dec hl
    dec hl
    dec hl
    dec hl
    dec hl
    jr NewScoreIsGreater ; If greater, jump to NewScoreIsGreater

ScoreIsLower:
    ; Code to handle if the score is lower than the high score

    ; Move to next item
    inc hl
    ; Return if this was the last item
    ; because the new score is not greater than any existing one
    call IsEndOfScoreArray
    ; if both bytes match -> Current item was the last one in array
    ret z

    ; Compare the next item
    jp CompareScore
; End of CompareScore Method (No ret because it loops to next item here)

; @param hl: hl address to check if it is the end of the array
; (actually the address of the byte after the array)
; @returns z is set if it is the end
; @trashes: a, bc
IsEndOfScoreArray:
    ; Compare if first byte matches
    ld bc, sHighScoresEnd
    call CompareTwoBytes
    ret

; TOOD Move to memory.asm
; Compare hl to bc. If h is b and l is c z is set else it is not.
; @param hl: bytes to compare
; @param bc: bytes to compare
CompareTwoBytes:
    ld a, b
    cp a, h
    jr z, :+

    ; Bytes do not match
    ret

    ; Compare if second byte matches
:
    ld a, c
    cp a, l
    ret

; Code to handle if the score is exactly equal to the high score
; Code to handle if the score is greater than the high score
; If I insert the new score at the current position then
; both cases are the same.
; hl: first byte of the array item to save the new score to
ScoreIsEqual:
NewScoreIsGreater:
    
    ; save hl in de to go back to it after moving everything down
    ; I also need it to check how far I have to copy stuff down
    ld d, h
    ld e, l
    ; be carefull to not change de in the following code

:
    ; Go the end of the array
    ; To go to the end of the array i can move the size of one item in the array per loop
REPT HIGHSCORES_ITEM_SIZE
    inc hl
ENDR

    call IsEndOfScoreArray
    jr z, :+

    ; Loop and move to next byte
    jr :-

; hl is the byte after the end of the array here
:
    ; go to last byte
    dec hl
    ; put de in bc for method CompareTwoBytes below
    ld b, d
    ld c, e

    ; Now loop and copy every byte one down
:
REPT HIGHSCORES_ITEM_SIZE
    dec hl
ENDR
    ld a, [hl]
REPT HIGHSCORES_ITEM_SIZE
    inc hl
ENDR
    ld [hld], a

    ; TODO Add a check to stop after we got to the position,
    ; which will contain the new score
    ; bc contains the address of the item where the new score should be saved
    call CompareTwoBytes
    jr z, AllCopiedDownNowSaveNewScore
    jr :- ; loop

AllCopiedDownNowSaveNewScore:

    ; TODO Just return here and let the caller save score

    ret
; End of method

; @param de: start screen background address to start drawing
; @trashes: a, de, hl
DrawHighscores::
    call EnableSaveAccess

    ld hl, sHighScores
    
    ; Counter for drawing all rows
    ld b, HIGHSCORES_ROWS

    ; Load all entries
:
    call DrawOneHighScoreEntry
    dec b
    ; If counter is 0 then we are done
    ld a, b
    cp a, 0
    ret z
    ; Else draw next entry
    ; inc de by 25 to move to background address of start of next row
    ; TODO Maybe optimize this and actually add 25 to de - Check what takes more space in the rom
REPT 25
    inc de
ENDR
    jr :-

    call DisableSaveAccess

    ret

; @param de: start screen background address to start drawing
; @param hl: start of the save data entry
; @trashes: a, de, hl
DrawOneHighScoreEntry:
    ; Write name
REPT 3
    ; load nth byte of save data entry
    ld a, [hli]
    ; set background to loaded value
    ld [de], a
    inc de
ENDR

    ; Write space (skip over one tile)
    inc de

    ; Write score
REPT 3
    ; load nth byte of save data entry
    ld a, [hli]
    ; set background to loaded value
    ld [de], a
    inc de
ENDR
    ret

SECTION "Save Variables", SRAM

; Array of highscores:
; First 3 bytes are the name of the player
; Last 3 bytes are the digits of the score
; Each digit of the score is saved in its own byte
; I can just store it like this
; It wastes 1 byte for each score that is saved but way easier to use
; On one screen without the heading and spacing I can fit 14 rows
; 14 * 6 bytes
sHighScores:: ds HIGHSCORES_SIZE
sHighScoresEnd:

sCheckSum1:: db
sCheckSum2:: db
sCheckSum3:: db
