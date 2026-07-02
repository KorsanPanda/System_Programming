library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
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
end uart_tx;

architecture Behavioral of uart_tx is
    constant CLOCKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
    
    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : state_type := IDLE;
    
    signal clk_count : integer range 0 to CLOCKS_PER_BIT := 0;
    signal bit_index : integer range 0 to 7 := 0;
    signal tx_reg    : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_out    : std_logic := '1';

begin
    tx_pin  <= tx_out;
    tx_busy <= '1' when state /= IDLE else '0';

    process(clk, rstn)
    begin
        if rstn = '0' then
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            tx_out <= '1';
            tx_reg <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    tx_out <= '1';
                    clk_count <= 0;
                    bit_index <= 0;
                    if tx_start = '1' then
                        tx_reg <= tx_data;
                        state <= START_BIT;
                    end if;
                    
                when START_BIT =>
                    tx_out <= '0'; -- Start biti her zaman 0'dır
                    if clk_count < CLOCKS_PER_BIT - 1 then
                        clk_count <= clk_count + 1;
                    else
                        clk_count <= 0;
                        state <= DATA_BITS;
                    end if;
                    
                when DATA_BITS =>
                    tx_out <= tx_reg(bit_index);
                    if clk_count < CLOCKS_PER_BIT - 1 then
                        clk_count <= clk_count + 1;
                    else
                        clk_count <= 0;
                        if bit_index < 7 then
                            bit_index <= bit_index + 1;
                        else
                            state <= STOP_BIT;
                        end if;
                    end if;
                    
                when STOP_BIT =>
                    tx_out <= '1'; -- Stop biti her zaman 1'dir
                    if clk_count < CLOCKS_PER_BIT - 1 then
                        clk_count <= clk_count + 1;
                    else
                        clk_count <= 0;
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;