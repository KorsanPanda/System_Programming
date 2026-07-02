.global topla_ve_surekli_yaz

topla_ve_surekli_yaz:
    # 1. Dinamik Toplama İşlemi
    add x12, x10, x11    # x12 = x10 + x11
    
    # Donanım Port Adresleri
    addi x13, x0, -124   # UART TX adresi (0xFFFFFF84)
    addi x5, x0, -128    # LED adresi (0xFFFFFF80)
    addi x6, x0, 255     # Tüm LED'leri yakacak maske (255)
    addi x20, x0, 48     # ASCII tablosunda '0' rakamının karşılığı (48)
    
    # Bütün LED'leri Yak
    sw x6, 0(x5)         

    # 2. Sayıyı Donanımsal Olarak Basamaklarına Ayırma (Onlar ve Birler)
    addi x17, x0, 0      # x17 = Onlar basamağı sayacı (Başlangıç: 0)

onlar_basamagi_dongu:
    addi x18, x12, -10   
    srli x19, x18, 31    
    bne x19, x0, basamaklar_hazir 
    
    addi x12, x12, -10   
    addi x17, x17, 1     
    beq x0, x0, onlar_basamagi_dongu 

basamaklar_hazir:
    add x17, x17, x20    # Onlar basamağının ASCII karşılığı
    add x12, x12, x20    # Birler basamağının ASCII karşılığı

    # Kararlı döngü üst sınırı (500)
    addi x15, x0, 500    

tek_sefer_gonder_dongusu:
    # -----------------------------------------------------------------
    # ADIM 1: Dinamik Hesaplanan Onlar Basamağını Gönder ve Bekle
    # -----------------------------------------------------------------
    sw x17, 0(x13)       
    
    addi x22, x0, 0      
out_loop1:
    addi x23, x0, 0      
in_loop1:
    addi x23, x23, 1     
    bne x23, x15, in_loop1
    addi x22, x22, 1     
    bne x22, x15, out_loop1

    # -----------------------------------------------------------------
    # ADIM 2: Dinamik Hesaplanan Birler Basamağını Gönder ve Bekle
    # -----------------------------------------------------------------
    sw x12, 0(x13)       
    
    addi x22, x0, 0      
out_loop2:
    addi x23, x0, 0      
in_loop2:
    addi x23, x23, 1     
    bne x23, x15, in_loop2
    addi x22, x22, 1     
    bne x22, x15, out_loop2

    # -----------------------------------------------------------------
    # ADIM 3: Akışı Durdur (Sadece 1 Kere Yazdırma Sağlayan Kritik Kısım)
    # -----------------------------------------------------------------
programi_durdur:
    beq x0, x0, programi_durdur  # Başa dönmek yerine işlemciyi burada kendi içinde sonsuz döngüye alıyoruz