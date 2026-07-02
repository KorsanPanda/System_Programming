.global main
.extern topla_ve_surekli_yaz

main:
    # Buton adresini oku (-256 = 0xFFFFFF00)
    addi x6, x0, -256    
    addi x21, x0, 1      # Active-Low buton bırakıldı sabiti

buton_bekle:
    lw x7, 0(x6)         
    beq x7, x21, buton_bekle # Butona basılmadığı sürece (1 olduğu sürece) burada kilitle

    # [BUTONA BASILDI] - Şimdi hesapla ve gönder
    addi x10, x0, 21     #sayi1
    addi x11, x0, 57     #sayi2
    jal x1, topla_ve_surekli_yaz