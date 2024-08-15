INCLUDE "hardware.inc"

; Constants

DEF OBJECT_OFFSET_X EQU 8
DEF OBJECT_OFFSET_Y EQU 16

DEF TILE_SIZE EQU 8

; Head tiles
DEF SNAKE_HEAD_LEFT_TILE_ID EQU 0
DEF SNAKE_HEAD_RIGHT_TILE_ID EQU 1
DEF SNAKE_HEAD_DOWN_TILE_ID EQU 2
DEF SNAKE_HEAD_UP_TILE_ID EQU 3

; Body tiles
DEF EMPTY_TILE_ID EQU 9 + 4
DEF SNAKE_BODY_HORIZONTAL_TILE_ID EQU 9 + 1
DEF SNAKE_BODY_VERTICAL_TILE_ID EQU 9 + 3
DEF SNAKE_BODY_LEFT_TO_TOP_TILE_ID EQU 9 + 5
DEF SNAKE_BODY_LEFT_TO_DOWN_TILE_ID EQU 9 + 0
DEF SNAKE_BODY_RIGHT_TO_TOP_TILE_ID EQU 9 + 6
DEF SNAKE_BODY_RIGHT_TO_DOWN_TILE_ID EQU 9 + 2

; Tail tiles
DEF SNAKE_TAIL_LEFT_TILE_ID EQU 9 + 7
DEF SNAKE_TAIL_RIGHT_TILE_ID EQU 9 + 8
DEF SNAKE_TAIL_DOWN_TILE_ID EQU 9 + 9
DEF SNAKE_TAIL_UP_TILE_ID EQU 9 + 10

; Apple tile
DEF APPLE_TILE_ID EQU 9 + 11

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
DEF SNAKE_HEAD_POS_X_ADDRESS EQU _OAMRAM + 1
DEF SNAKE_HEAD_POS_Y_ADDRESS EQU _OAMRAM
; Address in which the Tile ID of the snake head is saved
DEF SNAKE_HEAD_TILE_ID_ADDRESS EQU _OAMRAM + 2

SECTION "Header", ROM0[$100]
    jp EntryPoint
    ds $150 - @, 0 ; Make room for the header

EntryPoint:
    ; Do not turn the LCD off outside of VBlank
WaitVBlank:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank

    ; Turn the LCD off
    ld a, 0
    ld [rLCDC], a

    ; Load tiles

    ; SnakeHeadData
    ld de, SnakeHeadData
    ld hl, _VRAM
    ld bc, SnakeHeadDataEnd - SnakeHeadData
    call Memcopy

    ; Background Tiles
    ld de, BackgroundTiles
    ld hl, _VRAM9000
    ld bc, BackgroundTilesEnd - BackgroundTiles
    call Memcopy

    ; SnakeBodyData
    ld de, SnakeBodyData
    ld hl, _VRAM9000 + BackgroundTilesEnd - BackgroundTiles
    ld bc, SnakeBodyDataEnd - SnakeBodyData
    call Memcopy

    ; AppleData
    ld de, AppleData
    ld hl, _VRAM9000 + BackgroundTilesEnd - BackgroundTiles + SnakeBodyDataEnd - SnakeBodyData
    ld bc, AppleDataEnd - AppleData
    call Memcopy

    ; Load Background tilemap
    ld de, BackgroundTilemap
    ld hl, _SCRN0
    ld bc, BackgroundTilemapEnd - BackgroundTilemap
    call Memcopy

    ; For testing set static apple
    ; TODO Place it on a random tile that is not the snake
    ld hl, _SCRN0 + 80
    ld a, APPLE_TILE_ID
    ld [hl], a

    ; ClearOam
    ld a, 0
    ld b, 160
    ld hl, _OAMRAM
ClearOam:
    ld [hli], a
    dec b
    jp nz, ClearOam

    ; Once OAM is clear, we can draw an object by writing its properties.
    ; Initialize the snake head sprite in OAM
    ld hl, SNAKE_HEAD_POS_Y_ADDRESS
    ld a, SNAKE_START_POS_Y * 8
    add a, 16 ; y offset to make it start at 0
    ld [hli], a
    ld a, SNAKE_START_POS_X * 8
    add a, 8 ; x offset to make it start at 0
    ld [hli], a
    ld a, SNAKE_HEAD_RIGHT_TILE_ID
    ld [hli], a
    ld a, 0
    ld [hli], a

    ; Snake is not moving until first key press
    ld a, SNAKE_MOVE_NONE
    ld [wSnakeDirection], a
    ld a, SNAKE_MOVE_RIGHT
    ld [wPreviousSnakeDirection], a

    ; If i want to set the starting background tiles for
    ; the snake body it has to be done before the LCD is
    ; turned on
    call InitializeSnakeBody

    ; Turn the LCD on
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
    ld [rLCDC], a

    ; During the first (blank) frame, initialize display registers
    ; Set Palettes
    ld a, %11100100
    ld [rBGP], a
    ld a, %11100100
    ld [rOBP0], a

    ; Initialize global variables
    ld a, 0
    ld [wFrameCounter], a
    ld [wCurKeys], a
    ld [wNewKeys], a
    
    ; Set Snake Speed to 60 -> Move once every second
    ld a, 60
    ld [wSnakeSpeed], a

Main:
    ld a, [rLY]
    cp 144
    jp nc, Main
WaitVBlank2:
    ld a, [rLY]
    cp 144
    jp c, WaitVBlank2

    call MoveSnakePosition

    ; ld a, [wBallMomentumX]
    ; ld b, a
    ; ld a, [_OAMRAM + 5]
    ; add a, b
    ; ld [_OAMRAM + 5], a

    ; ld a, [wBallMomentumY]
    ; ld b, a
    ; ld a, [_OAMRAM + 4]
    ; add a, b
    ; ld [_OAMRAM + 4], a

; BounceOnTop:
;     ; Remember to offset the OAM position!
;     ; (8, 16) in OAM coordinates is (0, 0) on the screen.
;     ld a, [_OAMRAM + 4]
;     sub a, 16 + 1
;     ld c, a
;     ld a, [_OAMRAM + 5]
;     sub a, 8
;     ld b, a
;     call GetTileByPixel ; Returns tile address in hl
;     ld a, [hl]
;     call IsWallTile
;     jp nz, BounceOnRight
;     call CheckAndHandleBrick
;     ld a, 1
;     ld [wBallMomentumY], a

; BounceOnRight:
;     ld a, [_OAMRAM + 4]
;     sub a, 16
;     ld c, a
;     ld a, [_OAMRAM + 5]
;     sub a, 8 - 1
;     ld b, a
;     call GetTileByPixel
;     ld a, [hl]
;     call IsWallTile
;     jp nz, BounceOnLeft
;     call CheckAndHandleBrick
;     ld a, -1
;     ld [wBallMomentumX], a

; BounceOnLeft:
;     ld a, [_OAMRAM + 4]
;     sub a, 16
;     ld c, a
;     ld a, [_OAMRAM + 5]
;     sub a, 8 + 1
;     ld b, a
;     call GetTileByPixel
;     ld a, [hl]
;     call IsWallTile
;     jp nz, BounceOnBottom
;     call CheckAndHandleBrick
;     ld a, 1
;     ld [wBallMomentumX], a

; BounceOnBottom:
;     ld a, [_OAMRAM + 4]
;     sub a, 16 - 1
;     ld c, a
;     ld a, [_OAMRAM + 5]
;     sub a, 8
;     ld b, a
;     call GetTileByPixel
;     ld a, [hl]
;     call IsWallTile
;     jp nz, BounceDone
;     call CheckAndHandleBrick
;     ld a, -1
;     ld [wBallMomentumY], a
; BounceDone:

;     ; First, check if the ball is low enough to bounce off the paddle.
;     ld a, [_OAMRAM]
;     ld b, a
;     ld a, [_OAMRAM + 4]
;     cp a, b
;     jp nz, PaddleBounceDone ; If the ball isn't at the same Y position as the paddle, it can't bounce.
;     ; Now let's compare the X positions of the objects to see if they're touching.
;     ld a, [_OAMRAM + 5] ; Ball's X position.
;     ld b, a
;     ld a, [_OAMRAM + 1] ; Paddle's X position.
;     sub a, 8
;     cp a, b
;     jp nc, PaddleBounceDone
;     add a, 8 + 16 ; 8 to undo, 16 as the width.
;     cp a, b
;     jp c, PaddleBounceDone

;     ld a, -1
;     ld [wBallMomentumY], a

; PaddleBounceDone:

    ; Check the current keys every frame and move left or right.
    call UpdateKeys

    ; First, check if the left button is pressed.
CheckLeft:
    ld a, [wCurKeys]
    and a, PADF_LEFT
    jp z, CheckRight
Left:
    ; if old direction was right -> do not allow left
    ld a, [wSnakeDirection]
    cp a, SNAKE_MOVE_RIGHT
    jp z, Main
    ; else
    ld a, SNAKE_MOVE_LEFT
    ld [wSnakeDirection], a
    jp Main
    ; ; Move the paddle one pixel to the left.
    ; ld a, [_OAMRAM + 1]
    ; dec a
    ; ; If we've already hit the edge of the playfield, don't move.
    ; cp a, 15
    ; jp z, Main
    ; ld [_OAMRAM + 1], a
    ; jp Main

; Then check the right button.
CheckRight:
    ld a, [wCurKeys]
    and a, PADF_RIGHT
    jp z, CheckUp
Right:
    ; if old direction was left -> do not allow right
    ld a, [wSnakeDirection]
    cp a, SNAKE_MOVE_LEFT
    jp z, Main
    ; else
    ld a, SNAKE_MOVE_RIGHT
    ld [wSnakeDirection], a
    jp Main
    ; ; Move the paddle one pixel to the right.
    ; ld a, [_OAMRAM + 1]
    ; inc a
    ; ; If we've already hit the edge of the playfield, don't move.
    ; cp a, 105
    ; jp z, Main
    ; ld [_OAMRAM + 1], a
    ; jp Main

; Then check the up button.
CheckUp:
    ld a, [wCurKeys]
    and a, PADF_UP
    jp z, CheckDown
Up:
    ; if old direction was down -> do not allow up
    ld a, [wSnakeDirection]
    cp a, SNAKE_MOVE_DOWN
    jp z, Main
    ; else
    ld a, SNAKE_MOVE_UP
    ld [wSnakeDirection], a
    jp Main
    ; ; Move the paddle one pixel to the top.
    ; ld a, [_OAMRAM + 0]
    ; dec a
    ; ; If we've already hit the edge of the playfield, don't move.
    ; ; cp a, 105
    ; ; jp z, Main
    ; ld [_OAMRAM + 0], a
    ; jp Main

; Then check the down button.
CheckDown:
    ld a, [wCurKeys]
    and a, PADF_DOWN
    jp z, Main
Down:
    ; if old direction was up -> do not allow down
    ld a, [wSnakeDirection]
    cp a, SNAKE_MOVE_UP
    jp z, Main
    ; else
    ld a, SNAKE_MOVE_DOWN
    ld [wSnakeDirection], a
    jp Main
    ; ; Move the paddle one pixel to the bottom.
    ; ld a, [_OAMRAM + 0]
    ; inc a
    ; ; If we've already hit the edge of the playfield, don't move.
    ; ; cp a, 105
    ; ; jp z, Main
    ; ld [_OAMRAM + 0], a
    ; jp Main

UpdateKeys:
  ; Poll half the controller
  ld a, P1F_GET_BTN
  call .onenibble
  ld b, a ; B7-4 = 1; B3-0 = unpressed buttons

  ; Poll the other half
  ld a, P1F_GET_DPAD
  call .onenibble
  swap a ; A3-0 = unpressed directions; A7-4 = 1
  xor a, b ; A = pressed buttons + directions
  ld b, a ; B = pressed buttons + directions

  ; And release the controller
  ld a, P1F_GET_NONE
  ldh [rP1], a

  ; Combine with previous wCurKeys to make wNewKeys
  ld a, [wCurKeys]
  xor a, b ; A = keys that changed state
  and a, b ; A = keys that changed to pressed
  ld [wNewKeys], a
  ld a, b
  ld [wCurKeys], a
  ret

.onenibble
  ldh [rP1], a ; switch the key matrix
  call .knownret ; burn 10 cycles calling a known ret
  ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
  ldh a, [rP1]
  ldh a, [rP1] ; this read counts
  or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
.knownret
  ret

InitializeSnakeBody:
    ; set background tiles in tilemap
    ld hl, SNAKE_INITIAL_TAIL_ADDRESS
    ld a, SNAKE_TAIL_LEFT_TILE_ID
    ld [hli], a
    ld a, SNAKE_BODY_HORIZONTAL_TILE_ID
    ld [hli], a


    ld bc, SNAKE_INITIAL_BODY_ADDRESS
    
    ; set first item in wSnakeBodyPositions array
    ; +2 because the first item is actually the second,
    ; first one is used for temporary setting the new position when moving
    ld hl, wSnakeBodyPositions + 2
    ld [hl], b
    inc hl
    ld [hl], c

    ;ld bc, _SCRN0 + 1; In bc is now the address of the second background tile ID
    ld bc, SNAKE_INITIAL_TAIL_ADDRESS

    ; set second item in wSnakeBodyPositions array
    inc hl
    ld [hl], b
    inc hl
    ld [hl], c

    ; decrement by 1 to go to start of second item in array
    dec hl
    call SaveAddressOfLastSnakeBodyPart
    
    ret
  
MoveSnakePosition:
    ; Load framecounter and only make the snake move every 15 frames
    ld a, [wFrameCounter]
    inc a
    ld [wFrameCounter], a
    ld b, a
    ld a, [wSnakeSpeed]
    cp a, b ; Every x frames, run the following code
    jp nz, MoveHeadPositionSkip
    ; Reset the frame counter back to 0
    ld a, 0
    ld [wFrameCounter], a

    ; TODO Move this into "method"? and call it?
    ; Set background tile on which the head is at to snakebody
    call GetSnakeHeadTileAddress

    ; TODO Check if on head tile was an apple?
    ; Or check if the next tile to which head is moving is an apple?
    ld a, [hl]
    cp a, APPLE_TILE_ID
    jp z, EatApple
    jp DontEatApple

EatApple:
    ; Add one body part to snake
    call AddBodyPartItem
    call GetSnakeHeadTileAddress
    ; TODO Problem now is that there is nothing on that last tile
    ; so the tail check will not match any tail and lock up
    ; - I could copy the last two items down and then it would probably work
    ; - I have to copy both because the tail check also checks the item bofore the tail itself
    ; or
    ; - I tried jumping to the copy loop but that jumped over the head movement
    ; - I have to only jump the tail check and setting - make the stuff i need methods
    ;   and call them?

DontEatApple:

    ; Set background to snake body tile
    ; Depending on which direction snake is moving

    ld a, [wSnakeDirection]
    cp a, SNAKE_MOVE_NONE
    jp z, MoveHeadPositionSkip

    call SetBackgroundSnakeTile
    call SaveNewPositionToBodyArray
    call LoadLastSnakeBodyPositionAddress
    ; loop and move all addresse one down overriting the last one
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
    jp DebugLoop

MoveLeft:
    ld a, -1 * TILE_SIZE
    ld hl, SNAKE_HEAD_POS_X_ADDRESS
    call MoveSnakePositionByPixel
    ld a, SNAKE_HEAD_LEFT_TILE_ID
    call UpdateSnakeHeadTileId
    jp MoveHeadPositionEnd

MoveRight:
    ld a, 1 * TILE_SIZE
    ld hl, SNAKE_HEAD_POS_X_ADDRESS
    call MoveSnakePositionByPixel
    ld a, SNAKE_HEAD_RIGHT_TILE_ID
    call UpdateSnakeHeadTileId
    jp MoveHeadPositionEnd

MoveUp:
    ld a, -1 * TILE_SIZE
    ld hl, SNAKE_HEAD_POS_Y_ADDRESS
    call MoveSnakePositionByPixel
    ld a, SNAKE_HEAD_UP_TILE_ID
    call UpdateSnakeHeadTileId
    jp MoveHeadPositionEnd

MoveDown:
    ld a, 1 * TILE_SIZE
    ld hl, SNAKE_HEAD_POS_Y_ADDRESS
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
    ld hl, SNAKE_HEAD_TILE_ID_ADDRESS
    ld [hl], a
    ret

; loop and move all addresse one down overriding the last one
; @param hl: the address of the last snake body position
MoveSnakeBody:
    call SetNewSnakeTail

    call MoveArrayItemsLoop

    ret

DebugLoop:
    jp DebugLoop

; ; Checks if a brick was collided with and breaks it if possible.
; ; @param hl: address of tile.
; CheckAndHandleBrick:
;     ld a, [hl]
;     cp a, BRICK_LEFT
;     jr nz, CheckAndHandleBrickRight
;     ; Break a brick from the left side.
;     ld [hl], BLANK_TILE
;     inc hl
;     ld [hl], BLANK_TILE
; CheckAndHandleBrickRight:
;     cp a, BRICK_RIGHT
;     ret nz
;     ; Break a brick from the right side.
;     ld [hl], BLANK_TILE
;     dec hl
;     ld [hl], BLANK_TILE
;     ret

; Get the tilemap address of the background tile
; on which the snake head currently is
; @return hl: tile address
GetSnakeHeadTileAddress:
    ld a, [SNAKE_HEAD_POS_X_ADDRESS]
    ; Offset 8 because object position top left corner is not (0,0)
    sub a, OBJECT_OFFSET_X
    ld b, a
    ld a, [SNAKE_HEAD_POS_Y_ADDRESS]
    ; Offset 16 because object position top left corner is not (0,0)
    sub a, OBJECT_OFFSET_Y
    ld c, a
    call GetTileByPixel
    ret

; Save the last snake body position address hl into wSnakeLastBodyPositionAddress
; @return hl: address of last body position
SaveAddressOfLastSnakeBodyPart:
    ld a, h
    ld [wSnakeLastBodyPositionAddress], a
    ld a, l
    ld [wSnakeLastBodyPositionAddress + 1], a
    ret

; Load the last snake body position address into hl
; @return hl: address of last body position
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
    inc [hl]
    inc [hl]
    ret

; Set empty background tile to last position
; @param bc: contains the address in the tilemap
SetEmptyBackgroundTileToLastPosition:
    ld a, EMPTY_TILE_ID
    ; TODO For testing: This sets the last tile to snake body vertiaal
    ;ld a, SNAKE_BODY_VERTICAL_TILE_ID
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

    ; Read tile id from tile before tail
    ld a, [bc]

    ; undo changes to hl
    inc hl
    inc hl
    inc hl
    ret

; @param hl: the address of the last snake body position
SetNewSnakeTail:
    ; Get address pointed to by hl
    ld b, [hl]
    inc hl
    ld c, [hl]
    ; bc contains address of last tile in tilemap

    ; Check what tile id the tail on last tile is
    ld a, [bc]
    
    cp a, SNAKE_TAIL_LEFT_TILE_ID
    jp z, SnakeTailWasLeft

    cp a, SNAKE_TAIL_RIGHT_TILE_ID
    jp z, SnakeTailWasRight

    cp a, SNAKE_TAIL_DOWN_TILE_ID
    jp z, SnakeTailWasDown

    cp a, SNAKE_TAIL_UP_TILE_ID
    jp z, SnakeTailWasUp

    ; This should never happen -> hang
    jp DebugLoop

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
    jp DebugLoop

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
    jp DebugLoop

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
    jp DebugLoop

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
    jp DebugLoop

SetLeftTail:
    ld a, SNAKE_TAIL_LEFT_TILE_ID
    ld [bc], a
    jp SetTailTileEnd

SetRightTail:
    ld a, SNAKE_TAIL_RIGHT_TILE_ID
    ld [bc], a
    jp SetTailTileEnd

SetDownTail:
    ld a, SNAKE_TAIL_DOWN_TILE_ID
    ld [bc], a
    jp SetTailTileEnd

SetUpTail:
    ld a, SNAKE_TAIL_UP_TILE_ID
    ld [bc], a
    jp SetTailTileEnd

SetTailTileEnd:
    ret

; Set background on which the snake head is to
; the correct next body tile id
; @param hl: tilemap address of the background tile
SetBackgroundSnakeTile:
    ld a, [wPreviousSnakeDirection]

    cp a, SNAKE_MOVE_LEFT
    jp z, MovingFromLeftDirection
    
    cp a, SNAKE_MOVE_RIGHT
    jp z, MovingFromRightDirection

    cp a, SNAKE_MOVE_UP
    jp z, MovingFromUpDirection

    cp a, SNAKE_MOVE_DOWN
    jp z, MovingFromDownDirection
    
    jp DebugLoop

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
    ld hl, wSnakeBodyPositions
    ld [hl], d
    inc hl
    ld [hl], e
    
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
    ld bc, wSnakeBodyPositions + 1
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

; Convert a pixel position to a tilemap address
; hl = _SCRN0 + X + Y * 32
; @param b: X
; @param c: Y
; @return hl: tile address
GetTileByPixel:
    ; First, we need to divide by 8 to convert a pixel position to a tile position.
    ; After this we want to multiply the Y position by 32.
    ; These operations effectively cancel out so we only need to mask the Y value.
    ld a, c
    and a, %11111000
    ld l, a
    ld h, 0
    ; Now we have the position * 8 in hl
    add hl, hl ; position * 16
    add hl, hl ; position * 32
    ; Convert the X position to an offset.
    ld a, b
    srl a ; a / 2
    srl a ; a / 4
    srl a ; a / 8
    ; Add the two offsets together.
    add a, l
    ld l, a
    adc a, h
    sub a, l
    ld h, a
    ; Add the offset to the tilemap's base address, and we are done!
    ld bc, _SCRN0
    add hl, bc
    ret

; @param a: tile ID
; @return z: set if a is a wall.
IsWallTile:
    ; TODO Use correct Tile IDs
    cp a, $00
    ret z
    cp a, $01
    ret z
    cp a, $02
    ret z
    cp a, $04
    ret z
    cp a, $05
    ret z
    cp a, $06
    ret z
    cp a, $07
    ret

; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length
Memcopy:
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or a, c
    jp nz, Memcopy
    ret

BackgroundTiles: INCBIN "gfx/background.2bpp"
BackgroundTilesEnd:

BackgroundTilemap: INCBIN "gfx/background.tilemap"
BackgroundTilemapEnd:

SnakeBodyData: INCBIN "gfx/snake_body.2bpp"
SnakeBodyDataEnd:

AppleData: INCBIN "gfx/apple.2bpp"
AppleDataEnd:

SnakeHeadData: INCBIN "gfx/snake_head.2bpp"
SnakeHeadDataEnd:

; WRAM

SECTION "Counter", WRAM0
wFrameCounter: db

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db

SECTION "Snake Head Direction", WRAM0
wSnakeDirection: db
wPreviousSnakeDirection: db

SECTION "Snake Speed", WRAM0
wSnakeSpeed: db

; 20*18 = 360 possible tile positions
; Contains the addresses of the tiles in the tilemap on which a body part is
; Each address needs 2 bytes so 360 * 2 bytes = 720 bytes
SECTION "Snake Body Positions", WRAM0
wSnakeBodyPositions: ds 720

; Contains the address of the last snake body part in wSnakeBodyPositions
; (pointer to last snake body part)
; If I use this instead of snake size i can directly load the last address
wSnakeLastBodyPositionAddress: dw
