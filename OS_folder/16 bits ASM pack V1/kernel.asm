bits 16

org 0x7E00

start_kernel:
cli;стандартная функция очистки


xor ax,ax
mov ds,ax
mov es,ax
mov ss, ax
mov sp, 0x7E00

sti
call clearDisplay

mov si ,hello
call print_string

mov si,prompt;выводим промт с командами
call print_string


terminal_loop:;цикл из которого мы выйдем только по команде или по ошибке

   
call readline
call compare

jmp terminal_loop
;;;;;;;;;;;;;
;FUNCTION
;;;;;;;;;;;;;
stop_kernel:
cli
hlt

;;;;;;;;;;;;
clearDisplay:
    pusha;

    mov ax,0x0003;
    int 0x10

    popa ;
    ret

;;;;;;;;;;;;;;;;;;;;;
print_string:
    pusha
    
    mov ah , 0x0E;
    mov bh , 0
    mov bl , 7

;
printloop:
    ;стандартный цикл 
lodsb

test al ,al;проверяем на конец строки 
jz printStop

int 0x10
jmp printloop

;
printStop:
popa
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
compare:
;;;;;;;;;;;;;;
mov di , buffer  ;обработка команды help загружаем указатель на буффер
mov si , help    ;и указатель на команду которую мы хотим обработать
call cmp_str

cmp al, 1
je he1lp

;;;;;;;;;;;;;
mov di , buffer  ;обработка команды cls
mov si , cls     ; 
call cmp_str

cmp al, 1
je clearDisplay

;;;;;;;;;;;;;;
mov di , buffer
mov si, rem 
call cmp_str

cmp al,1
je shutdown_system

;;;;;;;;;;;;;;


.compare_stop:
ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
readline:

pusha
mov cx , 0
mov di,buffer

;;;;;;;;;
.read_loop:

mov ah,0; проц зависает и ждет нажатия клавиши 
int 0x16; биос фукнкция 

cmp al, 0x0D;проверка на ТАБ
je .read_stop;заканчиваем чтение

cmp al, 0x08
je .backspace

mov ah,0x0E
mov bh , 0
int 0x10

mov [di], al
inc di
inc cx

cmp cx,7;проверка на выход за буффер
je .read_stop

jmp .read_loop ;продолжаем цикл

;;;;
.backspace:

    cmp cx,0
    je .read_loop

    dec cx
    dec di
    mov [di] , 0;удалаяем прошлый символ

    mov al,0x08;через биос перемешаем курсор назад
    int 0x10

    mov al,' ';стираем его 
    int 0x10

    mov al,0x08;и опять через биос перемишаем курсор назад
    int 0x10
jmp .read_loop

;;;;;;;;;;
.read_stop:
    mov ah,0x0E;МАСКИМАЛЬНО НЕВЕЖЛИВО ЗАСТАВЛЯЮ БИОС ПЕРЕВЕСТИ НА НОВУЮ СТРОКУ
    mov al,0x0D
    int 0x10
    mov al,0x0A
    int 0x10

    mov byte [di] , 0
    popa 
    ret

;;;;;;;;
cmp_str:
    push cx
    push si
    push di

.cmp_str_loop:

mov al , [di]    ;сохраняем первые символы из двух указателей
mov bl , [si]    ;

cmp al,bl        ; сравниваем если не равны првыгаем на не равны
jne  .not_equal  ;

inc di
inc si

cmp bl,0
je .check_end

jmp .cmp_str_loop

.check_end: ;если хотябы один из регистров на данные момент равен нуллю то мы проверяем второй на конец
    cmp al, 0 
    jne .not_equal

.equal:     ;если они равны выставляем флаг 1
    mov ax,1
    jmp .cmp_str_stop

.not_equal: ;если они не равны выставляем флаг 0

    mov ax,0
    jmp .cmp_str_stop

.cmp_str_stop:
    pop di
    pop si

    pop cx
    ret

he1lp:
    mov si , help_text
    call print_string   
    ret

shutdown_system:
    jmp 0x7C00
    ret

write_driver:
ret

read_driver:
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;DATA SECTION ;;;;;;;;;;;;;;
prompt: db "all comands: help ,go ,cls ,shud ,move , read",0x0D,0x0A,0
;;;
buffer: times 7 db 0
;;;
hello: db "Hello from Kernel",0x0D,0x0A,0
;;;
help_text: db "All comands: help ,go ,cls ,rem  ,write , read;",0x0D,0x0A,0
;;;
help: db "help",0
go:   db   "go",0
cls : db  "cls",0
rem:  db  "rem",0
move: db "move",0
read: db "read",0
write:db"write",0
to32: db "to32",0
;;;;;;;;;;;;;;