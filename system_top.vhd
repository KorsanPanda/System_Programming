library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity system_top is
    port (
        clk          : in  std_logic;
        rstn_btn     : in  std_logic;
        rx_pin       : in  std_logic; 
        tx_pin       : out std_logic; 
        led          : out std_logic_vector(5 downto 0);
        buton_giris  : in  std_logic  -- S2 Buton Girişi (Pin 4)
    );
end system_top;

architecture Structural of system_top is

    component uart_rx is
        port (
            clk      : in  std_logic;
            rstn     : in  std_logic;
            rx       : in  std_logic;
            rx_data  : out std_logic_vector(7 downto 0);
            rx_valid : out std_logic
        );
    end component;

    component uart_tx is
        generic (
            CLK_FREQ  : integer := 27000000;
            BAUD_RATE : integer := 115200
        );
        port (
            clk       : in  std_logic;
            rstn      : in  std_logic;
            tx_data   : in  std_logic_vector(7 downto 0);
            tx_start  : in  std_logic;
            tx_pin    : out std_logic;
            tx_busy   : out std_logic
        );
    end component;

    component loader_fsm is
        port (
            clk        : in  std_logic;
            rstn       : in  std_logic;
            rx_data    : in  std_logic_vector(7 downto 0);
            rx_valid   : in  std_logic;
            cpu_resetn : out std_logic;
            mem_addr   : out std_logic_vector(31 downto 0);
            mem_wdata  : out std_logic_vector(31 downto 0);
            mem_we     : out std_logic
        );
    end component;

    component picorv32 is
        generic (
            PROGADDR_RESET : std_logic_vector(31 downto 0) := x"00000000"
        );
        port (
            clk        : in  std_logic;
            resetn     : in  std_logic;
            trap       : out std_logic;
            mem_valid  : out std_logic;
            mem_instr  : out std_logic;
            mem_ready  : in  std_logic;
            mem_addr   : out std_logic_vector(31 downto 0);
            mem_wdata  : out std_logic_vector(31 downto 0);
            mem_wstrb  : out std_logic_vector(3 downto 0);
            mem_rdata  : in  std_logic_vector(31 downto 0);
            pcpi_wr    : in  std_logic;
            pcpi_rd    : in  std_logic_vector(31 downto 0);
            pcpi_wait  : in  std_logic;
            pcpi_ready : in  std_logic;
            irq        : in  std_logic_vector(31 downto 0)
        );
    end component;

    signal rx_data_sig : std_logic_vector(7 downto 0);
    signal rx_valid_sig : std_logic;
    signal cpu_resetn_sig : std_logic;
    
    signal tx_data_sig : std_logic_vector(7 downto 0);
    signal tx_start_sig : std_logic;
    signal tx_busy_sig : std_logic;
    
    signal loader_mem_addr  : std_logic_vector(31 downto 0);
    signal loader_mem_wdata : std_logic_vector(31 downto 0);
    signal loader_mem_we    : std_logic;

    signal cpu_mem_addr  : std_logic_vector(31 downto 0);
    signal cpu_mem_wdata : std_logic_vector(31 downto 0);
    signal cpu_mem_wstrb : std_logic_vector(3 downto 0);
    signal cpu_mem_rdata : std_logic_vector(31 downto 0);
    
    signal cpu_mem_valid : std_logic;
    signal cpu_mem_ready : std_logic := '0';
    
    signal final_mem_addr  : std_logic_vector(31 downto 0);
    signal final_mem_wdata : std_logic_vector(31 downto 0);
    signal final_mem_we    : std_logic_vector(3 downto 0); -- DÜZELTİLDİ: Hata giderildi!
    
    signal word_addr : integer range 0 to 4095;
    signal led_reg : std_logic_vector(5 downto 0) := (others => '0');

    type ram_type is array (0 to 4095) of std_logic_vector(31 downto 0);
    signal ram : ram_type := (others => (others => '0'));
    signal ram_read_data : std_logic_vector(31 downto 0) := (others => '0');

    -- Asenkron buton sinyali için senkronizasyon register'ları
    signal btn_sync_0 : std_logic := '1';
    signal btn_sync_1 : std_logic := '1';

begin
    led <= not led_reg;

    u_uart : uart_rx port map (
        clk => clk, rstn => rstn_btn, rx => rx_pin,
        rx_data => rx_data_sig, rx_valid => rx_valid_sig
    );

    u_uart_tx : uart_tx port map (
        clk => clk, rstn => rstn_btn,
        tx_data => tx_data_sig, tx_start => tx_start_sig,
        tx_pin => tx_pin, tx_busy => tx_busy_sig
    );

    u_loader : loader_fsm port map (
        clk => clk, rstn => rstn_btn, rx_data => rx_data_sig, rx_valid => rx_valid_sig,
        cpu_resetn => cpu_resetn_sig, mem_addr => loader_mem_addr, mem_wdata => loader_mem_wdata, mem_we => loader_mem_we
    );

    u_picorv32 : picorv32
        generic map ( PROGADDR_RESET => x"00000000" )
        port map (
            clk => clk, resetn => cpu_resetn_sig, trap => open, 
            mem_valid => cpu_mem_valid,
            mem_instr => open,
            mem_ready => cpu_mem_ready,
            mem_addr => cpu_mem_addr, mem_wdata => cpu_mem_wdata,
            mem_wstrb => cpu_mem_wstrb, mem_rdata => cpu_mem_rdata,
            pcpi_wr => '0', pcpi_rd => x"00000000", pcpi_wait => '0', pcpi_ready => '0', irq => x"00000000"
        );

    final_mem_addr  <= cpu_mem_addr when cpu_resetn_sig = '1' else loader_mem_addr;
    final_mem_wdata <= cpu_mem_wdata when cpu_resetn_sig = '1' else loader_mem_wdata;
    
    process(cpu_resetn_sig, cpu_mem_wstrb, loader_mem_we)
    begin
        if cpu_resetn_sig = '1' then
            final_mem_we <= cpu_mem_wstrb;
        else
            if loader_mem_we = '1' then final_mem_we <= "1111";
            else final_mem_we <= "0000"; end if;
        end if;
    end process;

    word_addr <= to_integer(unsigned(final_mem_addr(13 downto 2)));
    
    -- Buton okuma adresi 
    cpu_mem_rdata <= (31 downto 1 => '0') & btn_sync_1 when cpu_mem_addr = x"FFFFFF00" else ram_read_data;

    process(clk)
    begin
        if rising_edge(clk) then
            
            -- Buton sinyal senkronizasyonu
            btn_sync_0 <= buton_giris;
            btn_sync_1 <= btn_sync_0;
            
            -- BRAM Zamanlama Pulse Handshake
            if cpu_mem_valid = '1
' and cpu_mem_ready = '0' then
                cpu_mem_ready <= '1';
            else
                cpu_mem_ready <= '0';
            end if;

            -- BRAM Yazma İşlemleri
            if unsigned(final_mem_addr) < 16384 then
                if final_mem_we(0) = '1' then ram(word_addr)(7 downto 0)   <= final_mem_wdata(7 downto 0);   end if;
                if final_mem_we(1) = '1' then ram(word_addr)(15 downto 8)  <= final_mem_wdata(15 downto 8);  end if;
                if final_mem_we(2) = '1' then ram(word_addr)(23 downto 16) <= final_mem_wdata(23 downto 16); end if;
                if final_mem_we(3) = '1' then ram(word_addr)(31 downto 24) <= final_mem_wdata(31 downto 24); end if;
            end if;
            ram_read_data <= ram(word_addr);

            -- Çevre Birimleri Yazma Portları 
            if tx_busy_sig = '1' then
                tx_start_sig <= '0';
            end if;

            if cpu_resetn_sig = '1' and final_mem_we(0) = '1' then
                if cpu_mem_addr = x"FFFFFF80" then
                    led_reg <= cpu_mem_wdata(5 downto 0);
                    
                elsif cpu_mem_addr = x"FFFFFF84" then
                    if tx_busy_sig = '0' and tx_start_sig = '0' then
                        tx_data_sig  <= cpu_mem_wdata(7 downto 0);
                        tx_start_sig <= '1'; 
                    end if;
                end if;
            end if;
            
        end if;
    end process;

end Structural;