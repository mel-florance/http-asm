bits 64

%define SYS_read 0
%define SYS_write 1
%define SYS_exit 60
%define SYS_socket 41
%define SYS_bind 49
%define SYS_listen 50
%define SYS_accept 43
%define SYS_close 3

%define AF_INET 2
%define SOCK_STREAM 1
%define IPPROTO_IP 0
%define INADDR_ANY 0

%define MAX_CONN 4

%define STDOUT 1
%define STDERR 2

global _start
_start:
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, start_msg
    mov rdx, start_msg_len
    syscall

    call init_socket

    call exit

init_socket:
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, init_socket_msg
    mov rdx, init_socket_msg_len
    syscall
    
    mov rax, SYS_socket
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    mov rdx, IPPROTO_IP
    syscall

    cmp rax, 0
    jl error

    mov [server_socket], eax
    
    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, bind_socket_msg
    mov rdx, bind_socket_msg_len
    syscall
    
    mov rax, SYS_bind
    mov rdi, [server_socket]
    mov rsi, sockaddr_in
    mov rdx, sockaddr_in_len
    syscall

    cmp rax, 0
    jl error

    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, listen_socket_msg
    mov rdx, listen_socket_msg_len
    syscall

    mov rax, SYS_listen
    mov rdi, [server_socket]
    mov rsi, MAX_CONN
    syscall

    mov rax, SYS_write
    mov rdi, STDOUT
    mov rsi, accept_socket_msg
    mov rdx, accept_socket_msg_len
    syscall

    call accept_connection

    mov rax, SYS_close
    mov rdi, [server_socket]
    syscall

accept_connection:
    mov rax, SYS_accept
    mov dword [peer_len], sockaddr_in_peer_len
    mov rdi, [server_socket]
    mov rsi, sockaddr_in_peer
    mov rdx, peer_len
    syscall

    cmp rax, 0
    jl error

    mov [client_socket], eax

    mov rax, SYS_read
    mov rdi, [client_socket]
    mov rsi, req_buf
    mov rdx, 1024
    syscall

    cmp dword [req_buf], 'GET '
    jne skip_count
    cmp byte [req_buf + 4], '/'
    jne skip_count
    cmp byte [req_buf+5], ' '
    jne skip_count

    inc qword [n_conn]

skip_count:
    mov rax, [n_conn]
    lea rsi, [n_conn_buf + 21]
    mov rbx, 10

convert_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jnz convert_loop

    lea rcx, n_conn_buf + 22
    sub rcx, rsi
    mov r9, rcx
    mov r8, rsi

    mov rax, SYS_write
    mov rdi, [client_socket]
    mov rsi, welcome_p1_msg
    mov rdx, welcome_p1_msg_len
    syscall

    mov rax, SYS_write
    mov rdi, [client_socket]
    mov rdx, rcx
    mov rsi, r8
    mov rdx, r9
    syscall

    mov rax, SYS_write
    mov rdi, [client_socket]
    mov rsi, welcome_p2_msg
    mov rdx, welcome_p2_msg_len
    syscall 

    mov rax, SYS_close
    mov rdi, [client_socket]
    syscall

    jmp accept_connection

error:
    mov rax, SYS_write
    mov rdi, STDERR
    mov rsi, error_msg
    mov rdx, error_msg_len
    syscall

    call exit

exit:
    mov rax, SYS_exit
    mov rdi, 0
    syscall

section .data
start_msg db 'Starting server...', 10
start_msg_len equ $ - start_msg

init_socket_msg db 'Initializing socket...', 10
init_socket_msg_len equ $ - init_socket_msg

bind_socket_msg db 'Binding socket...', 10
bind_socket_msg_len equ $ - bind_socket_msg

listen_socket_msg db 'Server listening...', 10
listen_socket_msg_len equ $ - listen_socket_msg

accept_socket_msg db 'Server ready for connections...', 10
accept_socket_msg_len equ $ - accept_socket_msg

welcome_p1_msg db 'HTTP/1.1 200 OK', 13, 10
            db 'Content-Type: text/html', 13, 10
            db 'Connection: close', 13, 10, 13, 10
            db '<h1>Welcome from assembly - visitor #'
welcome_p1_msg_len equ $ - welcome_p1_msg

welcome_p2_msg db '</h1>', 10, 0
welcome_p2_msg_len equ $ - welcome_p2_msg

error_msg db 'Error !', 10
error_msg_len equ $ - error_msg

server_socket dd -1
client_socket dd -1

sockaddr_in:
    .sin_family dw AF_INET
    .sin_port dw 0x901f
    .sin_addr dd INADDR_ANY
    .sin_zero dq 0
sockaddr_in_len equ $ - sockaddr_in

sockaddr_in_peer:
    .sin_family dw AF_INET
    .sin_port dw 0x901f
    .sin_addr dd INADDR_ANY
    .sin_zero dq 0
sockaddr_in_peer_len equ $ - sockaddr_in_peer

section .bss
peer_len  resd 1
n_conn resq 1
n_conn_buf resb 22
req_buf resb 1024