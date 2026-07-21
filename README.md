# System_Programming# ⚡ System Programming FPGA (Gowin GW1NR-9K / VHDL & Verilog & Python)

![Hardware](https://img.shields.io/badge/Board-Gowin_Tang_Nano_9K-orange.svg)
![FPGA](https://img.shields.io/badge/FPGA-GW1NR--9K-blue.svg)
![HDL](https://img.shields.io/badge/HDL-VHDL%20%7C%20Verilog-green.svg)
![Scripting](https://img.shields.io/badge/Scripting-Python_3-purple.svg)
![Toolchain](https://img.shields.io/badge/Toolchain-Gowin_EDA-red.svg)

A hybrid hardware-software system programming project deployed on the **Gowin Tang Nano 9K FPGA (GW1NR-9K)** board. The system combines **VHDL** and **Verilog** for digital logic/RTL design alongside **Python** scripts for host-side automation, serial communication, and data processing.

---

## 📌 Project Overview

This project implements low-level system programming and digital hardware architectures directly on a physical FPGA platform. By pairing HDL-based hardware modules with host-side Python tooling, the architecture achieves real-time execution, custom peripheral control, and hardware-software co-design.

### Key Features
* **Multi-HDL Architecture:** Mixed-language RTL design utilizing VHDL for structural/control components and Verilog for data path/peripheral modules.
* **Gowin 9K FPGA Target:** Optimized for the Gowin GW1NR-9K chip (9K LUTs, embedded BSRAM, onboard USB-JTAG/UART).
* **Python Host Integration:** Python scripts handle UART/serial communication, testbench automation, data serialization, and verification.
* **Hardware-Software Co-Design:** Interfacing custom FPGA logic modules with host-side software execution.

---

## 🏗️ System Architecture

```text
+-----------------------------------------------------------------------+
|                           Host System (PC)                            |
|                     Python Automation & Communication                 |
+-----------------------------------++----------------------------------+
                                    || UART / USB Serial
+-----------------------------------vv----------------------------------+
|                  Gowin Tang Nano 9K FPGA (GW1NR-9K)                   |
|  +--------------------------------+  +-----------------------------+  |
|  |     VHDL Control Modules       |  |  Verilog Datapath Modules   |  |
|  |   (FSM / System Logic)         |  |   (Peripherals / Registers) |  |
|  +--------------------------------+  +-----------------------------+  |
+-----------------------------------------------------------------------+
```

---

## 🚀 Getting Started

### Prerequisites
* **Gowin EDA** (Gowin FPGA Designer Suite)
* **Python 3.8+** (with `pyserial` for communication)
* Gowin Tang Nano 9K FPGA board

### Build and Synthesis

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/USERNAME/System_Programming.git](https://github.com/USERNAME/System_Programming.git)
   cd System_Programming
   ```

2. **Synthesis & Bitstream Generation:**
   * Open `Gowin EDA`.
   * Open the project file (`.gpn` / `.gprj`).
   * Add the VHDL (`.vhd`) and Verilog (`.v`) source files from the `hdl/` directory.
   * Add the physical constraint file (`.cst`) for pin mappings on the Tang Nano 9K.
   * Run **Synthesize** and **Place & Route**.
   * Generate Bitstream (`.fs`).

3. **Program the FPGA:**
   * Connect the Tang Nano 9K via USB.
   * Flash the `.fs` bitstream using **Gowin Programmer**.

4. **Run Python Host Script:**
   ```bash
   python python/host_controller.py
   ```
