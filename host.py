import serial
import time
import os

SERIAL_PORT = 'COM8'  # Kendi portunla değiştir
BAUD_RATE = 115200

def calculate_checksum(byte_array):
    checksum = 0
    for byte in byte_array:
        checksum ^= byte
    return checksum

def send_hex_firmware(hex_file_path):
    if not os.path.exists(hex_file_path):
        print(f"Hata: {hex_file_path} bulunamadı!")
        return

    try:
        with open(hex_file_path, "r") as f:
            hex_string = f.read().replace('\n', '').replace(' ', '').replace('\r', '')
            
        raw_bytes = bytes.fromhex(hex_string)
        print(f"Toplam {len(raw_bytes)} baytlık makine kodu okundu.")

        with serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1) as ser:
            print("FPGA'e bağlantı kuruldu. Aktarım başlıyor...\n")
            
            # Aktarım başlangıç zamanını kaydet
            start_time = time.time()
            
            for i in range(0, len(raw_bytes), 4):
                chunk = raw_bytes[i:i+4]
                
                if len(chunk) < 4:
                    chunk += b'\x00' * (4 - len(chunk))

                checksum = calculate_checksum(chunk)
                
                packet = bytearray(chunk)
                packet.append(checksum)
                
                ser.write(packet)
                time.sleep(0.001)
                
                print(f"Adres 0x{i:04X}: Veri={chunk.hex().upper()} | Checksum=0x{checksum:02X} gönderildi.")

            # Aktarım bitiş zamanını kaydet ve geçen süreyi hesapla
            end_time = time.time()
            elapsed_time = end_time - start_time

            print(f"\nYükleme tamamlandı! Toplam süre: {elapsed_time:.2f} saniye.")
            
    except Exception as e:
        print(f"Hata oluştu: {e}")

if __name__ == "__main__":
    send_hex_firmware("makine_kodu.hex")