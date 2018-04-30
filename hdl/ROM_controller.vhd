library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ROM_controller_SPI is
 Port (clk_25, rst, read: in STD_LOGIC;
       si_i: out STD_LOGIC;
       cs_n: out STD_LOGIC;
     --  so, acc, hold: in STD_LOGIC;
       wp: out std_logic;
       si_t: out std_logic;
       wp_t: out std_logic; 
       address_in: in STD_LOGIC_VECTOR(23 downto 0);
       qd: in STD_LOGIC_VECTOR(3 downto 0);
       data_out: out STD_LOGIC_VECTOR(63 downto 0);
       --pragma synthesis_off
        counter: out integer;
       --pragma synthesis_on
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
signal data_register_1, data_register_2 : std_logic_vector(63 downto 0) := (others => '0');
type spi_states is (idle, command, address, data_out_one_low, data_out_one_high, data_out_two, dummy, deasrt);
signal curr_state, next_state : spi_states := idle;
signal sckl_o,locked : std_logic;
signal s_t_si: std_logic;
signal s_clok_wat: std_logic := '0';
signal data_counter: natural := 0;

signal stop: std_logic := '0';

signal s_done: std_logic := '0';

signal retarded_counter : integer := 0;

signal one_clock_cycle: integer := 0;
signal s_read: std_logic;
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

read_proc: process(clk_25, rst, read) begin
    if(rst = '1') then
        one_clock_cycle <= 0;
        s_read <= '0';
    elsif(rising_edge(clk_25) and read = '1') then
        one_clock_cycle <= one_clock_cycle + 1;
        if(one_clock_cycle = 0) then
            s_read <= '1';
        elsif(one_clock_cycle = 1) then
            s_read <= '0';
        end if;
   end if;
end process;
                            

retarded_ctr_fsm: process(clk_25, rst, s_read) begin
  if(rst = '1') then
    cs_n <= '1';
    SCLK <= '0';
    si_t <= '0';
    wp_t <= '1';
 --   data_register_1 <= (others => '0');
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
        if(s_read = '1') then
          cs_n <= '0';
        end if;
        wp_t <= '1';
      when 1 => -- Wait for cs_n to propagate (?)
        cs_n <= '0';
      -- Opcode in starts
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
      -- Address_in starts
      when 10 =>
        --si_t <= '1';
        si_i <= address_in(23);
      when 11 =>
        si_i <= address_in(22);
      when 12 =>
        si_i <= address_in(21);
      when 13 =>
        si_i <= address_in(20);
      when 14 =>
        si_i <= address_in(19);
      when 15 =>
        si_i <= address_in(18);
      when 16 =>
        si_i <= address_in(17);
      when 17 =>
        si_i <= address_in(16);
      when 18 =>
        si_i <= address_in(15);
      when 19 =>
        si_i <= address_in(14);
      when 20 =>
        si_i <= address_in(13);
      when 21 =>
        si_i <= address_in(12);
      when 22 =>
        si_i <= address_in(11);
      when 23 =>
        si_i <= address_in(10);
      when 24 =>
        si_i <= address_in(9);
      when 25 =>
        si_i <= address_in(8);
      when 26 =>
        si_i <= address_in(7);
      when 27 =>
        si_i <= address_in(6);      
      when 28 =>
        si_i <= address_in(5);
      when 29 =>
        si_i <= address_in(4);
      when 30 =>
        si_i <= address_in(3);
      when 31 =>
        si_i <= address_in(2);
      when 32 =>
        si_i <= address_in(1);
      when 33 =>
        si_i <= address_in(0);
      when 34 =>
        si_t <= '1';

      -- Start of Data 
      -- Data comes out MSB first in bytes, like so
      -- [7][6][5][4][3][2][1][0] | [7][6][5][4][...]
      when 100 =>
        cs_n <= '1';
        done <= '1';
        data_out <= data_register_1;
        si_t <= '0';
      when others =>
      end case;
 end if;
 end process;
 
 process(clk_25) begin
    if(falling_edge(clk_25)) then
      -- Byte 2
      case retarded_counter is
      when 35 =>
        data_register_1(7) <= qd(1);
      when 36 =>
        data_register_1(6) <= qd(1);
      when 37 =>
        data_register_1(5) <= qd(1);
      when 38 =>
        data_register_1(4) <= qd(1);
      when 39 =>
        data_register_1(3) <= qd(1);
      when 40 =>
        data_register_1(2) <= qd(1);
      when 41 =>
        data_register_1(1) <= qd(1);
      when 42 =>
        data_register_1(0) <= qd(1);

      when 43 =>
        data_register_1(15) <= qd(1);   
      when 44 =>
        data_register_1(14) <= qd(1);   
      when 45 =>
        data_register_1(13) <= qd(1);   
      when 46 =>
        data_register_1(12) <= qd(1);   
      when 47 =>
        data_register_1(11) <= qd(1);   
      when 48 =>
        data_register_1(10) <= qd(1);   
      when 49 =>
        data_register_1(9) <= qd(1);   
      when 50 =>
        data_register_1(8) <= qd(1);  
      -- Byte 3
      when 51 =>
        data_register_1(23) <= qd(1);   
      when 52 =>
        data_register_1(22) <= qd(1);   
      when 53 =>
        data_register_1(21) <= qd(1);   
      when 54 =>
        data_register_1(20) <= qd(1);   
      when 55 =>
        data_register_1(19) <= qd(1);   
      when 56 =>
        data_register_1(18) <= qd(1);   
      when 57 =>
        data_register_1(17) <= qd(1);   
      when 58 =>
        data_register_1(16) <= qd(1);   
      -- Byte 4
      when 59 =>
        data_register_1(31) <= qd(1);   
      when 60 =>
        data_register_1(30) <= qd(1);   
      when 61 =>
        data_register_1(29) <= qd(1);   
      when 62 =>
        data_register_1(28) <= qd(1);   
      when 63 =>
        data_register_1(27) <= qd(1);   
      when 64 =>
        data_register_1(26) <= qd(1);   
      when 65 =>
        data_register_1(25) <= qd(1);   
      when 66 =>
        data_register_1(24) <= qd(1);           
      -- Byte 5
      when 67 =>
        data_register_1(39) <= qd(1);
      when 68 =>
        data_register_1(38) <= qd(1);           
      when 69 =>
        data_register_1(37) <= qd(1);   
      when 70 =>
        data_register_1(36) <= qd(1);           
      when 71 =>
        data_register_1(35) <= qd(1);   
      when 72 =>
        data_register_1(34) <= qd(1);           
      when 73 =>
        data_register_1(33) <= qd(1);   
      when 74 =>
        data_register_1(32) <= qd(1);      
      -- Byte 6     
      when 75 =>
        data_register_1(47) <= qd(1);   
      when 76 =>
        data_register_1(46) <= qd(1);           
      when 77 =>
        data_register_1(45) <= qd(1);   
      when 78 =>
        data_register_1(44) <= qd(1);           
      when 79 =>
        data_register_1(43) <= qd(1);   
      when 80 =>
        data_register_1(42) <= qd(1);           
      when 81 =>
        data_register_1(41) <= qd(1);   
      when 82 =>
        data_register_1(40) <= qd(1); 
      -- Byte 7          
      when 83 =>
        data_register_1(55) <= qd(1);   
      when 84 =>
        data_register_1(54) <= qd(1);           
      when 85 =>
        data_register_1(53) <= qd(1);   
      when 86 =>
        data_register_1(52) <= qd(1);           
      when 87 =>
        data_register_1(51) <= qd(1);   
      when 88 =>
        data_register_1(50) <= qd(1);           
      when 89 =>
        data_register_1(49) <= qd(1);   
      when 90 =>
        data_register_1(48) <= qd(1);
      -- Byte 8           
      when 91 =>
        data_register_1(63) <= qd(1);   
      when 92 =>
        data_register_1(62) <= qd(1);           
      when 93 =>
        data_register_1(61) <= qd(1);   
      when 94 =>
        data_register_1(60) <= qd(1);           
      when 95 =>
        data_register_1(59) <= qd(1);           
      when 96 =>
        data_register_1(58) <= qd(1);           
      when 97 =>
        data_register_1(57) <= qd(1);           
      when 98 =>
        data_register_1(56) <= qd(1);           
      when others =>
  end case; 
  end if;
end process;

-- QUAD command if switch 2 is off, SINGLE READ if switch 2 is on
read_command <= (0=>'0', 1=>'0', 2=>'0', 3=>'0', 4=>'0',5=>'0',6=>'1',7=>'1', 8 => '0');

--done <= s_done;
address_signal <= address_in;
--data_out <= data_register_1;

--pragma synthesis_off
    counter <= retarded_counter;
--pragma synthesis_on

end Behavioral;
