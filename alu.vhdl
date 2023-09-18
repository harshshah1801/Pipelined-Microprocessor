library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity ALU is
	generic(operand_width : integer:=16);
	port(ALU_op: in std_logic_vector(5 downto 0);
	  ALU_A: in std_logic_vector(15 downto 0);
	  ALU_B: in std_logic_vector(15 downto 0);
	  carry_in: in std_logic;
	  ALU_C: out std_logic_vector(15 downto 0);
	  ALU_zero: out std_logic;
	  ALU_carry: out std_logic);
end ALU;

architecture a1 of ALU is


function sub(ALU_A: in std_logic_vector(operand_width-1 downto 0);
ALU_B: in std_logic_vector(operand_width-1 downto 0))
return std_logic_vector is
-- declaring and initializing variables using aggregates
variable diff : std_logic_vector(operand_width+1 downto 0):= (others=>'0');

begin
	diff(0)	:= '1';
     L3: for i in 0 to (operand_width)-1 loop
					diff(i+2):= ALU_B(i) xor (not ALU_A(i)) xor diff(0);
					diff(0):= ((not ALU_A(i)) and ALU_B(i)) or ((not ALU_A(i)) and diff(0)) or (ALU_B(i) and diff(0));
				end loop L3;
		if diff(0)='1' then
			L4: for i in 0 to (operand_width)-1 loop
					diff(i+2):= ALU_B(i) xor (not ALU_A(i)) xor diff(0);
					diff(0):= ((not ALU_A(i)) and ALU_B(i)) or ((not ALU_A(i)) and diff(0)) or (ALU_B(i) and diff(0));
				end loop L4;
		-- ALU_carry<='0';
		end if;
		if diff(17 downto 2)="000000000000000" then
			diff(1):='1';
		else
			diff(1):='0';
		end if;
return diff;
end sub;

function add(ALU_A: in std_logic_vector(operand_width-1 downto 0);
ALU_B: in std_logic_vector(operand_width-1 downto 0); carry: in std_logic)
return std_logic_vector is
-- declaring and initializing variables using aggregates
variable addition : std_logic_vector(operand_width+1 downto 0):= (others=>'0');


begin
	addition(0):='0';
	if (carry='0') then
    	addition(17 downto 2) := ALU_A + ALU_B;
	else 
		addition(17 downto 2) := ALU_A + ALU_B  + "0000000000000001";
	end if;
	if addition="0000000000000000" then
		addition(1):='1';
	else
		addition(1):='0';
	end if;
	return addition;
end add;

function nand1(ALU_A: in std_logic_vector(operand_width-1 downto 0);
ALU_B: in std_logic_vector(operand_width-1 downto 0))
return std_logic_vector is
-- declaring and initializing variables using aggregates
variable nand_ans : std_logic_vector(operand_width+1 downto 0):= (others=>'0');

begin
		nand_ans(17 downto 2):= ALU_A nand ALU_B;
		if nand_ans(17 downto 2)="0000000000000000" then
			nand_ans(1):='1';
		else
			nand_ans(1):='0';
		end if;
return nand_ans;
end nand1;

function add_comp(ALU_A: in std_logic_vector(operand_width-1 downto 0);
ALU_B: in std_logic_vector(operand_width-1 downto 0); carry: in std_logic)
return std_logic_vector is
-- declaring and initializing variables using aggregates
variable addition : std_logic_vector(operand_width+1 downto 0):= (others=>'0');


begin
    addition(0):='0';
    if (carry='0') then
		addition(17 downto 2) := ALU_A + not(ALU_B);
    else
		addition(17 downto 2) := ALU_A + not(ALU_B) + "0000000000000001";
	end if;
	if addition="0000000000000000" then
		addition(1):='1';
	else
		addition(1):='0';
	end if;
	return addition;
end add_comp;

function nand_comp(ALU_A: in std_logic_vector(operand_width-1 downto 0);
ALU_B: in std_logic_vector(operand_width-1 downto 0))
return std_logic_vector is
-- declaring and initializing variables using aggregates
variable nand_ans : std_logic_vector(operand_width+1 downto 0):= (others=>'0');

begin
		nand_ans(17 downto 2):= ALU_A nand not(ALU_B);
		if nand_ans(17 downto 2)="0000000000000000" then
			nand_ans(1):='1';
		else
			nand_ans(1):='0';
		end if;
return nand_ans;
end nand_comp;




begin
alu : process( ALU_A, ALU_B, ALU_op)
variable ans: std_logic_vector(17 downto 0);
begin
	-- addition operation
	if (ALU_op="000000" or ALU_op="010000" or ALU_op="001000" or ALU_op="000010")then
		ans := add(ALU_A,ALU_B,'0');
		ALU_C <= ans(17 downto 2);
		ALU_carry <= ans(0);
		ALU_zero <= ans(1);
		
	-- add with carry operation
	elsif ALU_op="000100" then
		ans := add(ALU_A,ALU_B,carry_in);
		ALU_C <= ans(17 downto 2);
		ALU_carry <= ans(0);
		ALU_zero <= ans(1);
		
	-- addition with complement without carry
	elsif (ALU_op="000001" or ALU_op="010001" or ALU_op="001001")then
		ans := add_comp(ALU_A,ALU_B,'0');
		ALU_C <= ans(17 downto 2);
		ALU_carry <= ans(0);
		ALU_zero <= ans(1);
		
	-- add with complement with carry
	elsif ALU_op="000101" then
		ans := add_comp(ALU_A,ALU_B,carry_in);
		ALU_C <= ans(17 downto 2);
		ALU_carry <= ans(0);
		ALU_zero <= ans(1);
	-- nand
	elsif (ALU_op="100000" or ALU_op="110000" or ALU_op="101000")then
		ans := nand1(ALU_A,ALU_B);
		ALU_C <= ans(17 downto 2);
		ALU_carry <= ans(0);
		ALU_zero <= ans(1);	
	
	-- nand with complement 
	elsif (ALU_op="100001" or ALU_op="110001" or ALU_op="101001")then
		ans := nand_comp(ALU_A,ALU_B);
		ALU_C <= ans(17 downto 2);
		ALU_carry <= ans(0);
		ALU_zero <= ans(1);
		
	end if;
	
end process ; --alu
end a1 ; -- a1


-- addition operation without carry
	

