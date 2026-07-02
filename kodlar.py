import os

class OpcodeNode:
    def __init__(self, mnemonic, fmt, opcode, funct3="", funct7=""):
        self.mnemonic = mnemonic
        self.fmt = fmt
        self.opcode = opcode
        self.funct3 = funct3
        self.funct7 = funct7
        self.next = None

class OpcodeTable:
    def __init__(self):
        self.head = None

    def add(self, mnemonic, fmt, opcode, funct3="", funct7=""):
        node = OpcodeNode(mnemonic, fmt, opcode, funct3, funct7)
        if self.head is None:
            self.head = node
            return
        current = self.head
        while current.next is not None:
            current = current.next
        current.next = node

    def find(self, mnemonic):
        current = self.head
        while current is not None:
            if current.mnemonic == mnemonic:
                return current
            current = current.next
        return None

class SymbolNode:
    def __init__(self, label, address, sym_type="LOCAL"):
        self.label = label
        self.address = address
        self.sym_type = sym_type
        self.next = None

class SymbolTable:
    def __init__(self):
        self.head = None

    def add(self, label, address, sym_type="LOCAL"):
        existing = self.find(label)
        if existing is not None:
            existing.address = address
            existing.sym_type = sym_type
            return
        node = SymbolNode(label, address, sym_type)
        if self.head is None:
            self.head = node
            return
        current = self.head
        while current.next is not None:
            current = current.next
        current.next = node

    def find(self, label):
        current = self.head
        while current is not None:
            if current.label == label:
                return current
            current = current.next
        return None

    def get_all(self):
        result = {}
        current = self.head
        while current is not None:
            result[current.label] = {
                "address": current.address,
                "type": current.sym_type
            }
            current = current.next
        return result

class RelocationNode:
    def __init__(self, address, label, instr_type, mnemonic, rd="", rs1="", rs2=""):
        self.address = address
        self.label = label
        self.instr_type = instr_type
        self.mnemonic = mnemonic
        self.rd = rd
        self.rs1 = rs1
        self.rs2 = rs2
        self.next = None

class RelocationTable:
    def __init__(self):
        self.head = None

    def add(self, address, label, instr_type, mnemonic, rd="", rs1="", rs2=""):
        node = RelocationNode(address, label, instr_type, mnemonic, rd, rs1, rs2)
        if self.head is None:
            self.head = node
            return
        current = self.head
        while current.next is not None:
            current = current.next
        current.next = node

    def get_all_list(self):
        result = []
        current = self.head
        while current is not None:
            result.append({
                "address": current.address,
                "label": current.label,
                "type": current.instr_type,
                "mnemonic": current.mnemonic,
                "rd": current.rd,
                "rs1": current.rs1,
                "rs2": current.rs2
            })
            current = current.next
        return result

class Assembler:
    def __init__(self):
        self.symbols = SymbolTable()
        self.relocations = RelocationTable()
        self.opcodes = OpcodeTable()
        self.text_segment = []
        self.global_names = []
        self.extern_names = []
        self.load_opcodes_from_file("opcode_tablosu.txt")

    def load_opcodes_from_file(self, filename="opcode_tablosu.txt"):
        try:
            with open(filename, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    parts = line.split()
                    mnemonic = parts[0]
                    fmt = parts[1]
                    opcode = parts[2]
                    funct3 = parts[3] if len(parts) > 3 else ""
                    funct7 = parts[4] if len(parts) > 4 else ""
                    self.opcodes.add(mnemonic, fmt, opcode, funct3, funct7)
            print(f"[BİLGİ] Opcode tablosu '{filename}' dosyasından başarıyla yüklendi.")
        except FileNotFoundError:
            print(f"[HATA] '{filename}' dosyası bulunamadı! Lütfen dosyanın aynı klasörde olduğundan emin ol.")
            exit(1)

    def clean_line(self, line):
        hash_pos = line.find("#")
        semicolon_pos = line.find(";")
        cut_pos = -1
        if hash_pos != -1 and semicolon_pos != -1:
            cut_pos = min(hash_pos, semicolon_pos)
        elif hash_pos != -1:
            cut_pos = hash_pos
        elif semicolon_pos != -1:
            cut_pos = semicolon_pos
        if cut_pos != -1:
            line = line[:cut_pos]
        return line.strip()

    def parse_register(self, token):
        token = token.strip()
        if not token.startswith("x"):
            raise ValueError(f"Geçersiz register: {token}")
        number = int(token[1:])
        if number < 0 or number > 31:
            raise ValueError(f"Register aralık dışı: {token}")
        return format(number, "05b")

    def to_twos_complement(self, value, bits):
        return value & ((1 << bits) - 1)

    def encode_branch_binary(self, mnemonic, rs1_bin, rs2_bin, offset):
        node = self.opcodes.find(mnemonic)
        imm13 = self.to_twos_complement(offset, 13)
        bit12 = (imm13 >> 12) & 1
        bit11 = (imm13 >> 11) & 1
        bits10_5 = (imm13 >> 5) & 0b111111
        bits4_1 = (imm13 >> 1) & 0b1111
        return (
            format(bit12, "01b") + format(bits10_5, "06b") + rs2_bin + rs1_bin +
            node.funct3 + format(bits4_1, "04b") + format(bit11, "01b") + node.opcode
        )

    def encode_jal_binary(self, rd_bin, offset):
        opcode = "1101111"
        imm21 = self.to_twos_complement(offset, 21)
        bit20 = (imm21 >> 20) & 1
        bits10_1 = (imm21 >> 1) & 0b1111111111
        bit11 = (imm21 >> 11) & 1
        bits19_12 = (imm21 >> 12) & 0b11111111
        return (
            format(bit20, "01b") + format(bits10_1, "010b") + format(bit11, "01b") +
            format(bits19_12, "08b") + rd_bin + opcode
        )

    def pass1(self, input_file):
        pc = 0
        with open(input_file, "r", encoding="utf-8") as f:
            for raw_line in f:
                line = self.clean_line(raw_line)
                if line == "": continue

                if line.startswith(".global"):
                    name = line.split()[1].strip()
                    self.global_names.append(name)
                    continue

                if line.startswith(".extern"):
                    name = line.split()[1].strip()
                    self.extern_names.append(name)
                    self.symbols.add(name, 0, "EXTERN")
                    continue

                if ":" in line:
                    label, rest = line.split(":", 1)
                    label = label.strip()
                    if label in self.global_names:
                        sym_type = "GLOBAL"
                    else:
                        sym_type = "LOCAL"
                    self.symbols.add(label, pc, sym_type)
                    line = rest.strip()

                if line == "" or line.startswith("."):
                    continue
                pc += 4

    def encode_instruction(self, mnemonic, operands, pc):
        node = self.opcodes.find(mnemonic)
        if node is None:
            raise ValueError(f"Bilinmeyen komut: {mnemonic}")

        if node.fmt == "R":
            rd = self.parse_register(operands[0])
            rs1 = self.parse_register(operands[1])
            rs2 = self.parse_register(operands[2])
            return node.funct7 + rs2 + rs1 + node.funct3 + rd + node.opcode

        if node.fmt == "I":
            if mnemonic == "lw":
                rd = self.parse_register(operands[0])
                imm, rs1_text = operands[1].replace(")", "").split("(")
                rs1 = self.parse_register(rs1_text)
                imm_bin = format(self.to_twos_complement(int(imm), 12), "012b")
            else:
                rd = self.parse_register(operands[0])
                rs1 = self.parse_register(operands[1])
                imm_bin = format(self.to_twos_complement(int(operands[2]), 12), "012b")
            return imm_bin + rs1 + node.funct3 + rd + node.opcode

        if node.fmt == "S":
            rs2 = self.parse_register(operands[0])
            imm, rs1_text = operands[1].replace(")", "").split("(")
            rs1 = self.parse_register(rs1_text)
            imm_bin = format(self.to_twos_complement(int(imm), 12), "012b")
            imm_high = imm_bin[:7]
            imm_low = imm_bin[7:]
            return imm_high + rs2 + rs1 + node.funct3 + imm_low + node.opcode

        if node.fmt == "B":
            rs1 = self.parse_register(operands[0])
            rs2 = self.parse_register(operands[1])
            target = operands[2].strip()
            symbol = self.symbols.find(target)

            if symbol is not None and symbol.sym_type != "EXTERN":
                offset = symbol.address - pc
            else:
                offset = 0
                self.relocations.add(pc, target, "B", mnemonic, "", rs1, rs2)
            return self.encode_branch_binary(mnemonic, rs1, rs2, offset)

        if node.fmt == "J":
            if len(operands) == 1:
                rd = self.parse_register("x1")
                target = operands[0].strip()
            else:
                rd = self.parse_register(operands[0])
                target = operands[1].strip()

            symbol = self.symbols.find(target)

            if symbol is not None and symbol.sym_type != "EXTERN":
                offset = symbol.address - pc
            else:
                offset = 0
                self.relocations.add(pc, target, "J", mnemonic, rd)
            return self.encode_jal_binary(rd, offset)

        raise ValueError(f"Desteklenmeyen format: {node.fmt}")

    def assemble(self, input_file, output_obj_file):
        self.pass1(input_file)
        pc = 0
        self.text_segment = []

        with open(input_file, "r", encoding="utf-8") as f:
            for raw_line in f:
                line = self.clean_line(raw_line)
                if line == "": continue
                if line.startswith(".global") or line.startswith(".extern"): continue
                if ":" in line:
                    line = line.split(":", 1)[1].strip()
                if line == "" or line.startswith("."): continue

                parts = line.split(None, 1)
                mnemonic = parts[0]
                if len(parts) > 1:
                    operands = [op.strip() for op in parts[1].split(",")]
                else:
                    operands = []

                binary_code = self.encode_instruction(mnemonic, operands, pc)
                self.text_segment.append(binary_code)
                pc += 4

        base_name = os.path.basename(input_file).split('.')[0]
        prog_name = base_name[:6].upper()

        with open(output_obj_file, "w", encoding="utf-8") as f:
            f.write(f"H{prog_name:<6}000000{len(self.text_segment) * 4:06X}\n")

            globals_list = [name for name, info in self.symbols.get_all().items() if info["type"] == "GLOBAL"]
            if globals_list:
                for name in globals_list:
                    addr = self.symbols.find(name).address
                    f.write(f"D{name[:6]:<6}{addr:06X}\n")

            externs_list = [name for name, info in self.symbols.get_all().items() if info["type"] == "EXTERN"]
            if externs_list:
                for name in externs_list:
                    f.write(f"R{name[:6]:<6}\n")

            hex_text = "".join(f"{int(binary, 2):08X}" for binary in self.text_segment)
            start_addr = 0
            for i in range(0, len(hex_text), 56):
                chunk = hex_text[i:i+56]
                chunk_bytes = len(chunk) // 2
                f.write(f"T{start_addr:06X}{chunk_bytes:02X}{chunk}\n")
                start_addr += chunk_bytes

            for r in self.relocations.get_all_list():
                f.write(f"M{r['address']:06X}08+{r['label'][:6]:<6}\n")

            f.write("E000000\n")

        print(f"Nesne dosyası oluşturuldu: {output_obj_file}")

    def save_symbols_to_txt(self, output_file):
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(f"{'Sembol':<15} | {'Adres':<10} | {'Tip':<10}\n")
            f.write("-" * 45 + "\n")
            for label, info in self.symbols.get_all().items():
                f.write(f"{label:<15} | 0x{info['address']:08X} | {info['type']:<10}\n")
        print(f"Sembol tablosu dosyası oluşturuldu: {output_file}")


class Linker:
    def __init__(self, text_base=0x0000):
        self.text_base = text_base
        self.merged_text = []
        self.global_symbols = {}
        self.reloc_queue = []

    def to_twos_complement(self, value, bits):
        return value & ((1 << bits) - 1)

    def encode_branch_hex(self, mnemonic, rs1_bin, rs2_bin, offset):
        funct3 = "000" if mnemonic == "beq" else "001"
        opcode = "1100011"
        imm13 = self.to_twos_complement(offset, 13)
        bit12 = (imm13 >> 12) & 1
        bit11 = (imm13 >> 11) & 1
        bits10_5 = (imm13 >> 5) & 0b111111
        bits4_1 = (imm13 >> 1) & 0b1111
        binary = (format(bit12, "01b") + format(bits10_5, "06b") + rs2_bin + rs1_bin +
                  funct3 + format(bits4_1, "04b") + format(bit11, "01b") + opcode)
        return f"{int(binary, 2):08X}"

    def encode_jal_hex(self, rd_bin, offset):
        opcode = "1101111"
        imm21 = self.to_twos_complement(offset, 21)
        bit20 = (imm21 >> 20) & 1
        bits10_1 = (imm21 >> 1) & 0b1111111111
        bit11 = (imm21 >> 11) & 1
        bits19_12 = (imm21 >> 12) & 0b11111111
        binary = (format(bit20, "01b") + format(bits10_1, "010b") + format(bit11, "01b") +
                  format(bits19_12, "08b") + rd_bin + opcode)
        return f"{int(binary, 2):08X}"

    def add_object(self, filename):
        with open(filename, "r", encoding="utf-8") as f:
            lines = f.readlines()
        current_offset = len(self.merged_text) * 4
        for line in lines:
            line = line.strip()
            if line == "": continue
            record_type = line[0]

            if record_type == "D":
                for i in range(1, len(line), 12):
                    chunk = line[i:i+12]
                    if len(chunk) >= 12:
                        name = chunk[:6].strip()
                        addr_text = chunk[6:12].strip()
                        local_addr = int(addr_text, 16)
                        self.global_symbols[name] = self.text_base + current_offset + local_addr

            elif record_type == "T":
                hex_data = line[9:].strip()
                for i in range(0, len(hex_data), 8):
                    word = hex_data[i:i + 8]
                    if len(word) == 8:
                        self.merged_text.append(word)

            elif record_type == "M":
                local_addr = int(line[1:7], 16)
                sign = line[9]
                label = line[10:16].strip()
                self.reloc_queue.append({
                    "address": current_offset + local_addr,
                    "sign": sign,
                    "label": label
                })

    def resolve_relocations(self):
        for r in self.reloc_queue:
            label = r["label"]
            target_addr = None
            for sym, addr in self.global_symbols.items():
                if sym.startswith(label) or label.startswith(sym):
                    target_addr = addr
                    break
            if target_addr is None:
                raise ValueError(f"Çözülemeyen external sembol: {label}")

            reloc_addr = r["address"]
            index = reloc_addr // 4
            hex_instr = self.merged_text[index]
            bin_instr = format(int(hex_instr, 16), "032b")
            
            opcode = bin_instr[25:32]
            offset = target_addr - reloc_addr

            if opcode == "1101111": 
                rd = bin_instr[20:25]
                new_hex = self.encode_jal_hex(rd, offset)
                self.merged_text[index] = new_hex
                
            elif opcode == "1100011": 
                rs2 = bin_instr[7:12]
                rs1 = bin_instr[12:17]
                funct3 = bin_instr[17:20]
                mnemonic = "beq" if funct3 == "000" else "bne"
                new_hex = self.encode_branch_hex(mnemonic, rs1, rs2, offset)
                self.merged_text[index] = new_hex
                
            else:
                print(f"Uyarı: Bilinmeyen opcode ({opcode}) için relocation yapılamadı.")
            print(f"Bağlama yapıldı: {label} reloc=0x{reloc_addr:06X} target=0x{target_addr:06X} new={self.merged_text[index]}")

    def generate_hex(self, output_file):
        with open(output_file, "w", encoding="utf-8") as f:
            for code in self.merged_text:
                f.write(code + "\n")
        print(f"Final makine kodu dosyası oluşturuldu: {output_file}")

    def save_global_symbols_to_txt(self, output_file):
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(f"{'Global Sembol':<15} | {'Kesin Adres':<12}\n")
            f.write("-" * 35 + "\n")
            for label, addr in self.global_symbols.items():
                f.write(f"{label:<15} | 0x{addr:08X}\n")
        print(f"Global sembol tablosu dosyası oluşturuldu: {output_file}")


if __name__ == "__main__":
    path = os.getcwd()

    asm_main = Assembler()
    asm_main.assemble(
        os.path.join(path, "main2.asm"),
        os.path.join(path, "main_nesne.obj")
    )
    asm_main.save_symbols_to_txt(os.path.join(path, "main_symbol.txt"))

    asm_fonk = Assembler()
    asm_fonk.assemble(
        os.path.join(path, "fonksiyon2.asm"),
        os.path.join(path, "fonk_nesne.obj")
    )
    asm_fonk.save_symbols_to_txt(os.path.join(path, "fonk_symbol.txt"))

    linker = Linker()
    linker.add_object(os.path.join(path, "main_nesne.obj"))
    linker.add_object(os.path.join(path, "fonk_nesne.obj"))
    linker.resolve_relocations()
    linker.save_global_symbols_to_txt(os.path.join(path, "global_symbol.txt"))
    linker.generate_hex(os.path.join(path, "makine_kodu.hex"))