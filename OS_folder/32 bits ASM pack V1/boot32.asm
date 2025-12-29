bits 16      ;устанавливаем 16 битную адресацию

org 0x7C00   ;наччальное смещение всех данных

global init_pm ;создание глоюальной переменной 

CODE_SEG equ 0x08 ;
DATA_SEG equ 0x10 ;


start_boot:
    
    cli            ;запрет прерываний
              
    xor ax,ax      ;обнуление регистра ax
    mov [boot_drive],dl
    mov ds,ax      ;обнуления важных регистров
    mov es,ax      ;
    mov ss, ax     ;
    mov sp , 0x7B00; установка правиьного указателя на код

    mov si,msg1
    call printSTR

call loadKernel

call startTo32mode

;;;;;;;;;;;;;;;;;;
;16 bit Functions;
;;;;;;;;;;;;;;;;;;
loadKernel:
      mov ah,0x02  ;команда для чтения
      mov al,5     ;сколько секторов читать

      mov ch ,0    ;головка
      mov cl ,2    ;с какого сектора читать

      mov dh ,0    ;цилиндр
      mov dl ,[boot_drive] ;номер диска с которого читать будем

      xor bx,bx    ; настраиваем адрес выгрузки ядра в RAM
      mov es,bx    ;

      mov bx,0x7E00 ; es:bx
      int 0x13

      jc .error_load; если биос выдает ошибку прыгаем на ошибку чтения

      cmp al, 5
      jne .error_load

      mov si , msg2
      call printSTR 
ret

.error_load:
    mov si , err
    call printSTR
    jmp halt
ret
halt:
    cli
    hlt
    jmp halt
printSTR:;функция принта в 16 битном режиме
    pusha 

    mov ah,0x0E
    mov bh,0
    mov bl,7
.print_lop:
    lodsb
    
    test al,al
    jz .print_stp  ;ГРУБО заканчиваем вывод если строка закончилась 

    int 0x10;максимально ГРУБО просим биос вывести символ
    jmp .print_lop
.print_stp:
    popa
    ret
;;;;;;;;;;;;;;16 BITS DATA SEGMENT;;;;;;;;;;;
boot_drive: db 0
msg:   db "Hello from boot" ,0x0D,0x0A, 0
err :  db "ERROR from load kernel",0x0D,0x0A,0
msg1:  db "Load Kernel...",0x0D,0x0A,0
msg2:  db "Kernel load me jump to 32 bits mode",0x0D,0x0A,0
erra20:db "Error from A20",0

addr_RAM:    dd 0x0100100
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;16 BITS SEGMENT END;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;///////////////
gdt_start1:

;нулевой дескрипторы !!!обязателен!!!
dd 0
dd 0

;ДЕСКРИПТОР CODE_SEGMENT всего компьтера
dw 0xFFFF ; вся память до 4гб

dw 0 ; начиная с самого начала малдшие 0-15 бит
db 0 ;  средние 16 - 23

db 10011010b ;
db 11001111b ;

db 0

;ДЕСКРИПТОР ДАННЫХ ВСЕГО КОМПЬТЕРА 

dw 0xFFFF

dw 0
db 0
 
db 10010010b
db 11001111b 

db 0

gdt_end1:

gdt_descriptor:
dw gdt_end1 - gdt_start1 - 1

dd gdt_start1
;//////////////////
;///////////////////////////////////////////////////
enable_a20_line:
    push ax
    in al, 0x92

    test al,2
    jnz .a20_done
    
    or al,2

    out 0x92 , al
    call short_delay

.a20_done:
    pop ax 
    ret

short_delay:
push cx
mov cx , 0x0100

.delay_loop:
nop 
nop 
loop .delay_loop

pop cx
ret 

enable_a20_lineb:
    mov al,0x01 ;загружаем команду биосу для активации лини А20
    mov ah,0x24 ;при этом разбиваем ее 
    int 0x15
    jc .error_A20
    ret
.error_A20:
    mov si,erra20
    call printSTR


;////////////

startTo32mode:
    

    call enable_a20_lineb
    cli

    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7B00

    lgdt [gdt_descriptor];загрузка адреса и размера gdt

    ; устанавливаем бит защиты в регистр cr0
    mov eax , cr0 ;даем команду процессору перейти в защищенныей режим 
    or eax ,  1   ;
    mov cr0 , eax ;

    jmp 0x08:init_pm; так как на конвеере проца все еще лежат 16 битные инструкции делаем прыжок до конца 32 битных инструкций

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;32 BITS SEGMENT;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 32]
init_pm:
   cli

   mov ax,0x10
   mov ds,ax
   mov es,ax
   mov ss,ax
   mov fs,ax
   mov gs,ax
   mov esp,0x10000
   
   call cls321
   
   mov ax,0x10
   mov fs,ax

   mov byte [fs:0],'X'
   mov byte [fs:1],0

   jmp 0x08:0x7E00

cls321:
    push ax
    push ecx
    push edi

    mov edi,0xB8000  
    mov ah,0x1F             ; за счет атрибута синего цвета цвет экрана будет синий 

    mov al, ' '             ;загружаем символ пробела тк ничего не выводим 
    mov ecx , 2000          ; устанавливаем 2000 повторений 
.cls321_loop:
    
    mov [edi], ax

    add edi,2
    loop .cls321_loop  ; повторяем ecx раз 

.cl321_stop:

    pop edi
    pop ecx
    pop ax

    ret
  ;////////32 BITS DATA SECTION////////////
hello_msg: db "Hello from 32 mode proccessor",0
addr_ptr: dd 0x0100000
gg: db "Hello from boot",0
;////////////////////////////////////////
times 510 - ($ - $$) db 0
dw 0xAA55