library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity ADDER_1 is
	generic(operand_width : integer:=16);
	port(ADDER_A: in std_logic_vector(15 downto 0);
	  ADDER_B: in std_logic_vector(15 downto 0);
	  ADDER_C: out std_logic_vector(15 downto 0));
end ADDER_1;

architecture a1 of ADDER_1 is

-- declaring and initializing variables using aggregates
begin
	ADDER_C <= ADDER_A+ ADDER_B;
end a1 ; -- a1