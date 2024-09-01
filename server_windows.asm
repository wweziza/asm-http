.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\masm32.inc
include \masm32\include\wsock32.inc
include \masm32\include\kernel32.inc
include \masm32\include\user32.inc

includelib \masm32\lib\masm32.lib
includelib \masm32\lib\wsock32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\user32.lib

.data
    port dw 9966
    sock dd 0
    client dd 0
    wsaData db 400 dup(?)
    my_sockaddr db 16 dup(?)
    client_addr db 16 dup(?)
    client_addr_len dd 16
    message db "HTTP/1.1 200 OK", 13, 10
            db "Content-Type: text/html", 13, 10
            db "Content-Length: 512", 13, 10, 13, 10
            db "<html><head><style>"
            db "body { font-family: Arial, sans-serif; background-color: #f4f4f4; }"
            db "h1 { color: #333; }"
            db "p { color: #555; }"
            db "a { color: #1a0dab; text-decoration: none; }"
            db "</style></head>"
            db "<body><h1>Hello, World!</h1>"
            db "<p>This is a simple assembly web server.</p>"
            db "<p>I'm here <a href='https://github.com/wweziza'>GitHub</a>.</p>"
            db "</body></html>", 0
    msglen dd $ - message
    debug_msg db "Debug: %s", 13, 10, 0
    error_msg db "Error: %s (code %d)", 13, 10, 0
    success_msg db "Success: Server started on port 9966", 13, 10, 0
    accept_msg db "Accepted new connection from %d.%d.%d.%d:%d", 13, 10, 0
    send_msg db "Sent response", 13, 10, 0
    close_msg db "Closed client connection", 13, 10, 0
    console_handle dd 0
    bytes_written dd 0
    ip_address db 16 dup(0)
    port_str db 8 dup(0)

.code
print_msg proc uses eax ebx ecx edx, msg:DWORD
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov console_handle, eax
    invoke lstrlen, msg
    invoke WriteConsoleA, console_handle, msg, eax, addr bytes_written, 0
    ret
print_msg endp

start:
    ; Initialize Winsock
    push offset wsaData
    push 101h
    call WSAStartup
    test eax, eax
    jnz wsa_error

    invoke print_msg, addr success_msg

    ; Create socket
    push IPPROTO_TCP
    push SOCK_STREAM
    push AF_INET
    call socket
    mov sock, eax
    cmp eax, INVALID_SOCKET
    je socket_error

    ; Prepare sockaddr_in structure
    mov eax, AF_INET
    mov word ptr [my_sockaddr], ax
    mov ax, port
    xchg ah, al               ; Convert port to network byte order
    mov word ptr [my_sockaddr+2], ax
    xor eax, eax
    mov dword ptr [my_sockaddr+4], eax ; INADDR_ANY

    ; Bind socket
    push 16                 ; size of sockaddr_in
    push offset my_sockaddr
    push sock
    call bind
    test eax, eax
    jnz bind_error

    ; Listen for connections
    push 5
    push sock
    call listen
    test eax, eax
    jnz listen_error

accept_loop:
    push offset client_addr_len
    push offset client_addr
    push sock
    call accept
    mov client, eax
    cmp eax, INVALID_SOCKET
    je accept_error

    ; Get client IP and port
    push offset port_str
    push 8
    push offset ip_address
    push 16
    push offset client_addr
    call inet_ntoa
    
    movzx eax, word ptr [client_addr + 2]
    xchg al, ah
    push eax
    push dword ptr [ip_address]
    ; push offset accept_msg
    ; call printf
    invoke print_msg, addr accept_msg

    ; sending message
    invoke print_msg, addr message
    add esp, 12

    ; Send response
    push 0
    push msglen
    push offset message
    push client
    call send
    cmp eax, SOCKET_ERROR
    je send_error

    invoke print_msg, addr send_msg

    ; Close client socket
    push client
    call closesocket

    invoke print_msg, addr close_msg

    jmp accept_loop

wsa_error:
    invoke print_msg, addr error_msg
    jmp exit_program

socket_error:
    call WSAGetLastError
    invoke print_msg, addr error_msg
    jmp cleanup_wsa

bind_error:
    call WSAGetLastError
    invoke print_msg, addr error_msg
    jmp cleanup_socket

listen_error:
    call WSAGetLastError
    invoke print_msg, addr error_msg
    jmp cleanup_socket

accept_error:
    call WSAGetLastError
    invoke print_msg, addr error_msg
    jmp cleanup_socket

send_error:
    call WSAGetLastError
    invoke print_msg, addr error_msg
    jmp cleanup_client

cleanup_client:
    push client
    call closesocket
    jmp accept_loop

cleanup_socket:
    push sock
    call closesocket

cleanup_wsa:
    call WSACleanup

exit_program:
    push 0
    call ExitProcess

end start