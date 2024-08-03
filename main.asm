INCLUDE "hardware.inc"

; Constants
DEF SNAKE_START_POS_X EQU 10
DEF SNAKE_START_POS_Y EQU 10

DEF SNAKE_MOVE_NONE EQU 0
DEF SNAKE_MOVE_UP EQU 1
DEF SNAKE_MOVE_DOWN EQU 2
DEF SNAKE_MOVE_RIGHT EQU 3
DEF SNAKE_MOVE_LEFT EQU 4

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

    ; Copy the Snake Dot tile
    ; ld de, SnakeDot
    ; ld hl, _VRAM
    ; ld bc, SnakeDotEnd - SnakeDot
    ; call Memcopy

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

    ; Load Background tilemap
    ld de, BackgroundTilemap
    ld hl, _SCRN0
    ld bc, BackgroundTilemapEnd - BackgroundTilemap
    call Memcopy

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
    ld hl, _OAMRAM
    ; TODO Use Position variable Y
    ld a, 128 + 16
    ld [hli], a
    ; TODO Use Position variable X
    ld a, 128 + 8
    ld [hli], a
    ld a, 0
    ld [hli], a
    ld [hli], a

    ; The snake starts in the middle
    ld a, SNAKE_START_POS_X
    ld [wSnakeHeadPosX], a
    ld a, SNAKE_START_POS_Y
    ld [wSnakeHeadPosY], a

    ; Snake is not moving until first key press
    ld a, SNAKE_MOVE_NONE
    ld [wSnakeMovement], a

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
    ld a, SNAKE_MOVE_LEFT
    ld [wSnakeMovement], a
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
    ld a, SNAKE_MOVE_RIGHT
    ld [wSnakeMovement], a
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
    ld a, SNAKE_MOVE_UP
    ld [wSnakeMovement], a
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
    ld a, SNAKE_MOVE_DOWN
    ld [wSnakeMovement], a
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

MoveSnakePosition:
    ; Load framecounter and only make the snake move every 15 frames
    ld a, [wFrameCounter]
    inc a
    ld [wFrameCounter], a
    cp a, 15 ; Every 15 frames (a quarter of a second), run the following code
    jp nz, MoveSnakePositionEnd
    ; Reset the frame counter back to 0
    ld a, 0
    ld [wFrameCounter], a

    ; Add the snake's momentum to its position in OAM.
CheckAndMoveLeft:
    ld a, [wSnakeMovement]
    cp a, SNAKE_MOVE_LEFT
    jp z, MoveLeft

CheckAndMoveRight:
    ld a, [wSnakeMovement]
    cp a, SNAKE_MOVE_RIGHT
    jp z, MoveRight

CheckAndMoveUp:
    ld a, [wSnakeMovement]
    cp a, SNAKE_MOVE_UP
    jp z, MoveUp

CheckAndMoveDown:
    ld a, [wSnakeMovement]
    cp a, SNAKE_MOVE_DOWN
    jp z, MoveDown
    ; No Direction is set, for example at the start of the game
    jp MoveSnakePositionEnd

MoveLeft:
    ; Move x pos by -1 pixel
    ld a, -1
    ld b, a
    ld a, [_OAMRAM + 1]
    add a, b
    ld [_OAMRAM + 1], a
    jp MoveSnakePositionEnd

MoveRight:
    ; Move x pos by 1 pixel
    ld a, 1
    ld b, a
    ld a, [_OAMRAM + 1]
    add a, b
    ld [_OAMRAM + 1], a
    jp MoveSnakePositionEnd

MoveUp:
    ; Move y pos by -1 pixel
    ld a, -1
    ld b, a
    ld a, [_OAMRAM + 0]
    add a, b
    ld [_OAMRAM + 0], a
    jp MoveSnakePositionEnd

MoveDown:
    ; Move y pos by 1 pixel
    ld a, 1
    ld b, a
    ld a, [_OAMRAM + 0]
    add a, b
    ld [_OAMRAM + 0], a
    ;jp MoveSnakePositionEnd

MoveSnakePositionEnd:
    ret

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

; Convert a pixel position to a tilemap address
; hl = $9800 + X + Y * 32
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
    ld bc, $9800
    add hl, bc
    ret

; @param a: tile ID
; @return z: set if a is a wall.
IsWallTile:
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

SnakeDot:
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
    dw `33333333
SnakeDotEnd:

BackgroundTiles: INCBIN "gfx/background.2bpp"
BackgroundTilesEnd:

BackgroundTilemap: INCBIN "gfx/background.tilemap"
BackgroundTilemapEnd:

SnakeBodyData: INCBIN "gfx/snake_body.2bpp"
SnakeBodyDataEnd:

SnakeHeadData: INCBIN "gfx/snake_head.2bpp"
SnakeHeadDataEnd:

; WRAM

SECTION "Counter", WRAM0
wFrameCounter: db

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db

SECTION "Snake Head Position", WRAM0
wSnakeHeadPosX: db
wSnakeHeadPosY: db

SECTION "Snake Head Direction", WRAM0
wSnakeMovement: db
