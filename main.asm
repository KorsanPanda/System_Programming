.global main
.extern delay_and_tx

main:
    # LED adresi güvenli yüksek hafızaya (0xFFFFFF80) taşındı
    addi x5, x0, -128    # Eski değer: 128 (0x80)
    addi x6, x0, 1       # Yanacak ilk LED
    addi x7, x0, 32      # Sol Sınır (5. LED = 32)
    addi x8, x0, 0       # Yön (0=Sol, 1=Sağ)
    addi x9, x0, 1       # Sağ Sınır (0. LED = 1)

loop:
    sw x6, 0(x5)         
    jal x1, delay_and_tx 
    beq x8, x0, shift_left

shift_right:
    srli x6, x6, 1       
    beq x6, x9, change_to_left 
    jal x0, loop         

shift_left:
    slli x6, x6, 1       
    beq x6, x7, change_to_right 
    jal x0, loop         

change_to_left:
    addi x8, x0, 0       
    jal x0, loop

change_to_right:
    addi x8, x0, 1       
    jal x0, loop