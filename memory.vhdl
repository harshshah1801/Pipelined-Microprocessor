library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
	port (Mem_Addr, Mem_Data: in std_logic_vector(15 downto 0);
			clk, rst, r_enable, w_enable: in std_logic;
			Mem_Out: out std_logic_vector(15 downto 0));
end entity memory;

architecture behav of memory is

type locations is array(0 to 31) of std_logic_vector(15 downto 0);
-- Add instructions below

signal Mem : locations := ("0110001011111111", "0001001001010000", "0101010001001000", "0100111001001000", "0001001010011000", "0001010011100000", "0001010011101000", "0001001001110000", "1101001111000000", "1100001111111111", "1000100101111111", "1000100110111111", others => "1110110101100111");

-- 0110 001 0 11111111
-- 0001 001 001 010 000 : R2 = R1 + R1
-- 0101 010 001 001000  : M(R1 + 8) = M(9) = R2
-- 0100 111 001 001000  : R7 = M(R1 + 8) = M(9)
-- 0001 001 010 011 000 : R3 = R1 + R2
-- 0001 010 011 100 000 : R4 = R2 + R3
-- 0001 010 011 101 000 : R5 = R2 + R3
-- 0001 001 001 110 000 : R6 = R1 + R1

-- 1101 001 111 000000
-- 1100 001 111111111   : R1 = PC + 2 = 0000000000000111, PC -= 2 REMOVE THIS INSTRUCTION TO TEST BEQ

-- 1000 100 101 111111  : if(R4 == R5)	PC -= 2
-- 1000 100 110 111111  : if(R4 == R6)	PC -= 2

begin
	process (clk, rst, r_enable, Mem_Addr, Mem_Data)
		begin
			if (rst = '1') then
				Mem(to_integer(unsigned(Mem_Addr(4 downto 0)))) <= "0000000000000000";
			elsif (clk'event and clk = '1') then
				if (w_enable = '1') then
					Mem(to_integer(unsigned(Mem_Addr(4 downto 0)))) <= Mem_Data;
				end if;
			end if ;
			
			if (r_enable = '1') then
					Mem_Out <= Mem(to_integer(unsigned(Mem_Addr(4 downto 0))));
			end if;
		end process;
end behav;