----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/07/2018 09:48:32 PM
-- Design Name: 
-- Module Name: top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library unisim;
use unisim.VCOMPONENTS.ALL;


entity top is
 Port (clk: in std_logic;
       LED: out std_logic_vector(15 downto 0);
       SW: in std_logic_vector(15 downto 0);
       dq: inout STD_LOGIC_VECTOR(3 downto 0);
       cs_n: out STD_LOGIC);
end top;

architecture Behavioral of top is

component clk_wiz_0 is 
    Port(clk_in1: in std_logic;
         sclk: out std_logic;
         locked: out std_logic); 
end component;


component ROM_controller_SPI is
    PORT(clk_25, rst, read: in STD_LOGIC;
       si_i: out STD_LOGIC;
       si_t, wp_t: out STD_LOGIC;
       cs_n: out STD_LOGIC;
       wp: out STD_LOGIC;
       qd: in STD_LOGIC_VECTOR(3 downto 0);
       so, acc, hold: in STD_LOGIC;
       address_in: in STD_LOGIC_VECTOR(23 downto 0);
       data_out: out STD_LOGIC_VECTOR(15 downto 0);
       done: out STD_LOGIC);
end component;
signal clk_25: std_logic;
signal s_address_in: std_logic_vector(23 downto 0);
signal s_data_out: std_logic_vector(15 downto 0);
signal s_led_out: std_logic_vector(15 downto 0);
signal s_rst, s_read: std_logic;
signal clock_gate, gated_clock : std_logic := '1';
signal done: std_logic;
signal s_cs_n, s_t_si, s_t_wp: std_logic;
signal si,so,acc,hold,wp : std_logic;
signal locked: std_logic;
signal qd: std_logic_vector(3 downto 0);

begin

CLK_WIZ: clk_wiz_0 port map(clk_in1 => clk, sclk=>clk_25, locked=>locked); 

ROM_Controller_SPI_inst: ROM_controller_SPI port map(
        clk_25 => clk_25,
        rst => s_rst,
        read => s_read,
        si_i => si,
        wp => wp,
        cs_n => s_cs_n,
        qd => qd,
        si_t => s_t_si,
        wp_t => s_t_wp,
        so => so,
        acc => acc,
        hold => hold,
        address_in => s_address_in,
        data_out => LED,
        done => done); 
        
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
              USRCCLKO => gated_clock,       -- 1-bit input: User CCLK input
              USRCCLKTS => '0',              -- 1-bit input: User CCLK 3-state enable input
              USRDONEO => '1',               -- 1-bit input: User DONE pin output control
              USRDONETS => '0'               -- 1-bit input: User DONE 3-state enable output
           );
           
gated_clock <= '0' when clock_gate = '1' else not(clk_25); 

--sw(15) is my rst
process(clk_25, sw(15)) begin
    if(sw(15) = '1') then
        clock_gate <= '1';
    elsif(rising_edge(clk_25)) then
        if(s_cs_n = '0') then
            clock_gate <= '0';
        else
            clock_gate <= '1';
        end if;
    end if;
end process;

-- DQ is from us to the chip
dq(0) <= 'Z' when s_t_si = '1' else si;
dq(1) <= 'Z';
dq(2) <= 'Z' when s_t_wp = '1' else wp;  -- Not really used
dq(3) <= 'Z';                            -- Not really used

-- QD is from the chip to us
qd(0) <= dq(0) when s_t_si = '1' else 'Z';
qd(1) <= dq(1);
qd(2) <= dq(2) when s_t_wp = '1' else 'Z';
qd(3) <= dq(3);

cs_n <= s_cs_n;
s_rst <= SW(14);
s_read <= SW(13);
s_address_in(7 downto 0) <= SW(7 downto 0); 
end Behavioral;
