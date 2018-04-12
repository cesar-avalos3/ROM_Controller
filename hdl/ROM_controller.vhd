library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ROM_controller_SPI is
 Port (clk_25, rst, read: in STD_LOGIC;
       si_i: out STD_LOGIC;
       cs_n: out STD_LOGIC;
       so, acc, hold: in STD_LOGIC;
       wp: out std_logic;
       si_t: out std_logic;
       wp_t: out std_logic; 
       address_in: in STD_LOGIC_VECTOR(23 downto 0);
       qd: in STD_LOGIC_VECTOR(3 downto 0);
       data_out: out STD_LOGIC_VECTOR(15 downto 0);
     --  command_int, address_int, reg_one_int, reg_two_int: inout integer;
       done: out STD_LOGIC
       );
end ROM_controller_SPI;

architecture Behavioral of ROM_controller_SPI is

signal CFGCLK, CFGMCLK, EOS, PREQ: std_logic;
signal SCLK: std_logic := '0';
signal read_command: std_logic_vector(8 downto 0) := (0=>'0', 1=>'0', 2=>'0', 3=>'0', 4=>'0',5=>'0',6=>'1',7=>'1', 8 => '0');
signal address_signal: std_logic_vector(23 downto 0) := (others => '0');
signal command_ctr, address_ctr, data_1_ctr, data_2_ctr, dummy_ctr: natural := 0;

signal done_1_flag, done_2_flag: std_logic := '1';
signal data_register_1, data_register_2 : std_logic_vector(15 downto 0) := (others => '0');
type spi_states is (idle, command, address, data_out_one_low, data_out_one_high, data_out_two, dummy, deasrt);
signal curr_state, next_state : spi_states := idle;
signal sckl_o,locked : std_logic;
signal s_t_si: std_logic;
signal s_clok_wat: std_logic := '0';
signal data_counter: natural := 0;

signal stop: std_logic := '0';

signal s_done: std_logic := '0';

signal retarded_counter : integer := 0;

signal counter_s : std_logic;
signal counter_o : std_logic_vector(30 downto 0) := (others => '0');

begin

retarded_ctr_adder: process(clk_25, rst) begin
  if(rst = '1') then
      retarded_counter <= 0;
  elsif(rising_edge(clk_25)) then
      if(read = '1' and retarded_counter < 100) then
        retarded_counter <= retarded_counter + 1;
      end if;
  end if;
end process;

retarded_ctr_fsm: process(clk_25, rst) begin
  if(rst = '1') then
    cs_n <= '1';
    SCLK <= '0';
    si_t <= '0';
    wp_t <= '1';
    data_register_1 <= (OTHERS => '0');
  elsif(rising_edge(clk_25)) then
    if(retarded_counter > 0) then
       sclk <= sclk xor '1';
    end if;
    case retarded_counter is
      when 0 =>
        si_t <= '0';
        s_done <= '0';
        si_i <= '0';
        wp <= '0';
        cs_n <= '1';
        if(read = '1') then
          cs_n <= '0';
        end if;
        wp_t <= '1';
      when 1 => -- Wait for cs_n to propagate (?)
        cs_n <= '0';
      when 2 =>
        si_i <= '0';
      when 3 =>
        si_i <= '0';
      when 4 =>
        si_i <= '0';
      when 5 =>
        si_i <= '0';
      when 6 =>
        si_i <= '0';
      when 7 =>
        si_i <= '0';
      when 8 =>
        si_i <= '1';
      when 9 =>
        si_i <= '1';
      when 10 =>
        si_i <= '0';
  --      data_register_1(0) <= SO;
      when 11 =>
        si_i <= '0';
   --     data_register_1(1) <= SO;
      when 12 =>
        si_i <= '0';
   --     data_register_1(3) <= SO;
      when 13 =>
        si_i <= '0';
   --     data_register_1(4) <= SO;
      when 14 =>
        si_i <= '0';
   --     data_register_1(5) <= SO;
      when 15 =>
        si_i <= '0';
    --    data_register_1(6) <= SO;      
      when 16 =>
        si_i <= '0';
   --     data_register_1(7) <= SO;
      when 29 =>
        si_i <= address_in(5);
      when 30 =>
        si_i <= address_in(4);
      when 31 =>
        si_i <= address_in(3);
      when 32 =>
        si_i <= address_in(2);
      when 33 =>
        si_i <= address_in(1);
      when 34 =>
        si_i <= address_in(0);
      when others =>
    end case; 
  end if;
  if(falling_edge(clk_25)) then
    case retarded_counter is
  when 33 => 
    data_register_1(0) <= qd(1);
  when 34 =>
    data_register_1(1) <= qd(1);
  when 35 =>
    data_register_1(2) <= qd(1);
  when 36 =>
    data_register_1(3) <= qd(1);
  when 37 =>
    data_register_1(4) <= qd(1);
  when 38 =>
    data_register_1(5) <= qd(1);
  when 39 =>
    data_register_1(6) <= qd(1);      
  when 40 =>
    data_register_1(7) <= qd(1);   
  when 41 =>
    data_register_1(8) <= qd(1);   
  when 42 =>
    data_register_1(9) <= qd(1);   
  when 43 =>
    data_register_1(10) <= qd(1);   
  when 44 =>
    data_register_1(11) <= qd(1);   
  when 45 =>
    data_register_1(12) <= qd(1);   
  when 46 =>
    data_register_1(13) <= qd(1);   
  when 47 =>
    data_register_1(14) <= qd(1);   
  when 48 =>
    data_register_1(15) <= qd(1);   
  when 49 =>
    cs_n <= '1';
    done <= '1';
  when others =>
  end case; 
  end if;
end process;

-- QUAD command if switch 2 is off, SINGLE READ if switch 2 is on
read_command <= (0=>'0', 1=>'0', 2=>'0', 3=>'0', 4=>'0',5=>'0',6=>'1',7=>'1', 8 => '0');

done <= s_done;
address_signal <= address_in;
data_out <= data_register_1;
end Behavioral;