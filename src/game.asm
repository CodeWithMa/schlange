INCLUDE "src/include/hardware.inc/hardware.inc"
INCLUDE "src/include/font.inc"
INCLUDE "src/include/hardware_extensions.inc"

; Constants
DEF FALSE EQU 0
DEF TRUE EQU 1

; OAM tiles
; Head tiles
DEF SNAKE_HEAD_LEFT_TILE_ID EQU 0
DEF SNAKE_HEAD_RIGHT_TILE_ID EQU 1
DEF SNAKE_HEAD_DOWN_TILE_ID EQU 2
DEF SNAKE_HEAD_UP_TILE_ID EQU 3

; Background tiles
DEF EMPTY_TILE_ID EQU FONT_NUMBER_OF_TILES + 0

; Wall tiles
DEF TOP_WALL_TILE_ID EQU FONT_NUMBER_OF_TILES + 2
DEF LEFT_WALL_TILE_ID EQU FONT_NUMBER_OF_TILES + 4
DEF RIGHT_WALL_TILE_ID EQU FONT_NUMBER_OF_TILES + 5
DEF BOTTOM_WALL_TILE_ID EQU FONT_NUMBER_OF_TILES + 7

; Body tiles
DEF SNAKE_BODY_HORIZONTAL_TILE_ID EQU FONT_NUMBER_OF_TILES + 9 + 1
DEF SNAKE_BODY_VERTICAL_TILE_ID EQU FONT_NUMBER_OF_TILES + 9 + 3
DEF SNAKE_BODY_LEFT_TO_TOP_TILE_ID EQU FONT_NUMBER_OF_TILES + 9 + 4
DEF SNAKE_BODY_LEFT_TO_DOWN_TILE_ID EQU FONT_NUMBER_OF_TILES + 9 + 0
DEF SNAKE_BODY_RIGHT_TO_TOP_TILE_ID EQU FONT_NUMBER_OF_TILES + 9 + 5
DEF SNAKE_BODY_RIGHT_TO_DOWN_TILE_ID EQU FONT_NUMBER_OF_TILES + 9 + 2

; Tail tiles
DEF SNAKE_TAIL_LEFT_TILE_ID EQU FONT_NUMBER_OF_TILES + 9 + 6
DEF SNAKE_TAIL_RIGHT_TILE_ID EQU FONT_NUMBER_OF_TILES + 9 + 7
DEF SNAKE_TAIL_DOWN_TILE_ID EQU FONT_NUMBER_OF_TILES + 9 + 8
DEF SNAKE_TAIL_UP_TILE_ID EQU FONT_NUMBER_OF_TILES + 9 + 9

; Apple tile
DEF APPLE_TILE_ID EQU FONT_NUMBER_OF_TILES + 9 + 10

; The snake starts in the middle
DEF SNAKE_START_POS_X EQU 10
DEF SNAKE_START_POS_Y EQU 8

DEF SNAKE_INITIAL_TAIL_ADDRESS EQU $9908
DEF SNAKE_INITIAL_BODY_ADDRESS EQU $9909

DEF SNAKE_MOVE_NONE EQU 0
DEF SNAKE_MOVE_UP EQU 1
DEF SNAKE_MOVE_DOWN EQU 2
DEF SNAKE_MOVE_RIGHT EQU 3
DEF SNAKE_MOVE_LEFT EQU 4

; Address in which snake head position is saved
DEF SNAKE_HEAD_POS_Y_ADDRESS EQU _OAMRAM

; Tile addresses where the score will be displayed
DEF SCORE_TILE_1_ADDRESS EQU _SCRN0 + 10
DEF SCORE_TILE_2_ADDRESS EQU _SCRN0 + 9
DEF SCORE_TILE_3_ADDRESS EQU _SCRN0 + 8

SECTION "Game", ROM0

StartGame::
    call InitializeGame
    call GameLoop
    ret

InitializeGame:
    call WaitForVBlankInterrupt

    call TurnLcdOff

    ; Load tiles

    ; SnakeHeadData
    ld de, SnakeHeadData
    ld hl, _VRAM
    ld bc, SnakeHeadDataEnd - SnakeHeadData
    call Memcopy

    ; Background Tiles

    ; Load Font
    call LoadFontNumberTilesInOrder

    ; Wall tiles etc
    ld de, BackgroundTiles
    ld hl, _VRAM9000 + FONT_TILES_SIZE
    ld bc, BackgroundTilesEnd - BackgroundTiles
    call Memcopy

    ; Load Background tilemap
    ld de, BackgroundTilemap
    ld hl, _SCRN0
    ld bc, BackgroundTilemapEnd - BackgroundTilemap
    call MemcopyWithFontOffset

    ; Load initial score after the background is loaded
    ld hl, SCORE_TILE_3_ADDRESS
    ld a, 0
    ld [hli], a
    ld [hli], a
    ld [hli], a

    ; Spawn 3 random apples
REPT 3
    call GetRandomEmptyTileAddress
    ld a, APPLE_TILE_ID
    ld [hl], a
ENDR    

    call ClearOam

    ; Once OAM is clear, we can draw an object by writing its properties.
    ; Initialize the snake head sprite in OAM
    ld hl, wSnakePositionY
    ld a, SNAKE_START_POS_Y * 8
    add a, 16 ; y offset to make it start at 0
    ld [hl], a

    ld hl, wSnakePositionX
    ld a, SNAKE_START_POS_X * 8
    add a, 8 ; x offset to make it start at 0
    ld [hl], a

    ld hl, wSnakeHeadTileId
    ld a, SNAKE_HEAD_RIGHT_TILE_ID
    ld [hl], a

    ; TODO Why set 0 to the byte after tile id? For init? See docs on obj struct
    ;ld a, 0
    ;ld [hli], a

    ; Snake is not moving until first key press
    ld a, SNAKE_MOVE_NONE
    ld [wSnakeDirection], a
    ld a, SNAKE_MOVE_RIGHT
    ld [wPreviousSnakeDirection], a

    ; If i want to set the starting background tiles for
    ; the snake body it has to be done before the LCD is
    ; turned on
    call InitializeSnakeBody

    call TurnLcdOn

    ; During the first (blank) frame, initialize display registers
    ; Set Palettes
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

    ; Initialize global variables
    ld a, 0
    ld [wFrameCounter], a
    ld [wApplesCounter], a
    ld [wIsGameOver], a
    ld [wCurKeys], a
    ld [wNewKeys], a
    ld [wUpdateNextBody], a
    
    ; Set Snake Speed to 60 -> Move once every second
    ld a, 30
    ld [wSnakeSpeed], a
    ret

GameLoop:
    ; Only continue if vblank interrupt was called
    call WaitForVBlankInterrupt

    ; TODO Maybe only do this inside MoveSnakePosition when
    ; the snake moves? Now it updates the values every frame
    ; even if the snake did not move
    ; TODO But then it will only be updated after speed amount of frames
    ; which means the display is one turn behind
    call UpdateSnakeOam
    call UpdateBackgroundSnakeTiles

    call MoveSnakePosition

    ; Return if game is over
    ld a, [wIsGameOver]
    cp a, 1
    ret z

    ; Check the current keys every frame.
    call UpdateKeys
    call UpdateSnakeDirection

    jp GameLoop

UpdateSnakeDirection:
    ; First, check if the left button is pressed.
CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jp z, CheckRight
Left:
    ; if old direction was right -> do not allow left
    ld a, [wSnakeDirection]
    cp a, SNAKE_MOVE_RIGHT
    ret z
    ; else
    ld a, SNAKE_MOVE_LEFT
    ld [wSnakeDirection], a
    ret

; Then check the right button.
CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, CheckUp
Right:
    ; if old direction was left -> do not allow right
    ld a, [wSnakeDirection]
    cp a, SNAKE_MOVE_LEFT
    ret z
    ; else
    ld a, SNAKE_MOVE_RIGHT
    ld [wSnakeDirection], a
    ret

; Then check the up button.
CheckUp:
    ld a, [wCurKeys]
    and a, PADF_UP
    jp z, CheckDown
Up:
    ; if old direction was down -> do not allow up
    ld a, [wSnakeDirection]
    cp a, SNAKE_MOVE_DOWN
    ret z
    ; else
    ld a, SNAKE_MOVE_UP
    ld [wSnakeDirection], a
    ret

; Then check the down button.
CheckDown:
    ld a, [wCurKeys]
    and a, PADF_DOWN
    ret z
Down:
    ; if old direction was up -> do not allow down
    ld a, [wSnakeDirection]
    cp a, SNAKE_MOVE_UP
    ret z
    ; else
    ld a, SNAKE_MOVE_DOWN
    ld [wSnakeDirection], a
    ret

InitializeSnakeBody:
    ; set background tiles in tilemap
    ld hl, SNAKE_INITIAL_TAIL_ADDRESS
    
    ld a, SNAKE_TAIL_LEFT_TILE_ID
    ld [hli], a
    ld [wNextTailTileId], a
    ld a, SNAKE_BODY_HORIZONTAL_TILE_ID
    ld [hli], a

    ld bc, SNAKE_INITIAL_BODY_ADDRESS

    ; set first item in wSnakeBodyArray array
    ; +2 because the first item is actually the second,
    ; first one is used for temporary setting the new position when moving
    ld hl, wSnakeBodyArray + 2
    ld [hl], b
    inc hl
    ld [hl], c

    ;ld bc, _SCRN0 + 1; In bc is now the address of the second background tile ID
    ld bc, SNAKE_INITIAL_TAIL_ADDRESS

    ; set second item in wSnakeBodyArray array
    inc hl
    ld [hl], b
    inc hl
    ld [hl], c

    ; decrement by 1 to go to start of second item in array
    dec hl
    call SaveAddressOfLastSnakeBodyPart

    ret

; Method to update snake head position and snake head
; tile id in OAM
UpdateSnakeOam:
    ld hl, SNAKE_HEAD_POS_Y_ADDRESS
    ld a, [wSnakePositionY]
    ld [hli], a
    ld a, [wSnakePositionX]
    ld [hli], a
    ld a, [wSnakeHeadTileId]
    ld [hl], a
    ret

; Update the background tiles
; Set background tile to body where the head was
; Update background for tail
; TODO Also check if apples was eaten -> do not update tail
UpdateBackgroundSnakeTiles:
    ; check if update should run
    ; TODO Maybe this can be optimized and removed
    ld a, [wUpdateNextBody]
    cp a, FALSE
    ret z

    ; reset to false
    ld a, FALSE
    ld [wUpdateNextBody], a

    ; load saved address in hl
    ld a, [wNextBodyTileAddress]
    ld h, a
    ld a, [wNextBodyTileAddress + 1]
    ld l, a

    ; set next body tile
    ld a, [wNextBodyTileId]
    ld [hl], a

    ; Update tail
    ld a, [wNextTailTileAddress]
    ld h, a
    ld a, [wNextTailTileAddress + 1]
    ld l, a

    ld a, [wNextTailTileId]
    ld [hl], a

    ret

MoveSnakePosition:
    ; Load framecounter and only make the snake move every x frames
    ld a, [wFrameCounter]
    ld b, a
    ld a, [wSnakeSpeed]
    cp a, b ; Every x frames, run the following code
    ; TODO Make sure this works. What happens if the framecounter gets
    ; increased to more than the speed.
    ; I have to check if it is greater or equal if yes then move snake
    jp nz, MoveHeadPositionSkip
    ; Reset the frame counter back to 0
    ld a, 0
    ld [wFrameCounter], a

    ; Get address of tile the head is on
    call GetSnakeHeadBackgroundTileAddress
    
    ; Save address on which the head was to wram
    ld a, h
    ld [wNextBodyTileAddress], a
    ld a, l
    ld [wNextBodyTileAddress + 1], a
    
    ; Check what kind of tile the head is on
    ld a, [hl]

    ; Only check if the head is on an allowed tile else game over
    call IsAllowedTileId
    jp z, SetGameOverEnd
    jp SetGameOver

SetGameOver:
    ld a, 1
    ld [wIsGameOver], a

    ; Game Over Song
    ld de, AstronomiaSong ; This is the song descriptor that was passed to `teNOR`.
	call hUGE_SelectSong

    ret

SetGameOverEnd:

    ; Check if on head tile was an apple?
    ; Or check if the next tile to which head is moving is an apple?
    cp a, APPLE_TILE_ID
    jp z, EatApple
    jp DontEatApple

EatApple:
    ; Add one body part to snake
    call AddBodyPartItem
    call GetSnakeHeadBackgroundTileAddress
    call SetBackgroundSnakeTile
    call SaveNewPositionToBodyArray
    call LoadLastSnakeBodyPositionAddress
    ; instead of calling MoveSnakeBody like below only
    ; call the copy loop, as the body does not have
    ; to move
    inc hl
    call MoveArrayItemsLoop
    call MoveHeadPosition
    call SpawnNewApple
    call IncreaseSnakeSpeedIfAteEnoughApples
    call UpdateDisplayScore

    ; TODO Is this the best position?
    ; Set flag to true so background will be updated
    ; Make it a macro?
    ld a, TRUE
    ld [wUpdateNextBody], a

    ret

DontEatApple:

    ; Set background to snake body tile
    ; Depending on which direction snake is moving

    ld a, [wSnakeDirection]
    cp a, SNAKE_MOVE_NONE
    jp z, MoveHeadPositionSkip

    ; Set flag to true so background will be updated
    ld a, TRUE
    ld [wUpdateNextBody], a

    call SetBackgroundSnakeTile

    ; hl has to contain position of last head address. load it
    ; wNextBodyTileAddress -> hl
    ld a, [wNextBodyTileAddress]
    ld h, a
    ld a, [wNextBodyTileAddress + 1]
    ld l, a
    call SaveNewPositionToBodyArray
    
    call MoveSnakeBody
    call MoveHeadPosition

MoveHeadPositionSkip:
    ret

; Add the snake's momentum to its position in OAM.
MoveHeadPosition:
    ; CheckAndMoveLeft
    ld a, [wSnakeDirection]
    cp a, SNAKE_MOVE_LEFT
    jp z, MoveLeft

    ; CheckAndMoveRight
    ld a, [wSnakeDirection]
    cp a, SNAKE_MOVE_RIGHT
    jp z, MoveRight

    ; CheckAndMoveUp
    ld a, [wSnakeDirection]
    cp a, SNAKE_MOVE_UP
    jp z, MoveUp

    ; CheckAndMoveDown
    ld a, [wSnakeDirection]
    cp a, SNAKE_MOVE_DOWN
    jp z, MoveDown

    ; this should never happen -> hang
    call DebugLoop

MoveLeft:
    ld a, -1 * TILE_SIZE
    ld hl, wSnakePositionX
    call MoveSnakePositionByPixel
    ld a, SNAKE_HEAD_LEFT_TILE_ID
    call UpdateSnakeHeadTileId
    jp MoveHeadPositionEnd

MoveRight:
    ld a, 1 * TILE_SIZE
    ld hl, wSnakePositionX
    call MoveSnakePositionByPixel
    ld a, SNAKE_HEAD_RIGHT_TILE_ID
    call UpdateSnakeHeadTileId
    jp MoveHeadPositionEnd

MoveUp:
    ld a, -1 * TILE_SIZE
    ld hl, wSnakePositionY
    call MoveSnakePositionByPixel
    ld a, SNAKE_HEAD_UP_TILE_ID
    call UpdateSnakeHeadTileId
    jp MoveHeadPositionEnd

MoveDown:
    ld a, 1 * TILE_SIZE
    ld hl, wSnakePositionY
    call MoveSnakePositionByPixel
    ld a, SNAKE_HEAD_DOWN_TILE_ID
    call UpdateSnakeHeadTileId
    jp MoveHeadPositionEnd

MoveHeadPositionEnd:
    ; Save previous snake direction
    ld a, [wSnakeDirection]
    ld [wPreviousSnakeDirection], a
    ret

; Method to move the snake's position
; @param a: the amount to move the position by (can be positive or negative)
; @param hl: the address of the position to modify (SNAKE_HEAD_POS_X_ADDRESS or SNAKE_HEAD_POS_Y_ADDRESS)
MoveSnakePositionByPixel:
    ld b, a
    ld a, [hl]
    add a, b
    ld [hl], a
    ret

; @param a: the tile id to set
UpdateSnakeHeadTileId:
    ld hl, wSnakeHeadTileId
    ld [hl], a
    ret

; loop and move all addresse one down overriding the last one
; @param hl: the address of the last snake body position
MoveSnakeBody:
    call SetNewSnakeTail
    call MoveArrayItemsLoop
    ret

SpawnNewApple:
    call GetRandomEmptyTileAddress

    ; set background tile to apple
    ld [hl], APPLE_TILE_ID
    ret

; Get a random empty tile address
; @return hl: tile address
GetRandomEmptyTileAddress:
    call GetRandomTileAddress
    ; hl is the new random background tile address

    ; Check if tile is empty
    ld a, [hl]
    cp a, EMPTY_TILE_ID
    ret z

    ; If tile is not empty generate a new random tile
    jr GetRandomEmptyTileAddress

; Increase speed by 2 every 10 apples
IncreaseSnakeSpeedIfAteEnoughApples:
    ; Increase apple counter
    ld a, [wApplesCounter]
    inc a
    ld [wApplesCounter], a

    ; return if not 10 apples
    cp a, 10
    ret nz

    ; reset apple counter to 0
    ld a, 0
    ld [wApplesCounter], a

    ; increase speed
    ld a, [wSnakeSpeed]
    sub a, 3
    ; Return if result is zero - This happens if we are at full speed
    ret z
    ld [wSnakeSpeed], a
    ret

UpdateDisplayScore:
    ld a, [wApplesCounter]
    ld hl, SCORE_TILE_1_ADDRESS
    ld [hl], a

    ; If counter is 0 then add 1 to next digit
    cp a, 0
    jp z, :+
    ret
:
    ld hl, SCORE_TILE_2_ADDRESS
    ld a, [hl]

    ; Check if value is 9 -> update third digit
    cp a, 9
    jp z, .UpdateThirdDigit
    jp .UpdateSecondDigit

.UpdateThirdDigit:
    ; Set second to 0
    ld a, 0
    ld [hld], a
    ld a, [hl]
    inc a
    ld [hl], a
    ret

.UpdateSecondDigit:
    inc a
    ld [hl], a
    ret

; Get the tilemap address of the background tile
; on which the snake head currently is
; @return hl: tile address
GetSnakeHeadBackgroundTileAddress:
    ld a, [wSnakePositionX]
    ; Offset 8 because object position top left corner is not (0,0)
    sub a, OAM_X_OFS
    ld b, a
    ld a, [wSnakePositionY]
    ; Offset 16 because object position top left corner is not (0,0)
    sub a, OAM_Y_OFS
    ld c, a
    call GetTileByPixel
    ret

; Save the last snake body position address hl into wSnakeLastBodyPositionAddress
; @param hl: address of last body position
SaveAddressOfLastSnakeBodyPart:
    ld a, h
    ld [wSnakeLastBodyPositionAddress], a
    ld a, l
    ld [wSnakeLastBodyPositionAddress + 1], a
    ret

; Load the last snake body position address into hl
; @return hl: address of last body position
; trashes: a
LoadLastSnakeBodyPositionAddress:
    ld a, [wSnakeLastBodyPositionAddress]
    ld h, a
    ld a, [wSnakeLastBodyPositionAddress + 1]
    ld l, a
    ret

; Add one item to the body part array
; by increasing the pointer
AddBodyPartItem:
    call LoadLastSnakeBodyPositionAddress
    inc hl
    inc hl
    call SaveAddressOfLastSnakeBodyPart
    ; also update wNextTailTileAddress
    
    ld a, [hli]
    ld [wNextTailTileAddress], a
    ld a, [hl]
    ld [wNextTailTileAddress + 1], a

    dec hl ; TODO Check if this is needed
    ret

; Set empty background tile to last position
; @param bc: contains the address in the tilemap
SetEmptyBackgroundTileToLastPosition:
    ld a, EMPTY_TILE_ID
    ld [bc], a
    ret

; @param hl: points to the last byte of tail
; @returns a: tile id of tile bofore tail
ReadTileIdFromTileBeforeTail:
    ; Put the address of the tile that is before the tail in bc
    dec hl
    dec hl
    ld c, [hl]
    dec hl
    ld b, [hl]

    ; Save address to tile before tail,
    ; which will become the new tail
    ld a, b
    ld [wNextTailTileAddress], a
    ld a, c
    ld [wNextTailTileAddress + 1], a

    ; Read tile id from tile before tail
    ld a, [bc]

    ; undo changes to hl
    inc hl
    inc hl
    inc hl

    ret

; @param hl: the address of the last snake body position
SetNewSnakeTail:
    ; We need the address of the last body part in bc
    ; to read the tile id before the tail
    call LoadLastSnakeBodyPositionAddress
    ld b, [hl]
    inc hl
    ld c, [hl]
    ; bc contains address of last tile in tilemap

    ; Load what tile id the tail has. It is called next, but always contains the current tail...
    ld a, [wNextTailTileId]
    
    cp a, SNAKE_TAIL_LEFT_TILE_ID
    jp z, SnakeTailWasLeft

    cp a, SNAKE_TAIL_RIGHT_TILE_ID
    jp z, SnakeTailWasRight

    cp a, SNAKE_TAIL_DOWN_TILE_ID
    jp z, SnakeTailWasDown

    cp a, SNAKE_TAIL_UP_TILE_ID
    jp z, SnakeTailWasUp

    ; This should never happen -> hang
    call DebugLoop

SnakeTailWasLeft:
    call SetEmptyBackgroundTileToLastPosition
    call ReadTileIdFromTileBeforeTail

    cp a, SNAKE_BODY_HORIZONTAL_TILE_ID
    jp z, SetLeftTail

    cp a, SNAKE_BODY_RIGHT_TO_DOWN_TILE_ID
    jp z, SetUpTail

    cp a, SNAKE_BODY_RIGHT_TO_TOP_TILE_ID
    jp z, SetDownTail

    ; This should never happen -> hang
    call DebugLoop

SnakeTailWasRight:
    call SetEmptyBackgroundTileToLastPosition
    call ReadTileIdFromTileBeforeTail

    cp a, SNAKE_BODY_HORIZONTAL_TILE_ID
    jp z, SetRightTail

    cp a, SNAKE_BODY_LEFT_TO_DOWN_TILE_ID
    jp z, SetUpTail

    cp a, SNAKE_BODY_LEFT_TO_TOP_TILE_ID
    jp z, SetDownTail

    ; This should never happen -> hang
    call DebugLoop

SnakeTailWasDown:
    call SetEmptyBackgroundTileToLastPosition
    call ReadTileIdFromTileBeforeTail

    cp a, SNAKE_BODY_VERTICAL_TILE_ID
    jp z, SetDownTail

    cp a, SNAKE_BODY_RIGHT_TO_DOWN_TILE_ID
    jp z, SetRightTail

    cp a, SNAKE_BODY_LEFT_TO_DOWN_TILE_ID
    jp z, SetLeftTail

    ; This should never happen -> hang
    call DebugLoop

SnakeTailWasUp:
    call SetEmptyBackgroundTileToLastPosition
    call ReadTileIdFromTileBeforeTail

    cp a, SNAKE_BODY_VERTICAL_TILE_ID
    jp z, SetUpTail

    cp a, SNAKE_BODY_RIGHT_TO_TOP_TILE_ID
    jp z, SetRightTail

    cp a, SNAKE_BODY_LEFT_TO_TOP_TILE_ID
    jp z, SetLeftTail

    ; This should never happen -> hang
    call DebugLoop

SetLeftTail:
    ld a, SNAKE_TAIL_LEFT_TILE_ID
    ld [wNextTailTileId], a
    ret

SetRightTail:
    ld a, SNAKE_TAIL_RIGHT_TILE_ID
    ld [wNextTailTileId], a
    ret

SetDownTail:
    ld a, SNAKE_TAIL_DOWN_TILE_ID
    ld [wNextTailTileId], a
    ret

SetUpTail:
    ld a, SNAKE_TAIL_UP_TILE_ID
    ld [wNextTailTileId], a
    ret

; Calculate which body tile is the correct one
; to place on the background where the head was
; depending on previous and current snake direction
; The next body tile is then save to wNextBodyTileId
; and set on the next vblank
SetBackgroundSnakeTile:
    ld hl, wNextBodyTileId

    ld a, [wPreviousSnakeDirection]

    cp a, SNAKE_MOVE_LEFT
    jp z, MovingFromLeftDirection
    
    cp a, SNAKE_MOVE_RIGHT
    jp z, MovingFromRightDirection

    cp a, SNAKE_MOVE_UP
    jp z, MovingFromUpDirection

    cp a, SNAKE_MOVE_DOWN
    jp z, MovingFromDownDirection
    
    call DebugLoop

MovingFromLeftDirection:
    ld a, [wSnakeDirection]

    cp a, SNAKE_MOVE_UP
    jp z, MovingFromLeftToUp

    cp a, SNAKE_MOVE_DOWN
    jp z, MovingFromLeftToDown

    ; From left to left
    jp SetHorizontalSnakeTile

MovingFromRightDirection:
    ld a, [wSnakeDirection]

    cp a, SNAKE_MOVE_UP
    jp z, MovingFromRightToUp

    cp a, SNAKE_MOVE_DOWN
    jp z, MovingFromRightToDown

    ; From right to right
    jp SetHorizontalSnakeTile

MovingFromUpDirection:
    ld a, [wSnakeDirection]

    cp a, SNAKE_MOVE_LEFT
    jp z, MovingFromRightToDown

    cp a, SNAKE_MOVE_RIGHT
    jp z, MovingFromLeftToDown

    ; From up to up
    jp SetVerticalSnakeTile

MovingFromDownDirection:
    ld a, [wSnakeDirection]

    cp a, SNAKE_MOVE_LEFT
    jp z, MovingFromRightToUp

    cp a, SNAKE_MOVE_RIGHT
    jp z, MovingFromLeftToUp

    ; From down to down
    jp SetVerticalSnakeTile

SetHorizontalSnakeTile:
    ld [hl], SNAKE_BODY_HORIZONTAL_TILE_ID
    jp SetBackgroundSnakeTileEnd

SetVerticalSnakeTile:
    ld [hl], SNAKE_BODY_VERTICAL_TILE_ID
    jp SetBackgroundSnakeTileEnd

MovingFromLeftToUp:
    ld [hl], SNAKE_BODY_LEFT_TO_TOP_TILE_ID
    jp SetBackgroundSnakeTileEnd

MovingFromLeftToDown:
    ld [hl], SNAKE_BODY_LEFT_TO_DOWN_TILE_ID
    jp SetBackgroundSnakeTileEnd

MovingFromRightToUp:
    ld [hl], SNAKE_BODY_RIGHT_TO_TOP_TILE_ID
    jp SetBackgroundSnakeTileEnd

MovingFromRightToDown:
    ld [hl], SNAKE_BODY_RIGHT_TO_DOWN_TILE_ID
    jp SetBackgroundSnakeTileEnd

SetBackgroundSnakeTileEnd:
    ret

SaveNewPositionToBodyArray:
    ; Save the new position to the body array
    ld d, h
    ld e, l
    ; Before moving every body part back
    ; set the item before the first body part to the one we
    ; are standing on when moving down it will be the first
    ld hl, wSnakeBodyArray
    ld [hl], d
    inc hl
    ld [hl], e

    ; Also add the tile id of that tile, which is already put
    ; into wNextBodyTileId

    ; inc hl
    ; ld a, [wNextBodyTileId]
    ; ld [hl], a
    
    ; TODO Adjust move down array loop to move 3 instead of 2 bytes
    ; TODO Initiazlize method has to also initialize the tile id values as 3rd byte of each item
    ; the position of each item is still not correct
    
    ret

; hl has to be the last byte of the array for this to work
; This block overrides the byte pointed to by hl with hl-2
; After this block hl is decremented by 1
MoveArrayItemsLoop:
    dec hl
    dec hl
    ld a, [hli]
    inc hl
    ld [hld], a

    ; if hl is base address + 1 we are done
    ; compare first byte of hl
    ld bc, wSnakeBodyArray + 1
    ld a, b
    cp a, h
    jp z, MoveArrayItemsLoopIsBaseAddressPart1

    ; else continue loop
    jp MoveArrayItemsLoop

MoveArrayItemsLoopIsBaseAddressPart1:
    ; compare second byte of hl
    ld a, c
    cp a, l
    jp z, MoveArrayItemsLoopEnd

    ; else continue loop
    jp MoveArrayItemsLoop

MoveArrayItemsLoopEnd:
    ret

; @param a: tile ID
; @return z: set if a is an allowed tile to be on
IsAllowedTileId:
    cp a, EMPTY_TILE_ID
    ret z
    cp a, APPLE_TILE_ID
    ret

BackgroundTiles: INCBIN "obj/gfx/background.2bpp"
BackgroundTilesEnd:

BackgroundTilemap: INCBIN "src/gfx/background.tilemap"
BackgroundTilemapEnd:

SnakeHeadData: INCBIN "obj/gfx/snake_head.2bpp"
SnakeHeadDataEnd:

; WRAM

SECTION "Snake Head Direction", WRAM0
wSnakeDirection: db
wPreviousSnakeDirection: db

; These are the same values as OAM
; They will be synced every vblank
SECTION "Snake Head Position", WRAM0
wSnakePositionX: db
wSnakePositionY: db
wSnakeHeadTileId: db

; These are updates to the background tiles
; Also synced every vblank
SECTION "Snake Body Updates", WRAM0
wUpdateNextBody: db ; Bool: TRUE if background should be updated

wNextBodyTileAddress: dw
wNextBodyTileId: db

wNextTailTileAddress: dw
wNextTailTileId: db

SECTION "Snake Speed", WRAM0
wSnakeSpeed: db

SECTION "Apples Counter", WRAM0
; Counter for apples. Resets to 0 after collecting 10 apples
; and increasing the speed.
wApplesCounter: db

SECTION "Game Over", WRAM0
wIsGameOver: db

; 20*18 = 360 possible tile positions
; Contains the addresses of the tiles in the tilemap on which a body part is
; Also contains the value that the tile has
; Each address needs 3 bytes so 360 * 3 bytes = 1080 bytes
; 3 bytes because the addresses take 2 bytes and the value takes 1 byte
SECTION "Snake Body Array", WRAM0
wSnakeBodyArray: ds 360 * 3

; Contains the address of the last snake body part in wSnakeBodyArray
; (pointer to last snake body part)
; If I use this instead of snake size i can directly load the last address
wSnakeLastBodyPositionAddress: dw
