library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library unisim;
use unisim.VCOMPONENTS.ALL;

entity SPI_Controller is
 Port (clk, rst, READ: in STD_LOGIC;
       si_i: inout STD_LOGIC;
       --si_o: out STD_LOGIC;
       BTN: in std_logic_vector(4 downto 0);
       cs_n: out STD_LOGIC;
       so, acc, hold, halt: in STD_LOGIC;
       SW: in STD_LOGIC_VECTOR(15 downto 0);
       LED: out STD_LOGIC_VECTOR(15 DOWNTO 0));
end SPI_Controller;

architecture Behavioral of SPI_Controller is

signal CFGCLK, CFGMCLK, EOS, PREQ, SCLK: std_logic;

component clk_wiz_0 is
port(clk_in1: in std_logic;
     locked, sclk: out std_logic);
end component;

signal read_command: std_logic_vector(7 downto 0) := (0=>'0', 1=>'1', 2=>'1', 3=>'0', 4=>'1',5=>'0',6=>'1',7=>'1');
signal address_signal: std_logic_vector(23 downto 0) := (others => '0');
signal command_ctr, address_ctr, data_1_ctr, data_2_ctr, dummy_ctr: natural := 0;

signal done_1_flag, done_2_flag: std_logic := '1';
signal data_register_1, data_register_2 : std_logic_vector(7 downto 0) := (others => '0');

type spi_states is (idle, command, address, data_out_1, data_out_2, dummy);
signal curr_state, next_state : spi_states := idle;
signal sckl_o,locked : std_logic;

signal s_clok_wat: std_logic := '0';
signal data_counter: natural := 0;

signal stop: std_logic := '0';

signal s_cs_n: std_logic := '0';

signal ff : std_logic_vector(1 downto 0);
signal counter_s : std_logic;
signal counter_o : std_logic_vector(30 downto 0) := (others => '0');

signal btn_debounced : std_logic := '0';

begin

cs_n <= s_cs_n;

--address_adder:process(clk) begin
--  if(rising_edge(clk)) then
--    if(BTN(0) = '1') then
--            address_signal <= std_logic_vector(unsigned(address_signal) + 1);
--    end if;
--  end if;
--end process;


address_signal <= (0 => SW(8), 1 => SW(9), 2 => SW(10), 3 => SW(11), 4 => SW(12), 5 => SW(13), OTHERS => '0');
clk_gen: clk_wiz_0 port map(clk_in1 => clk, sclk => sclk, locked => locked);

STARTUPE2_inst : STARTUPE2
   generic map (
      PROG_USR => "FALSE",    -- Activate program event security feature. Requires encrypted bitstreams.
      SIM_CCLK_FREQ => 10.0    -- Set the Configuration Clock Frequency(ns) for simulation.
   )
   port map (
      CFGCLK => open,                -- 1-bit output: Configuration main clock output
      CFGMCLK => open,               -- 1-bit output: Configuration internal oscillator clock output
      EOS => open,                   -- 1-bit output: Active high output signal indicating the End Of Startup.
      PREQ => open,                  -- 1-bit output: PROGRAM request to fabric output
      CLK => '0',                    -- 1-bit input: User start-up clock input
      GSR => '0',                    -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
      GTS => '0',                    -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
      KEYCLEARB => '0',              -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
      PACK => '0',                   -- 1-bit input: PROGRAM acknowledge input
      USRCCLKO => sclk,              -- 1-bit input: User CCLK input
      USRCCLKTS => '0',              -- 1-bit input: User CCLK 3-state enable input
      USRDONEO => '1',               -- 1-bit input: User DONE pin output control
      USRDONETS => '1'               -- 1-bit input: User DONE 3-state enable output
   );

process(sclk,rst) begin
    if(rst = '1') then
        curr_state <= idle;
    elsif(rising_edge(sclk)) then
        curr_state <= next_state;
    end if;
end process;


-- QUAD command if switch 2 is off, SINGLE READ if switch 2 is on
read_command <= (0=>'0', 1=>'1', 2=>'1', 3=>'0', 4=>'1',5=>'0',6=>'1',7=>'1') when sw(2) = '0' else 
                (6 => '1', 7=>'1', others => '0');

process(sclk, rst) begin
    if(rst = '1') then
        next_state <= idle;
        s_cs_n <= '1';
        si_i <= '0';
        command_ctr <= 0;
        address_ctr <= 0;
        data_1_ctr <= 0;
        data_2_ctr <= 0;
        dummy_ctr <= 0;
--       address_signal <= (1 => '1', others => '0');
    -- Try with falling edge
    elsif(rising_edge(sclk)) then
        case curr_state is
        when idle =>
        next_state <= idle;
        data_counter <= 0;
        if(BTN(1) = '1') then
        elsif(BTN(2) = '1') then
        elsif(BTN(3) = '1') then
            next_state <= command;
        elsif(BTN(4) = '1') then
        end if;
        command_ctr <= 0;
        address_ctr <= 0;
        data_1_ctr <= 0;
        data_2_ctr <= 0;
        dummy_ctr <= 0;
        s_cs_n <= '1';
  --      done_1_flag <= '1';
  --      done_2_flag <= '0';
        if(READ = '1') then
            next_state <= command;
        end if;
        when command =>
        s_cs_n <= '0';
        si_i <= read_command(command_ctr);
        command_ctr <= command_ctr + 1;
        next_state <= command;
        if(command_ctr = 7) then
            next_state <= address;
        end if;
        when address =>
            si_i <= address_signal(23 - address_ctr);
            address_ctr <= address_ctr + 1;
            next_state <= address;
            if(address_ctr = 23) then
                next_state <= data_out_1; --if freq is <= 50, then dummy is 0
            end if;
        when dummy =>
            next_state <= data_out_1;
            if(dummy_ctr = 6) then 
                next_state <= data_out_1;
            end if;
            dummy_ctr <= dummy_ctr + 1;
        when data_out_1 =>
            if(data_1_ctr = 1) then
                data_register_1(4) <= si_i;
                data_register_1(5) <= SO;
                data_register_1(6) <= ACC;
                data_register_1(7) <= HOLD;
                next_state <= data_out_2;
                data_counter <= data_counter + 1;
                if(data_counter = 12) then
             --       next_state <= data_out_2;
                end if;
                data_1_ctr <= 0;
                done_1_flag <= '1';
                done_2_flag <= '0';
            else
                done_1_flag <= '1';
                data_register_1(0) <= si_i;
                data_register_1(1) <= SO;
                data_register_1(2) <= ACC;
                data_register_1(3) <= HOLD;
                data_1_ctr <= 1;
                next_state <= data_out_1;
            end if;
        when data_out_2 =>
           s_cs_n <= '1';
           si_i <= '0';
  --         address_signal <= std_logic_vector(unsigned(address_signal) + 1);
           next_state <= idle;
           -- if(data_2_ctr = 7) then
           --     done_2_flag <= '1';
           --     done_1_flag <= '0';
           --     data_register_2(4) <= SI;
           --     data_register_2(5) <= SO;
           --     data_register_2(6) <= ACC;
           --     data_register_2(7) <= HOLD;
           --     if(read = '1') then
           --         next_state <= data_out_1;
           --     else
           --         next_state <= idle;
           --     end if;
           -- else
           --     done_2_flag <= '0';
           --     data_register_2(0) <= SI;
           --     data_register_2(1) <= SO;
           --     data_register_2(2) <= ACC;
           --     data_register_2(3) <= HOLD;
           --     data_2_ctr <= 1;
           -- end if;
        end case;
    end if;
end process;

LED <= data_register_1 & address_signal(7 downto 0);
end Behavioral;