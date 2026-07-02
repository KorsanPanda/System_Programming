library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity loader_fsm is
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
end loader_fsm;

architecture Behavioral of loader_fsm is
    constant TIMEOUT_MAX : integer := 2700000;

    signal byte_count      : integer range 0 to 4 := 0;
    signal assembled_data  : std_logic_vector(31 downto 0) := (others => '0');
    signal temp_data       : std_logic_vector(31 downto 0) := (others => '0');
    signal calc_checksum   : std_logic_vector(7 downto 0) := (others => '0');

    signal timeout_counter : integer range 0 to TIMEOUT_MAX := 0;
    signal addr_reg        : unsigned(31 downto 0) := (others => '0');

    signal mem_addr_reg    : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_wdata_reg   : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_we_reg      : std_logic := '0';
    signal cpu_resetn_reg  : std_logic := '0';
begin
    mem_addr   <= mem_addr_reg;
    mem_wdata  <= mem_wdata_reg;
    mem_we     <= mem_we_reg;
    cpu_resetn <= cpu_resetn_reg;

    process(clk, rstn)
    begin
        if rstn = '0' then
            byte_count      <= 0;
            assembled_data  <= (others => '0');
            temp_data       <= (others => '0');
            calc_checksum   <= (others => '0');
            timeout_counter <= 0;
            addr_reg        <= (others => '0');
            mem_addr_reg    <= (others => '0');
            mem_wdata_reg   <= (others => '0');
            mem_we_reg      <= '0';
            cpu_resetn_reg  <= '0';
        elsif rising_edge(clk) then
            mem_we_reg <= '0';
            if rx_valid = '1' then
                timeout_counter <= 0;
                cpu_resetn_reg  <= '0';

                case byte_count is
                    when 0 =>
                        temp_data(31 downto 24) <= rx_data;
                        calc_checksum <= rx_data;
                        byte_count <= 1;
                    when 1 =>
                        temp_data(23 downto 16) <= rx_data;
                        calc_checksum <= calc_checksum xor rx_data;
                        byte_count <= 2;
                    when 2 =>
                        temp_data(15 downto 8) <= rx_data;
                        calc_checksum <= calc_checksum xor rx_data;
                        byte_count <= 3;
                    when 3 =>
                        temp_data(7 downto 0) <= rx_data;
                        calc_checksum <= calc_checksum xor rx_data;
                        byte_count <= 4;
                    when 4 =>
                        assembled_data <= temp_data;
                        if rx_data = calc_checksum then
                            mem_addr_reg  <= std_logic_vector(addr_reg);
                            mem_wdata_reg <= temp_data;
                            mem_we_reg    <= '1';
                            addr_reg      <= addr_reg + to_unsigned(4, 32);
                        end if;
                        byte_count    <= 0;
                        calc_checksum <= (others => '0');
                    when others =>
                        byte_count <= 0;
                end case;
            else
                if cpu_resetn_reg = '0' then
                    if timeout_counter < TIMEOUT_MAX then
                        timeout_counter <= timeout_counter + 1;
                    else
                        if addr_reg > to_unsigned(0, 32) then
                            cpu_resetn_reg <= '1';
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;
end Behavioral;