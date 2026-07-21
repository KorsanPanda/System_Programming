# ⚡ System Programming RISC-V SoC on Tang Nano 9K FPGA

![Hardware](https://img.shields.io/badge/Board-Gowin_Tang_Nano_9K-orange.svg)
![FPGA](https://img.shields.io/badge/FPGA-GW1NR--9K-blue.svg)
![Processor](https://img.shields.io/badge/CPU-PicoRV32_RISC--V-green.svg)
![HDL](https://img.shields.io/badge/HDL-VHDL-blue.svg)
![Scripting](https://img.shields.io/badge/Toolchain-Custom_Python_Assembler_%26_Linker-purple.svg)

A complete hardware-software co-design system programming framework built on the **Gowin Tang Nano 9K FPGA (GW1NR-9K)**. The project integrates a **PicoRV32 RISC-V CPU core** in VHDL, a custom **UART Bootloader FSM**, and a ground-up **Python-based Assembler & Linker toolchain** for building and flashing RISC-V firmware over serial interface.

---

## 📌 Project Overview

This architecture implements a soft-core RISC-V System-on-Chip (SoC) on FPGA hardware paired with a custom software toolchain:
* **Custom Python Assembler & Linker (`kodlar.py`):** Parses RISC-V assembly (`.asm`), generates object files (`.obj`), resolves global/extern symbols and branch relocations, and outputs merged machine code (`makine_kodu.hex`).
* **UART Firmware Loader (`loader_fsm.vhd` & `host.py`):** Transfers binary machine code chunks with XOR checksum verification directly into FPGA Block RAM (BRAM) over UART, automatically releasing CPU reset upon completion.
* **Memory-Mapped I/O (MMIO):** Interfacing software instructions to physical hardware components:
  * `0xFFFFFF80`: 6-bit LED Output Port
  * `0xFFFFFF84`: UART TX Data Register
  * `0xFFFFFF00`: S2 Hardware Pushbutton Input

---

## 🏗️ System Architecture

```text
+-------------------------------------------------------------------------------+
|                                Host System (PC)                               |
|   1. Assembler & Linker (kodlar.py)  --> Generates makine_kodu.hex          |
|   2. Serial Host Flasher (host.py)   --> Transmits Firmware via UART (COM)    |
+---------------------------------------++--------------------------------------+
                                        || UART Serial (115200 Baud)
+---------------------------------------vv--------------------------------------+
|                    Gowin Tang Nano 9K FPGA (system_top.vhd)                   |
|                                                                               |
|   +-------------------+       +--------------------+       +--------------+   |
|   |   UART RX/TX      | ----> | Loader FSM         | ----> | 16KB BRAM    |   |
|   | (uart_rx / tx)    |       | (loader_fsm.vhd)   |       | (ram)        |   |
|   +-------------------+       +--------------------+       +-------+------+   |
|                                                                    |          |
|   +-------------------+       +--------------------+               |          |
|   | LEDs / Button     | <---- | PicoRV32 RISC-V    | <-------------+          |
|   | (0xFFFFFF80/00)   |       | CPU Core           |                          |
|   +-------------------+       +--------------------+                          |
+-------------------------------------------------------------------------------+
```

---

## 💻 Custom Toolchain & Assembly Workflow

### 1. Custom Assembler & Linker (`kodlar.py`)
Translates RISC-V Assembly source files (`main2.asm`, `fonksiyon2.asm`) into relocatable object files using instruction formats defined in `opcode_tablosu.txt`, resolves symbol addresses, and generates `makine_kodu.hex`.

### 2. Flashing Firmware (`host.py`)
Sends the generated machine code over UART to the FPGA. The onboard `loader_fsm.vhd` handles packet assembly, verifies checksums, writes instructions into BRAM, and starts CPU execution.

---

## 🚀 Getting Started

### Prerequisites
* **Gowin EDA** (Gowin FPGA Designer)
* **Python 3.8+** (with `pyserial` installed: `pip install pyserial`)
* Gowin Tang Nano 9K FPGA Board

### Build & Execution Steps

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/KorsanPanda/system_programming.git](https://github.com/KorsanPanda/system_programming.git)
   cd system_programming
   ```

2. **Assemble & Link RISC-V Firmware:**
   ```bash
   python kodlar.py
   ```
   *Generates `makine_kodu.hex`, `main_symbol.txt`, `fonk_symbol.txt`, and `global_symbol.txt`.*

3. **Synthesize & Program FPGA:**
   * Open `system_top.vhd` in Gowin EDA alongside supporting VHDL modules (`loader_fsm.vhd`, `uart_rx.vhd`, `uart_tx.vhd`, `picorv32.v`).
   * Apply pin constraints from `pinler.cst`.
   * Synthesize, Place & Route, and flash the bitstream (`.fs`) to the Tang Nano 9K.

4. **Upload Firmware to FPGA:**
   ```bash
   python host.py
   ```

---

## 📁 Directory Structure

```text
korsanpanda-system_programming/
├── system_top.vhd          # Top-Level VHDL SoC wrapper connecting CPU, BRAM & MMIO
├── loader_fsm.vhd          # Hardware FSM for receiving and loading firmware into BRAM
├── uart_rx.vhd             # UART Receiver module (115200 baud)
├── uart_tx.vhd             # UART Transmitter module (115200 baud)
├── pinler.cst              # Physical pin constraints for Tang Nano 9K FPGA
├── kodlar.py               # Custom RISC-V Assembler & Linker Python implementation
├── host.py                 # Serial firmware uploader script with checksum verification
├── opcode_tablosu.txt      # RISC-V instruction opcode mapping reference
├── main.asm / main2.asm    # RISC-V assembly main program routines
├── fonksiyon.asm / ...     # Subroutine assembly source files
├── makine_kodu.hex         # Generated machine code output
├── *_symbol.txt            # Generated symbol tables for relocation verification
└── README.md               # Project documentation
```
