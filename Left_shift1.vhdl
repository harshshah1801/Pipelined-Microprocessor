library ieee;
use ieee.std_logic_1164.all;

entity Left_shift_1 is
   port(ip: in std_logic_vector(15 downto 0);
			op: out std_logic_vector(15 downto 0));
end entity;

architecture Struct of Left_shift_1 is

begin
	op(15 downto 1) <= ip(14 downto 0);
	
	op(0) <= '0';
	
end Struct;