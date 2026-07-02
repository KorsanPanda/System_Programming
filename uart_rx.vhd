library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
    generic (
        CLK_FREQ  : integer := 27000000;
        BAUD_RATE : integer := 115200
    );
    port (
        clk      : in  std_logic;
        rstn     : in  std_logic;
        rx       : in  std_logic;
        rx_data  : out std_logic_vector(7 downto 0);
        rx_valid : out std_logic
    );
end uart_rx;

architecture Behavioral of uart_rx is
    constant CLOCKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
    
    type state_type is (IDLE, START, DATA, STOP);
    signal state : state_type := IDLE;
    
    signal clk_count : integer range 0 to CLOCKS_PER_BIT := 0;
    signal bit_index : integer range 0 to 7 := 0;
    signal rx_data_reg : std_logic_vector(7 downto 0) := (others => '0');

begin
    rx_data <= rx_data_reg;

    process(clk, rstn)
    begin
        if rstn = '0' then
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            rx_data_reg <= (others => '0');
            rx_valid <= '0';
        elsif rising_edge(clk) then
            rx_valid <= '0';
            case state is
                when IDLE =>
                    clk_count <= 0;
                    bit_index <= 0;
                    if rx = '0' then
                        state <= START;
                    end if;
                    
                when START =>
                    if clk_count = CLOCKS_PER_BIT / 2 then
                        if rx = '0' then
                            clk_count <= 0;
                            state <= DATA;
                        else
                            state <= IDLE;
                        end if;
                    else
                        clk_count <= clk_count + 1;
                    end if;
                    
                when DATA =>
                    if clk_count < CLOCKS_PER_BIT - 1 then
                        clk_count <= clk_count + 1;
                    else
                        clk_count <= 0;
                        rx_data_reg(bit_index) <= rx;
                        if bit_index < 7 then
                            bit_index <= bit_index + 1;
                        else
                            state <= STOP;
                        end if;
                    end if;
                    
                when STOP =>
                    if clk_count < CLOCKS_PER_BIT - 1 then
                        clk_count <= clk_count + 1;
                    else
                        rx_valid <= '1';
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;