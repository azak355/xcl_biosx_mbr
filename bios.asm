[ORG 0x7C00]        ; This sets the location where the code will be loaded (MBR)

; Initial Code - Set up a basic screen output
mov ah, 0x0E         ; BIOS teletype output function (to print text)
mov al, 'H'          ; Print 'H'
int 0x10             ; Call BIOS interrupt to display character
mov al, 'e'          ; Print 'e'
int 0x10

; You can add more characters to print a message

; Infinite loop (after printing)
jmp $

; Padding with zeroes to reach 510 bytes (MBR space before the signature)
times 510 - ($ - $$) db 0

; Boot signature at the end of the MBR
dw 0xAA55
; Check the first partition's boot flag at 0x1BE
mov si, 0x1BE
mov al, [si]  ; Read the bootable flag (0x80 indicates a bootable partition)
cmp al, 0x80
jne no_bootable_partition

; If bootable, jump to loading bootloader
jmp load_bootloader

no_bootable_partition:
; Handle no bootable partition found (error message, etc.)
; Read sector from disk (using BIOS interrupt 0x13)
mov ah, 0x02   ; BIOS read sector function
mov al, 1      ; Number of sectors to read
mov ch, 0      ; Track 0 (first track)
mov cl, 2      ; Sector number (2, for the second sector, e.g., bootloader)
mov dh, 0      ; Head 0
mov dl, 0x80   ; Disk drive 0x80 (first hard drive)
int 0x13       ; Call BIOS interrupt 0x13 to read the sector

; Jump to the loaded bootloader (if successful)
jmp 0x0000:0x7C00
mov ah, 0x00      ; Function 0x00: Set video mode
mov al, 0x13      ; Mode 13h: 320x200, 256 colors
int 0x10          ; Call BIOS interrupt 0x10 to change video mode
; Function to plot a pixel at (x, y) in mode 13h
PlotPixel:
    ; Input:  cx = x, dx = y, al = color index
    ; Video memory begins at 0xA0000, 320 pixels per line
    ; Calculate memory location:
    mov ax, 0xA000    ; Video memory start
    mov bx, dx        ; bx = y (height)
    mov cx, 320       ; 320 pixels per row
    mul cx            ; ax = y * 320
    add ax, cx        ; ax = ax + x (x coordinate)
    mov di, ax        ; di = screen address
    mov es, 0xA000    ; es points to video memory
    mov [es:di], al   ; plot pixel with color al
    ret

; Function to display "X"
DisplayX:
    ; Call PlotPixel for each pixel of "X" bitmap
    ; Example of how we might call PlotPixel for a character:
    ; (In real usage, you’d have a bitmap that you use)
    ; Here we simply plot random pixels for demonstration.
    ; Normally, you'd loop through your font data and plot pixels.

    ; Example: Plotting 3 pixels for 'X'
    mov cx, 10       ; x position
    mov dx, 10       ; y position
    mov al, 0x0F     ; color (white)
    call PlotPixel

    ; Repeat for more pixels of "X"...
    ret

; Main Program Entry Point
Start:
    ; Set the video mode to 13h (320x200, 256 colors)
    mov ah, 0x00
    mov al, 0x13
    int 0x10

    ; Display "X" at position (10,10)
    call DisplayX

    ; Display "C" at position (50,10)
    call DisplayC

    ; Display "L" at position (90,10)
    call DisplayL

    ; Infinite loop to keep the screen displayed
    jmp $
; Character 'X' bitmap example (8x8 grid)
; Each byte represents a row, 8 bits for each row of pixels
XBitmap:
    db 0x81, 0xC3, 0x63, 0x33, 0x33, 0x63, 0xC3, 0x81 ; Example bitmap for "X"
DisplayXCL:
    ; Display 'X'
    mov cx, 10        ; x position for 'X'
    mov dx, 10        ; y position for 'X'
    lea si, XBitmap   ; Load address of "X" bitmap
    call DisplayCharacter

    ; Display 'C' (similarly, you would define a bitmap for C)
    mov cx, 30        ; x position for 'C'
    lea si, CBitmap
    call DisplayCharacter

    ; Display 'L' (similarly, you would define a bitmap for L)
    mov cx, 50        ; x position for 'L'
    lea si, LBitmap
    call DisplayCharacter

    ret
; Switch to VGA mode 13h (320x200, 256 colors)
mov ah, 0x00
mov al, 0x13  ; 0x13 = VGA mode 320x200 256 colors
int 0x10      ; BIOS interrupt 0x10 to set the video mode
; Function to display text at a given x, y position
DisplayText:
    ; Input: cx = x position, dx = y position, si = pointer to text string
    mov ah, 0x0E    ; BIOS teletype function (display character)
DisplayLoop:
    mov al, [si]    ; Get the current character
    cmp al, 0       ; If null terminator, end the string
    je Done
    mov bh, 0       ; Page number
    mov bl, 0x07    ; Text color (light gray on black)
    int 0x10        ; Display the character
    inc si          ; Move to the next character
    inc cx          ; Move the x position
    jmp DisplayLoop
Done:
    ret
; Wait for a key press and store the ASCII value in AL
WaitForKey:
    mov ah, 0x00       ; BIOS function to read keyboard input
    int 0x16           ; BIOS interrupt for keyboard input
    ret
; Read the boot sector of the selected partition
ReadBootSector:
    ; Parameters for BIOS interrupt 0x13
    ; AH = 0x02 (read sectors)
    ; AL = 1 (number of sectors)
    ; CH = track (0 for the first track)
    ; CL = sector (usually 1 for the first sector)
    ; DH = head (0 for the first head)
    ; DL = drive (0x80 for the first hard disk)
    
    mov ah, 0x02       ; Read sector function
    mov al, 0x01       ; Read 1 sector
    mov ch, 0x00       ; Track 0
    mov cl, 0x01       ; Sector 1 (boot sector)
    mov dh, 0x00       ; Head 0
    mov dl, 0x80       ; Disk drive 0x80 (first hard disk)
    int 0x13           ; Call BIOS interrupt 0x13 to read the sector

    ; Jump to the loaded boot sector
    jmp 0x0000:0x7C00
; Handle key input to navigate the menu
HandleInput:
    call WaitForKey     ; Wait for key press
    cmp al, '1'         ; If '1' key pressed
    je BootPartition1
    cmp al, '2'         ; If '2' key pressed
    je BootPartition2
    cmp al, '3'         ; If '3' key pressed
    je BootFromUSB
    cmp al, '4'         ; If '4' key pressed
    je ExitMenu
    ret
; Exit the menu and reboot the system
ExitMenu:
    mov ax, 0x0E00    ; System reset code
    int 0x19          ; BIOS interrupt to reset the system
    ret
; Store the password in a reserved disk sector (simplified)
SetPassword:
    ; Display a prompt asking the user to enter a password
    ; (You will need to render the message here)
    call DisplayPrompt

    ; Wait for the user to input the password (You can use a function to read input)
    call GetUserPassword

    ; Write the password to a reserved sector on the disk
    ; (In a real-world scenario, use BIOS interrupt 0x13 to write data to a disk sector)
    ; This example assumes a reserved sector for simplicity.
    call WritePasswordToDisk

    ; After the password is set, display a confirmation message
    call DisplayPasswordSetMessage

    ; Continue with normal boot
    jmp NormalBoot
; Get the user input (password)
GetUserPassword:
    ; Allocate a buffer to store the password (e.g., buffer at 'UserPassword')
    ; Use BIOS interrupt 0x16 to capture each key
    ; For simplicity, assume the user enters a password of fixed length
    ; (Here we assume the buffer for the password is already set up)
    ; Continue reading characters until a newline or Enter is pressed

    ; Wait for key press
    mov ah, 0x00       ; BIOS function to read key
    int 0x16           ; Interrupt to read the key from the keyboard
    ; Store the key in the password buffer
    ; Repeat for each character entered until "Enter" is pressed
    ret
; Check if the password is already set
CheckPassword:
    ; Read the reserved disk sector where the password is stored
    ; (Assume the password is stored in sector 1)
    mov ah, 0x02       ; BIOS function to read a sector
    mov al, 0x01       ; Read one sector
    mov ch, 0x00       ; Track 0
    mov cl, 0x01       ; Sector 1
    mov dh, 0x00       ; Head 0
    mov dl, 0x80       ; Disk drive 0x80 (first hard disk)
    lea si, [StoredPassword] ; Point SI to where we will store the password
    int 0x13           ; Read the sector from disk
    ; Now compare the entered password with the stored password
    call PromptForPassword
    call ComparePassword
    je BootSystem       ; If passwords match, continue booting
    call DisplayError   ; If password is incorrect, display error
    jmp $

; Compare the entered password with the stored password
ComparePassword:
    ; Compare the entered password (from buffer) with the stored password
    ; Return with Zero Flag set (ZF=1) if passwords match
    ; (You will need to compare byte by byte)
    ret
PromptForPassword:
    ; Display prompt for password (e.g., "Enter Password:")
    ; Code to render the prompt here
    ret

DisplayError:
    ; Display "Incorrect password" message here
    ; Then halt or prompt for password again
    ret
BootSystem:
    ; Jump to the bootloader or OS loader
    jmp 0x0000:0x7C00  ; Jump to the bootloader code
section .data
    menu_title db "BIOS Configuration", 0
    option1 db "1. Set Boot Device Order", 0
    option2 db "2. Set Master Password", 0
    option3 db "3. Display System Info", 0
    option4 db "4. Exit", 0
    prompt db "Enter selection (1-4):", 0

section .bss
    user_input resb 1

section .text
    global _start
    _start:

    ; Display menu title
    call DisplayMenuTitle
    ; Display menu options
    call DisplayMenuOptions
    ; Prompt user for selection
    call DisplayPrompt
    ; Wait for user input (1-4)
    call GetUserInput
    ; Handle user input
    call HandleMenuSelection

    ; Hang or loop
    jmp $

DisplayMenuTitle:
    ; Display "BIOS Configuration"
    mov ah, 0x0E           ; BIOS function: teletype output
    mov al, [menu_title]    ; Load the first byte of the title
    int 0x10               ; Call BIOS interrupt to display the character
    ret

DisplayMenuOptions:
    ; Display each menu option
    ; 1. Set Boot Device Order
    call PrintString, option1
    ; 2. Set Master Password
    call PrintString, option2
    ; 3. Display System Info
    call PrintString, option3
    ; 4. Exit
    call PrintString, option4
    ret

PrintString:
    ; Print string at address passed in 'a'
    mov si, [esp + 4]     ; Get address of string
.loop:
    mov al, [si]          ; Load byte from string
    or al, al             ; Check if it's the null terminator
    jz .done              ; If it's null, we're done
    mov ah, 0x0E          ; BIOS function: teletype output
    int 0x10              ; Print character
    inc si                ; Move to next character
    jmp .loop
.done:
    ret

DisplayPrompt:
    ; Display prompt: "Enter selection (1-4):"
    call PrintString, prompt
    ret

GetUserInput:
    ; Wait for user input (1-4)
    mov ah, 0x00           ; BIOS function to read a key
    int 0x16               ; Call BIOS interrupt to read a key
    mov [user_input], al   ; Store the user's input
    ret

HandleMenuSelection:
    ; Read user input (1-4) and jump to appropriate function
    mov al, [user_input]
    cmp al, '1'            ; Compare with '1'
    je SetBootDeviceOrder
    cmp al, '2'            ; Compare with '2'
    je SetMasterPassword
    cmp al, '3'            ; Compare with '3'
    je DisplaySystemInfo
    cmp al, '4'            ; Compare with '4'
    je ExitBIOS
    ret

SetBootDeviceOrder:
    ; Implement setting boot device order here
    ; (This would modify the boot sequence)
    call PrintString, "Setting Boot Device Order"
    ret

SetMasterPassword:
    ; Implement setting master password here
    call PrintString, "Setting Master Password"
    ret

DisplaySystemInfo:
    ; Display basic system info (like CPU, RAM, etc.)
    call PrintString, "Displaying System Information"
    ret

ExitBIOS:
    ; Exit the BIOS setup (exit to boot)
    mov ah, 0x4C           ; BIOS function: exit
    int 0x21               ; Terminate program
    ret
StoreBootDeviceOrder:
    ; Write the boot device order to a reserved disk sector (sector 2 for example)
    mov ah, 0x03       ; BIOS function to write a sector
    mov al, 0x01       ; Write one sector
    mov ch, 0x00       ; Track 0
    mov cl, 0x02       ; Sector 2 (reserved sector for boot order)
    mov dh, 0x00       ; Head 0
    mov dl, 0x80       ; Disk drive 0x80 (first hard disk)
    lea si, [BootOrder] ; Point SI to boot order data
    int 0x13           ; Write to the disk
    ret
LogEvent:
    ; Input: SI = pointer to string
    ; Writes log string to a reserved memory buffer

    pusha
    mov di, log_buffer_ptr  ; log_buffer_ptr points to next free spot in buffer
.write_loop:
    lodsb                   ; Load byte from string at SI
    or al, al
    jz .done
    stosb                   ; Store byte in memory at ES:DI
    jmp .write_loop
.done:
    mov log_buffer_ptr, di  ; Update pointer
    popa
    ret
    mov ah, 0x03       ; Write sectors
    mov al, 1          ; One sector
    mov ch, 0          ; Track 0
    mov cl, 3          ; Sector 3 (log storage)
    mov dh, 0          ; Head 0
    mov dl, 0x80       ; First HDD
    mov bx, log_buffer
    int 0x13
int 0x16           ; Wait for key
cmp al, 0x85       ; F12 = scancode 0x85
jne normal_boot
call StartUpdate
mov ah, 0x02         ; BIOS read sectors
mov al, 10           ; Read 10 sectors (example)
mov ch, 0            ; Cylinder 0
mov cl, 2            ; Start at sector 2
mov dh, 0            ; Head 0
mov dl, 0x80         ; Drive 0 (HDD)
mov bx, 0x8000       ; Load at 0x8000
int 0x13
mov si, 0x8000
xor ax, ax
mov cx, filesize     ; Total bytes - 4
.loop:
    lodsb
    add al, ah
    mov ah, al
    loop .loop

; Read expected checksum
mov si, 0x8000 + filesize - 4
lodsd
cmp eax, expected_checksum
jne bad_checksum
mov si, 0x8000         ; Source buffer
mov di, flash_base     ; Flash memory base (e.g., 0xFFF00000)
mov cx, firmware_size

.write_loop:
    lodsb
    mov [di], al       ; Store byte to flash-mapped region
    inc di
    loop .write_loop
; Clear BIOS Write Enable bit
mov dx, 0x0CF8
mov eax, 0x800000DC
out dx, eax
mov dx, 0x0CFC
in al, dx
and al, 0xFE           ; Clear bit 0
out dx, al
mov ax, 0x40
mov ds, ax
mov word [0x72], 0x1234  ; Set reboot flag
jmp 0xFFFF:0x0000        ; Hard reboot
call check_f4_key
cmp al, 1
je open_bios_menu
jmp continue_boot

check_f4_key:
    xor ah, ah         ; Function 00h - Read keystroke (blocks)
    int 0x16
    cmp ah, 0x3E       ; F4 = 0x3E (scan code)
    jne .not_f4
    mov al, 1
    ret
.not_f4:
    xor al, al
    ret
open_bios_menu:
    call clear_screen
    call draw_menu
    call wait_for_selection
    jmp continue_boot

clear_screen:
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov cx, 2000
    mov ax, 0x0720     ; Space char, white-on-black
    rep stosw
    ret
draw_menu:
    mov si, menu_title
    call print_string
    ret

menu_title db "Custom BIOS Setup Menu", 0

print_string:
    mov ax, 0xB800
    mov es, ax
    xor di, di
.print_loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x07
    stosw
    jmp .print_loop
.done:
    ret
wait_for_selection:
.wait:
    mov ah, 0           ; Wait for key
    int 0x16
    cmp ah, 0x01        ; Esc
    je .exit
    cmp ah, 0x1C        ; Enter
    je .select
    jmp .wait
.select:
    ; Handle selected option (e.g. Boot Order, Password)
    jmp wait_for_selection
.exit:
    ret
mov al, 0x10         ; CMOS offset
out 0x70, al
mov al, 0x42         ; Example value
out 0x71, al
start:
    cli                  ; Clear interrupts
    call clear_screen
    call display_banner
    call run_post_tests
    jmp boot_continue
run_post_tests:
    call test_video
    jc error_video

    call test_keyboard
    jc error_keyboard

    call test_memory
    jc error_memory

    ret

error_video:
    mov si, msg_video_error
    call print_error
    jmp halt_system

error_keyboard:
    mov si, msg_keyboard_error
    call print_error
    jmp halt_system

error_memory:
    mov si, msg_memory_error
    call print_error
    jmp halt_system
test_video:
    mov ah, 0x0F         ; Get video mode
    int 0x10
    cmp al, 0            ; AL will be zero if video not initialized
    stc                 ; Set carry if failed
    ret
test_keyboard:
    xor ah, ah
    int 0x16
    cmp ah, 0            ; AH = scan code
    stc
    je .ok
    clc
.ok:
    ret
test_memory:
    mov di, 0x1000
    mov ax, 0xABCD
    mov [di], ax
    cmp [di], ax
    jne .fail
    clc
    ret
.fail:
    stc
    ret
print_error:
    call clear_screen
    call print_string
    ret

print_string:
    mov ax, 0xB800
    mov es, ax
    xor di, di
.next_char:
    lodsb
    or al, al
    jz .done
    mov ah, 0x04        ; Red-on-black
    stosw
    jmp .next_char
.done:
    ret
halt_system:
    cli
.hang:
    hlt
    jmp .hang
msg_video_error db "ERROR: Video hardware not responding", 0
msg_keyboard_error db "ERROR: No keyboard detected", 0
msg_memory_error db "ERROR: RAM failed test", 0
start:
    cli
    call clear_screen
    call check_security
    jmp continue_boot
check_security:
    call check_cmos_integrity
    jc security_halt

    call check_password
    jc security_halt

    call check_bootloader_checksum
    jc security_halt

    ret
	check_cmos_integrity:
    mov al, 0x0E        ; Custom register
    out 0x70, al
    in al, 0x71
    cmp al, 0xA5        ; Expected value
    jne .fail
    clc
    ret
.fail:
    stc
    ret
check_bootloader_checksum:
    mov si, 0x7C00      ; Bootloader location
    xor ax, ax
    mov cx, 512
.loop:
    lodsb
    add ah, al
    loop .loop
    cmp ah, expected_sum
    jne .fail
    clc
    ret
.fail:
    stc
    ret
security_halt:
    call clear_screen
    mov si, sec_error_msg
    call print_string
    jmp halt_forever

sec_error_msg db "!!! BIOS SECURITY VIOLATION DETECTED !!!", 0
read_pci_byte:
    ; Input:
    ;   BH = bus (usually 0)
    ;   BL = device (e.g., 0x1F)
    ;   DL = function (usually 0)
    ;   DH = register offset (e.g., 0xDC)
    ; Output:
    ;   AL = value read

    push eax
    push edx

    ; Build config address: 0x80000000 | (bus << 16) | (device << 11) | (function << 8) | (offset & 0xFC)
    mov eax, 0x80000000
    movzx ecx, bh         ; bus
    shl ecx, 16
    or eax, ecx
    movzx ecx, bl         ; device
    shl ecx, 11
    or eax, ecx
    movzx ecx, dl         ; function
    shl ecx, 8
    or eax, ecx
    movzx ecx, dh         ; reg offset
    and ecx, 0xFC
    or eax, ecx

    mov dx, 0xCF8
    out dx, eax           ; send config address

    mov dx, 0xCFC
    in eax, dx            ; read 32-bit value

    ; Extract byte from EAX
    movzx ecx, dh
    and ecx, 3
    shr eax, cl
    and eax, 0xFF
    mov al, al

    pop edx
    pop eax
    ret
check_flash_protection:
    mov bh, 0x00     ; Bus 0
    mov bl, 0x1F     ; Device 31
    mov dl, 0x00     ; Function 0
    mov dh, 0xDC     ; Register 0xDC (BIOS_CNTL)

    call read_pci_byte

    test al, 0x01    ; BIOSWE
    jz .ok           ; If BIOSWE is 0, OK

    test al, 0x02    ; BLE
    jnz .ok          ; If BLE is 1, OK

    jmp flash_vuln_detected
.ok:
    ret
flash_vuln_detected:
    call clear_screen
    mov si, msg_flash_unlocked
    call print_string
    jmp halt_forever

msg_flash_unlocked db "FATAL: BIOS FLASH WRITE ENABLED AND UNLOCKED!", 0
check_os_integrity:
    mov si, 0x7C00      ; Load bootloader area
    mov cx, 512
    xor ax, ax
.sum_loop:
    lodsb
    add ah, al
    loop .sum_loop
    cmp ah, expected_sum
    jne os_security_halt
    ret
os_security_halt:
    call clear_screen
    mov si, sec_msg
    call print_string

    call enter_password
    jc wrong_password

    call reset_security_flags
    ret

wrong_password:
    mov si, sec_fail_msg
    call print_string
    jmp halt_forever
enter_password:
    mov si, password_prompt
    call print_string

    mov di, user_input
    mov cx, 8
.read_loop:
    call read_key
    stosb
    loop .read_loop
    mov byte [di], 0

    ; Compare input to master
    mov si, user_input
    mov di, master_password
    call strcmp
    jc .fail
    clc
    ret
.fail:
    stc
    ret
strcmp:
.loop:
    lodsb
    scasb
    jne .notequal
    or al, al
    jne .loop
    clc
    ret
.notequal:
    stc
    ret
reset_security_flags:
    ; CMOS example
    mov al, 0x30         ; CMOS security byte
    out 0x70, al
    mov al, 0x00         ; Clear security flag
    out 0x71, al
    ret
SMM_Handler:
    ; Check OS memory, drivers, I/O ports, etc.
    call check_runtime_security
    jc security_violation
    iret

security_violation:
    ; Halt or reset system
    cli
.loop:
    hlt
    jmp .loop
start_post:
    call check_cpu
    call check_ram
    call init_display
    call check_keyboard
    call check_storage
    jmp continue_boot
check_ram:
    mov si, 0x1000
    mov cx, 100
.loop:
    mov word [si], 0xAA55
    cmp word [si], 0xAA55
    jne ram_error
    add si, 2
    loop .loop
    ret

ram_error:
    mov si, ram_fail_msg
    call print_string
    jmp halt_forever
; Assuming SHA1 of data is already in a buffer
; TPM I/O base usually at 0xE0 - 0xEF or 0xE4
; Send "Extend" command to TPM

tpm_extend:
    ; Construct command buffer
    ; Write to TPM register interface
    ; Poll TPM_STS until ready
    ; Handle response
    ret
; BIOS Boot Logging System in Assembly (NASM syntax)

org 0x7C00              ; BIOS boot sector location

section .text

start:
    cli                 ; Disable interrupts during init
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; Initialize serial port (COM1: 0x3F8)
    call init_serial

    ; Begin POST logging
    call log_msg_booting
    call check_ram
    call check_cpu
    call check_keyboard
    call check_storage

    ; If all good
    call log_msg_ready
    jmp bootloader_load

; --------------------------
; LOGGING ROUTINES
; --------------------------
log_msg_booting:
    mov si, msg_booting
    call print_log
    ret

log_msg_ready:
    mov si, msg_ready
    call print_log
    ret

log_error:
    ; AL = error code
    ; Message in SI
    call print_log
    hlt_loop:
        hlt
        jmp hlt_loop

print_log:
    ; Send string [SI] to serial + screen
.print:
    lodsb
    or al, al
    jz .done
    call print_char_serial
    call print_char_screen
    jmp .print
.done:
    ret

print_char_serial:
    ; Send AL to COM1
.wait:
    in al, 0x3FD          ; Line status
    test al, 0x20
    jz .wait
    mov dx, 0x3F8
    out dx, al
    ret

print_char_screen:
    ; Print AL to screen using teletype BIOS
    mov ah, 0x0E
    int 0x10
    ret

; --------------------------
; INIT SERIAL PORT
; --------------------------
init_serial:
    mov dx, 0x3F8
    mov al, 0x00         ; Disable interrupts
    out dx, al
    mov dx, 0x3FB
    mov al, 0x80         ; Enable DLAB
    out dx, al
    mov dx, 0x3F8
    mov al, 0x03         ; 38400 baud
    out dx, al
    mov dx, 0x3F9
    mov al, 0x00
    out dx, al
    mov dx, 0x3FB
    mov al, 0x03         ; 8N1
    out dx, al
    ret

; --------------------------
; HARDWARE CHECKS (POST)
; --------------------------
check_ram:
    mov si, msg_check_ram
    call print_log
    mov di, 0x1000
    mov cx, 16
.ram_test:
    mov word [di], 0xAA55
    cmp word [di], 0xAA55
    jne ram_fail
    add di, 2
    loop .ram_test
    ret
ram_fail:
    mov si, msg_ram_fail
    call log_error

check_cpu:
    mov si, msg_check_cpu
    call print_log
    ; (Assume OK for simplicity)
    ret

check_keyboard:
    mov si, msg_check_kbd
    call print_log
    ; (Assume OK for simplicity)
    ret

check_storage:
    mov si, msg_check_storage
    call print_log
    ; (Assume OK for simplicity)
    ret

; --------------------------
; BOOTLOADER LOAD
; --------------------------
bootloader_load:
    ; Continue normal boot (placeholder)
    cli
    hlt

; --------------------------
; DATA SEGMENT
; --------------------------
section .data
msg_booting        db "[BIOS] Starting POST...", 0
msg_ready          db "[BIOS] System Ready.", 0
msg_check_ram      db "[BIOS] Testing RAM...", 0
msg_check_cpu      db "[BIOS] Checking CPU...", 0
msg_check_kbd      db "[BIOS] Checking Keyboard...", 0
msg_check_storage  db "[BIOS] Checking Storage...", 0
msg_ram_fail       db "[BIOS] RAM Test Failed!", 0

times 510-($-$$) db 0
    dw 0xAA55       ; Boot signature
check_input:
    mov ah, 0x00
    int 0x16        ; wait for key
    cmp al, '1'
    je audio_menu
    cmp al, '2'
    je video_menu
    cmp al, '3'
    je gpu_menu
    jmp check_input
; PCI config space read example (bus 0, device 2, function 0)
mov dx, 0xCF8
mov eax, 0x80000000
out dx, eax
mov dx, 0xCFC
in eax, dx      ; contains vendor/device ID
check_f11_key:
    mov ah, 0x10      ; Extended keyboard read
    int 0x16
    cmp ah, 0x85      ; AH = scan code for F11
    je enter_driver_menu
    ret
enter_driver_menu:
    call clear_screen
    call show_driver_menu
    ; After menu, return to boot process
    ret
wait_key_loop:
    mov ah, 0x00
    int 0x16
    cmp al, 0x85
    je enter_driver_menu
    cmp al, 0x53          ; DEL
    je enter_bios_setup
    jmp wait_key_loop
; Secure Boot System + BIOS Driver Menu (NASM)
org 0x7C00

section .text

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax

    call init_screen
    call check_f11_key
    call load_bootloader
    call hash_bootloader
    call load_signature
    call verify_signature
    jc secure_boot_fail

    call boot_bootloader
    jmp $

secure_boot_fail:
    mov si, msg_fail
    call print_string
    jmp $

; ------------------------------
; F11 HOTKEY DETECTION
; ------------------------------
check_f11_key:
    mov ah, 0x10
    int 0x16
    cmp ah, 0x85        ; Scan code for F11
    je enter_driver_menu
    ret

; ------------------------------
; DRIVER MENU SYSTEM
; ------------------------------
enter_driver_menu:
    call clear_screen
    mov si, driver_menu_title
    call print_string
    call driver_menu_loop
    call clear_screen
    ret

driver_menu_loop:
.next:
    mov si, driver_menu_options
    call print_string
    mov ah, 0x00
    int 0x16
    cmp al, '1'
    je audio_config
    cmp al, '2'
    je video_config
    cmp al, '3'
    je gpu_diagnostics
    cmp al, 27          ; ESC to exit
    je .done
    jmp .next
.done:
    ret

audio_config:
    mov si, msg_audio
    call print_string
    call wait_key
    ret

video_config:
    mov si, msg_video
    call print_string
    call wait_key
    ret

gpu_diagnostics:
    mov si, msg_gpu
    call print_string
    call wait_key
    ret

wait_key:
    mov ah, 0x00
    int 0x16
    ret

; ------------------------------
; Load Bootloader
; ------------------------------
load_bootloader:
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0x80
    mov bx, 0x1000
    int 0x13
    ret

load_signature:
    mov ah, 0x02
    mov al, 2
    mov ch, 0
    mov cl, 3
    mov dh, 0
    mov dl, 0x80
    mov bx, 0x2000
    int 0x13
    ret

hash_bootloader:
    ; Call C SHA-256 implementation on [0x1000:512]
    ret

verify_signature:
    ; Call C RSA verify implementation
    ret

boot_bootloader:
    jmp 0x0000:0x1000

clear_screen:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    mov ah, 0x02
    xor bh, bh
    xor dx, dx
    int 0x10
    ret

print_string:
.next:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .next
.done:
    ret

section .data
msg_fail db "SECURE BOOT FAILED - System Halted", 0
msg_audio db "Audio settings screen (stub). Press any key...", 0
msg_video db "Video config screen (stub). Press any key...", 0
msg_gpu   db "GPU diagnostics (stub). Press any key...", 0
driver_menu_title db "\r\n=== BIOS DRIVER MENU ===\r\n", 0
driver_menu_options db "1. Audio Settings\r\n2. Video Config\r\n3. GPU Diagnostics\r\nESC to Exit\r\n", 0

section .bss

times 510-($-$$) db 0
    dw 0xAA55
	; BIOS Update Procedure in Assembly

; Update BIOS if key combination (e.g., F12) is pressed during boot
check_for_update_key:
    ; Poll keyboard input
    mov ah, 0x10  ; BIOS keyboard input
    int 0x16
    cmp al, 0x3B  ; Check if F12 key was pressed (scan code for F12 is 0x3B)
    je start_bios_update
    ret

start_bios_update:
    ; Prompt user for confirmation
    call prompt_update_confirmation

    ; Load new BIOS image from disk (e.g., floppy, USB)
    call load_bios_image

    ; Validate image (e.g., checksum, size)
    call validate_bios_image

    ; Program flash memory with the new BIOS
    call flash_bios

    ; Verify flash operation
    call verify_flash_update

    ; Notify user about success
    call notify_success

    ret

; Prompt the user to confirm BIOS update
prompt_update_confirmation:
    ; Display confirmation message
    mov si, confirmation_message
    call print_string
    ; Wait for user input
    ret

; Load BIOS image from disk
load_bios_image:
    ; Load the BIOS image from a specific location (e.g., USB or floppy)
    ; This will depend on the hardware and your BIOS filesystem code
    ret

; Validate the BIOS image (e.g., checksum or hash)
validate_bios_image:
    ; Checksum or hash verification logic goes here
    ret

; Write BIOS image to flash memory
flash_bios:
    ; Write the new BIOS image to flash memory
    ; This will involve writing to the specific flash controller on your system
    ret

; Verify the flash operation
verify_flash_update:
    ; Read back from flash memory and compare with the original image
    ; If successful, display "BIOS update successful"
    ret

; Notify the user of success
notify_success:
    ; Display success message
    mov si, success_message
    call print_string
    ret


