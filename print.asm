
print:
    pusha ; the push instructions takes a register and places
        ; it on top of the stack; pusha does the same, but
        ; with all registers.
    
    .loop:
    cmp [bx], byte 0 ; nb: the "byte" here indicates that
        ; comparison has to be made with a byte-sized 0
    je .exit ; if equal (that is, if the string iterator
        ; value [bx] is equal to 0, or in other words if
        ; we have reached the end of string character \0),
        ; exit the function

    ; Else...
    mov ah, 0x0e ; when the interrupt request is issued, it
        ; will look up in the AH register the number of the
        ; desired subfunction (in our case,  teletype
        ; output, or TTY, which prints one character and
        ; advances the cursor)
    mov al, [bx] ; move into AL the character we want to print
    int 0x10 ; software interrup instruction; code 0x10 
        ; handles generic video services requests (reading
        ; and writing pixels to screen)

    inc bx ; increment BX so it points to the next character
    jmp .loop

    .exit:
    popa
    ret

print_hex:
    pusha
    mov cx, 0 ; index counter for the loop

    .loop:
    cmp cx, 4 ; byte-sized numbers have 4 hexadecimal 
        ; characters, so we will only need to loop 4 times
    je .end

    mov ax, dx ; use AX as the working register
    and ax, 0x000f ; get the last digit
    add al, 0x30 ; in ASCII, numbers 0-9 are encoded by
        ; 0x30-0x39, so adding 0x30 to the last digit give
        ; us its ASCII representation...
    cmp al, 0x39
    jle .string_pos
    add al, 7 ; ...but if the digit is A-F, we need to add
        ; an extra 7 (digit A would have made us land at 0x3A,
        ; and 0x3A + 7 = 0x41 which is ASCII A).

    .string_pos:
    mov bx, HEX_OUT + 5 ; position bx at the end of the string
    sub bx, cx ; move bx to the corresponding digit
    mov [bx], al ; copy the ASCII character stored in AL 
        ; before at the string position pointed to by BX
    
    ror dx, 4 ; the ROR instruction rotates the bits to the
        ; left by the number given as operand; for example,
        ; 0x1234 becomes 0x4123, because each hex digit is 4
        ; bits, and right-rotating the last 4 bits makes
        ; them flip over the other side. This allow us to
        ; repeat the loop with the second (then third, then
        ; fourth) digit from the right in the original
        ; number at the last position in the number (so
        ; that the AND operation works as expected).
    add cx, 1
    jmp .loop

    .end:
    mov bx, HEX_OUT
    call print

    popa
    ret

HEX_OUT: db '0x0000', 0

print_nwl:
    ; This function is necessary because classic newline
    ; character '\n' doesn't work (it will simply be printed
    ; as-is with the rest of characters).
    pusha

    mov ah, 0x0e
    mov al, 0x0a ; newline character (\n)
    int 0x10
    mov al, 0x0d ; carriage return (\r; if this is not 
        ; included, the cursor will indeed move on line down,
        ; but on the same column, without returning to the
        ; start of the line)
    int 0x10

    popa
    ret

[bits 32]

VIDEO_MEMORY equ 0xb8000

print_32:
    ; In real mode, we used interrupt instructions to print
    ; characters to the screen because it was simple
    ; -although not the fastest. However, in protected mode
    ; we are not able to access BIOS (because it is written
    ; in 16 bits), so we have to print in a slightly more
    ; complex manner, by accessing the video memory
    ; directly.

    ; The display device in a computer can be configured in
    ; one of two different modes: graphics mode (classic
    ; pixel-by-pixel screen manipulation) and text mode,
    ; where the screen is divided in "character cells", each
    ; of which displays a character from a fixed font set;
    ; by default, the graphics hardware used is VGA (Video
    ; Graphics Array) colour text mode with 80x25
    ; characters. To print some string, one simply needs to
    ; access the video memory, which is located at 0xb8000.
    pusha
    mov edx, VIDEO_MEMORY

    .loop:
    mov al, [ebx] ; the string is located at EBX, so store
        ; the first character in AL
    mov ah, 0x1f ; text mode memory takes two bytes per
        ; character on screen: one for the actual character,
        ; and one that carries the foreground colour in its
        ; lowest 4 bits and the background colours in the
        ; upper 3 bits (the last bit interpretation
        ; depending on hardware configuration). Here, 0x1f =
        ; 0001'1111b, which corresponds to white (1111) on
        ; blue (001) (yes, the Blue Screen of Death !).
    
    cmp al, 0 ; check against the end of the string
    je .end

    mov [edx], ax ; store the character (AL) and attributes
        ; (AH) combined (AX) at current character cell (EDX)
    add ebx, 1 ; move the string iterator by one character
    add edx, 2 ; move the video memory iterator by two bytes
        ; (one for the character and one for the attributes)

    jmp .loop

    .end:
    popa
    ret