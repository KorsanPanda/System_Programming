.global buton_kontrol_dongusu

buton_kontrol_dongusu:
    # Donanım Port Adresleri Tanımlamaları (Sign-Extension ile Yüksek Hafızaya Taşındı)
    addi x5, x0, -128    # x5 = LED Port Adresi (0xFFFFFF80)
    addi x13, x0, -124   # x13 = UART TX Port Adresi (0xFFFFFF84)
    addi x6, x0, -256    # x6 = Güvenli MMIO Buton Giriş Adresi (0xFFFFFF00)
    
    # Kontrol ve Karakter Sabitleri
    addi x14, x0, 43     # x14 = ASCII tablosunda '+' karakteri (43)
    addi x21, x0, 1      # x21 = Active-Low buton bırakıldı kontrol sabiti (1)
    addi x15, x0, 500    # x15 = Kararlı gecikme döngü sınırı (500)

led_sifirla:
    # 1. AKIŞ ADIMI: Ledlere 000000 yazdır (Hepsini söndür)
    sw x0, 0(x5)         

buton_basilma_bekle:
    # 2. AKIŞ ADIMI: Sonsuz bir beklemeye gir ve butonun basılmasını (0 olmasını) bekle
    lw x7, 0(x6)         
    beq x7, x21, buton_basilma_bekle 

    # [BEKLEMEDEN ÇIKILDI - BUTONA BASILDI]
    
    # 3. AKIŞ ADIMI: Serial monitöre sadece '+' işareti gönder
    sw x14, 0(x13)       

    # 4. AKIŞ ADIMI: Sayaca bir ekle ve ledlere o anki veriyi yazdır
    addi x9, x9, 1       
    sw x9, 0(x5)         # 1. basışta 000001, 2. basışta 000010 yanar...

    # UART donanımının '+' karakterini kabloya güvenle basması için kısa donanım gecikmesi
    addi x22, x0, 0      
tx_delay_out:
    addi x23, x0, 0      
tx_delay_in:
    addi x23, x23, 1     
    bne x23, x15, tx_delay_in
    addi x22, x22, 1     
    bne x22, x15, tx_delay_out

buton_birakma_bekle:
    # Kullanıcı elini butondan çekene kadar (Sinyal tekrar 1 olana kadar) bekleyen kilit döngüsü
    lw x7, 0(x6)
    bne x7, x21, buton_birakma_bekle

    # Buton ark sönümleme (Debounce) için kararlı gecikme döngüsü (500x500)
    addi x22, x0, 0      
debounce_out:
    addi x23, x0, 0      
debounce_in:
    addi x23, x23, 1     
    bne x23, x15, debounce_in
    addi x22, x22, 1     
    bne x22, x15, debounce_out

    # 5. AKIŞ ADIMI: Tekrar sonsuz buton bekleme kısmına geri dön
    beq x0, x0, buton_basilma_bekle