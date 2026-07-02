.global delay_and_tx

delay_and_tx:
    # UART TX adresi güvenli yüksek hafızaya (0xFFFFFF84) taşındı
    addi x11, x0, -124   # Eski değer: 132 (0x84)
    addi x12, x0, 42     # '*' karakteri
    sw x12, 0(x11)       

    addi x13, x0, 0      
    addi x15, x0, 500    

outer_loop:
    addi x14, x0, 0      
inner_loop:
    addi x14, x14, 1     
    bne x14, x15, inner_loop
    
    addi x13, x13, 1     
    bne x13, x15, outer_loop

    jalr x0, x1, 0