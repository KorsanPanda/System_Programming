.global main
.extern buton_kontrol_dongusu

main:
    # Güvenli Başlangıç: Fliplop sinyallerinin oturması için açılış gecikmesi (500x500)
    addi x15, x0, 500    
    addi x13, x0, 0      
boot_out:
    addi x14, x0, 0      
boot_in:
    addi x14, x14, -1     
    bne x14, x15, boot_in
    addi x13, x13, -1    
    bne x13, x15, boot_out

    # Sayaç registerını başlangıçta tamamen sıfırla
    addi x9, x0, 0       # x9 = Bizim ana sayacımız (Başlangıçta 0)

    # Ana fonksiyon iş parçacığına dallan
    jal x1, buton_kontrol_dongusu