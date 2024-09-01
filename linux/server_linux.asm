; Simple HTTP Server in x86 Assembly for Linux
; Compile with: nasm -f elf32 server.asm
; Link with: ld -m elf_i386 server.o -o server

section .data
    port dw 9966
    sock dd 0
    client dd 0
    message db "HTTP/1.1 200 OK", 13, 10
            db "Content-Type: text/html", 13, 10
            db "Content-Length: 95", 13, 10, 13, 10
            db "<html><body><h1>Hello, World!</h1>"
            db "<p>This is a simple assembly web server on Linux.</p></body></html>", 0
    msglen equ $ - message
    success_msg db "Success: Server started on port 9966", 10, 0
    accept_msg db "Accepted new connection", 10, 0
    send_msg db "Sent response", 10, 0
    close_msg db "Closed client connection", 10, 0
    error_msg db "Error occurred", 10, 0

section .bss
    sockaddr_in resb 16

section .text
    global _start

_start:
    mov eax, 359    ; sys_socket
    mov ebx, 2      ; AF_INET
    mov ecx, 1      ; SOCK_STREAM
    mov edx, 0      ; protocol
    int 0x80
    mov [sock], eax

    mov word [sockaddr_in], 2    ; AF_INET
    mov word [sockaddr_in + 2], 0x771e  ; port 9966 (network byte order)
    mov dword [sockaddr_in + 4], 0  ; INADDR_ANY

    mov eax, 361    ; sys_bind
    mov ebx, [sock]
    mov ecx, sockaddr_in
    mov edx, 16     ; size of sockaddr_in
    int 0x80

    mov eax, 363    ; sys_listen
    mov ebx, [sock]
    mov ecx, 5      ; backlog
    int 0x80

    mov eax, 4      ; sys_write
    mov ebx, 1      ; stdout
    mov ecx, success_msg
    mov edx, 38     ; length of success_msg
    int 0x80

accept_loop:

    mov eax, 364    ; sys_accept
    mov ebx, [sock]
    mov ecx, 0
    mov edx, 0
    int 0x80
    mov [client], eax

    mov eax, 4
    mov ebx, 1
    mov ecx, accept_msg
    mov edx, 24     ; length of accept_msg
    int 0x80

    mov eax, 4      ; sys_write
    mov ebx, [client]
    mov ecx, message
    mov edx, msglen
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, send_msg
    mov edx, 13     ; length of send_msg
    int 0x80

    mov eax, 6      ; sys_close
    mov ebx, [client]
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, close_msg
    mov edx, 25     ; length of close_msg
    int 0x80

    jmp accept_loop

exit:
    mov eax, 1      ; sys_exit
    xor ebx, ebx    ; status 0
    int 0x80