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

include \masm32\include\msvcrt.inc
includelib \masm32\lib\msvcrt.lib

; External references to content
EXTERN index_content:BYTE
EXTERN about_content:BYTE

.data
    port dw 9966
    sock dd 0
    client dd 0
    wsaData db 400 dup(?)
    my_sockaddr db 16 dup(?)
    client_addr db 16 dup(?)
    client_addr_len dd 16
    buffer db 1024 dup(0)
    header db "HTTP/1.1 200 OK", 13, 10
           db "Content-Type: text/html", 13, 10
           db "Content-Length: %d", 13, 10, 13, 10
    ; debug_msg db "Debug - Parsed path: %s", 13, 10, 0
    index_page db "/", 0
    about_page db "/about", 0
    not_found db "404 Not Found", 0
    error_msg db "Error: %s (code %d)", 13, 10, 0
    success_msg db "Success: Server started on port 9966", 13, 10, 0
    accept_msg db "Accepted new connection from %d.%d.%d.%d:%d", 13, 10, 0
    request_msg db "Received request: %s", 13, 10, 0
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

send_response proc uses eax ebx ecx edx, content:DWORD
    local content_length:DWORD
    local header_buffer[128]:BYTE

    invoke lstrlen, content
    mov content_length, eax

    ; Format the header with the content length
    invoke wsprintf, addr header_buffer, addr header, content_length
    invoke send, client, addr header_buffer, eax, 0
    invoke send, client, content, content_length, 0
    ret
send_response endp

parse_request proc uses eax ebx ecx edx esi edi, request:DWORD
    mov esi, request
    mov edi, request
    
    ; Skip "GET "
    add esi, 4
    
    ; Find the start of the path (should be at '/')
    .while byte ptr [esi] != '/'
        inc esi
    .endw
    
    ; Copy the path
    .while byte ptr [esi] != ' ' && byte ptr [esi] != 0
        movsb
    .endw
    
    ; Null-terminate the string
    mov byte ptr [edi], 0
    
    ; Debug output
    ; invoke print_msg, addr debug_msg
    ; invoke print_msg, request
    
    ret
parse_request endp

handle_request proc uses eax ebx ecx edx, request:DWORD
    invoke print_msg, addr request_msg
    invoke print_msg, request

    ; Parse and handle request
    invoke parse_request, request
    
    ; Debug output
    ; invoke print_msg, addr debug_msg
    ; push request
    ; push offset debug_msg
    ; add esp, 8

    ; Check for root path
    invoke lstrcmp, request, addr index_page
    test eax, eax
    jz serve_index

    invoke lstrcmp, request, addr about_page
    test eax, eax
    jz serve_about

    ; If not matched, send 404 Not Found
    invoke send_response, offset not_found
    ret

serve_index:
    invoke send_response, offset index_content
    ret

serve_about:
    invoke send_response, offset about_content
    ret
handle_request endp

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
    invoke print_msg, addr accept_msg

    ; Receive request
    push 0
    push 1024
    push offset buffer
    push client
    call recv

    ; Handle request
    push offset buffer
    call handle_request

    ; Close client socket
    push client
    call closesocket

    invoke print_msg, addr close_msg

    jmp accept_loop

    ; (Error handling and cleanup as in your original code)

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
