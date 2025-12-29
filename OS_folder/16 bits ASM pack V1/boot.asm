bits 16;перевод процессора в 16 битный режим 

org 0x7C00;точка отсчета адресации переменнных



start:
    cli;запрет прерываний

    xor ax,ax

    mov ds, ax ; обнуление дата сегмента
    mov es ,ax ; обнуление экстра сегмента
    mov ss, ax ; обнуления сегмента стэка


    mov sp , 0x7C00

    sti;разрешение прерываний

    ;функция биос для очистки экрана
    mov ax,0x0003
    int 0x10
    
    mov si , msg
    call print_string

    mov si , msg1
    call print_string

    jmp load_kernel

load_kernel:
mov ah,0x02;команда биосу читать
mov al,2;сколько секторов читать нужно

mov ch,0;номер цилиндра для чтения
mov cl,2;порядковый номер сектора для чтения соостветсвенно в режиме LBA

mov dh,0;головка
mov dl,0;номер диска тк fluppy controller то 0


mov bx , 0x7E00;

int 0x13
jc disk_error

mov si , msg2
call print_string

mov ah,0; проц зависает и ждет нажатия клавиши после нажатия мы прыгаем на ядро
int 0x16; биос фукнкция 

jmp 0x0000:0x7E00

disk_error:
    mov si , err
    call print_string 
    jmp halt

halt:;заставляем процессор просто зависнуть
    cli
    hlt
    jmp halt
;процедура вывода строки через функцию биоса
print_string:
    pusha

    mov ah , 0x0E
    mov bh , 0
    mov bl , 7
.printloop:;стандартный цикл 
lodsb

test al ,al;проверяем на конец строки 
jz .printStop

int 0x10
jmp .printloop

;;
.printStop:
popa
ret

;;;;;;;;;;;
msg: db "Hello from boot" ,0x0D,0x0A, 0
err : db "ERROR from load kernel",0x0D,0x0A,0
msg1: db "Load Kernel...",0x0D,0x0A,0
msg2:db "Kernel load me jump to kernel",0x0D,0x0A,0
buffer: times 64 db 0
;;;;;;;;;;;;
times 510 - ($ - $$) db 0
dw 0xAA55