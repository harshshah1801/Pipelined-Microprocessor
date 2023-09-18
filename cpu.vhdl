-- xx_yy_pipe and xx_yy are same and are the pipeline registers
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
	generic(operand_width : integer := 16);
	port(reset: in std_logic; clk: out std_logic;
		  Register_0, Register_1, Register_2, Register_3, Register_4, 
		  Register_5, Register_6, Register_7: out std_logic_vector(15 downto 0));
end entity cpu;

architecture bhv of cpu is 
--Memory
component memory is
	port (Mem_Addr, Mem_Data: in std_logic_vector(operand_width-1 downto 0);
			clk, rst, r_enable, w_enable: in std_logic;
			Mem_Out: out std_logic_vector(operand_width-1 downto 0));
end component memory;


--Register file
component reg_file is
	port (RF_A0, RF_A1, RF_A2, RF_A3, RF_A4: in std_logic_vector(2 downto 0);
			RF_D3, RF_D4: in std_logic_vector(15 downto 0);
			clk, rst, we: in std_logic;
			RF_D0, RF_D1, RF_D2: out std_logic_vector(15 downto 0);
			R0, R1, R2, R3, R4, R5, R6, R7: out std_logic_vector(15 downto 0));
end component reg_file;

--DeMux
component demux18 is
	port (inp: in std_logic_vector(operand_width-1 downto 0);
			A: in std_logic_vector(2 downto 0);
			outp1: out std_logic_vector(operand_width-1 downto 0);
			outp2: out std_logic_vector(operand_width-1 downto 0);
			outp3: out std_logic_vector(operand_width-1 downto 0);
			outp4: out std_logic_vector(operand_width-1 downto 0);
			outp5: out std_logic_vector(operand_width-1 downto 0);
			outp6: out std_logic_vector(operand_width-1 downto 0);
			outp7: out std_logic_vector(operand_width-1 downto 0);
			outp8: out std_logic_vector(operand_width-1 downto 0));
end component demux18;

--ALU
--00:ADD
--01:SUBTRACT
--10:NAND
--11:SHIFTER_LEFT_7
component ALU is
	generic(operand_width : integer:=16);
	port(ALU_op: in std_logic_vector(5 downto 0);
	  ALU_A: in std_logic_vector(operand_width-1 downto 0);
	  ALU_B: in std_logic_vector(operand_width-1 downto 0);
	  carry_in: in std_logic;
	  ALU_C: out std_logic_vector(operand_width-1 downto 0);
	  ALU_zero: out std_logic;
	  ALU_carry: out std_logic);
end component ALU;

component ADDER_1 is
	generic(operand_width : integer:=16);
	port(ADDER_A: in std_logic_vector(15 downto 0);
	  ADDER_B: in std_logic_vector(15 downto 0);
	  ADDER_C: out std_logic_vector(15 downto 0));
end component ADDER_1;

component Sign_Extension_10 is
	port(ip: in std_logic_vector(operand_width-11 downto 0);
			 op: out std_logic_vector(operand_width-1 downto 0));
 end component;

component Sign_Extension_7 is
	port(ip: in std_logic_vector(operand_width-8 downto 0);
			 op: out std_logic_vector(operand_width-1 downto 0));
end component;

component Left_shift_1 is
   port(ip: in std_logic_vector(15 downto 0);
			op: out std_logic_vector(15 downto 0));
end component;

signal read_0, read_1, read_2, write_1, write_2: std_logic_vector(2 downto 0);

--sign extender
signal SE10_inp: std_logic_vector(operand_width-11 downto 0);
signal SE7_inp: std_logic_vector(operand_width-8 downto 0);
signal clock: std_logic := '1';
signal stall, repeat, start, remove: std_logic := '0';
signal mem: std_logic_vector(4 downto 0);
signal reg_we, mem_re, d_mem_re, mem_we, d_mem_we, alu_zflag, alu_cflag, z_flag, c_flag,carry_in, change_if_rising, change_if_falling: std_logic := '0';
signal mem_inp, d_mem_inp, mem_read, d_mem_read, mem_store, d_mem_store, outp_0, outp_1, outp_2, inp_1, inp_2, alu_inp1, alu_inp2, alu_outp1, SE10_outp, SE7_outp, add_a, add_b, add_c, add_a2, add_b2, add_c2, instr, ls_i, ls_o, temp_D, temp_Q, lm_sm_reg_temp, lm_sm_reg, pc_reassign: std_logic_vector(operand_width-1 downto 0) := "0000000000000000";
signal alu_op: std_logic_vector(5 downto 0);
signal if_id_temp, if_id: std_logic_vector(2*operand_width-1 downto 0);
signal id_rr, id_rr_temp: std_logic_vector(2*operand_width-1+11 downto 0);
--id_rr, id_rr_temp first six bits are control bits
signal rr_ex, rr_ex_temp: std_logic_vector(4*operand_width-1+11 downto 0);
signal ex_ma, ex_ma_temp: std_logic_vector(3*operand_width-1+5 downto 0);
signal ma_wb, ma_wb_temp: std_logic_vector(3*operand_width+4 downto 0);

begin

RF1: reg_file port map (RF_A0=>read_0, RF_A1=>read_1, RF_A2=>read_2, RF_A3=>write_1, RF_A4=>write_2, RF_D3=>inp_1, RF_D4=>inp_2, clk=>clock, rst=>reset, we=>reg_we, RF_D0=>outp_0, RF_D1=>outp_1, RF_D2=>outp_2, 
								R0 => Register_0, R1 => Register_1, R2 => Register_2, 
								R3 => Register_3, R4 => Register_4, R5 => Register_5, 
								R6 => Register_6, R7 => Register_7);
		
--Instruction Memory
Mem1: memory port map (Mem_Addr=>mem_inp, Mem_Data=>mem_store,clk=> clock, rst=>reset, r_enable=>mem_re, w_enable=>mem_we, Mem_Out=> mem_read);
--Data Memory
Data_Mem : memory port map(Mem_Addr=>d_mem_inp, Mem_Data=>d_mem_store,clk=> clock, rst=>reset, r_enable=>d_mem_re, w_enable=>d_mem_we, Mem_Out=> d_mem_read);
ADDER1: ADDER_1 port map (ADDER_A=>add_a, ADDER_B=> add_b, ADDER_C=> add_c);
ADDER2: ADDER_1 port map (ADDER_A=>add_a2, ADDER_B=> add_b2, ADDER_C=> add_c2);
SE10: Sign_Extension_10 port map (ip => SE10_inp, op => SE10_outp);
SE7: Sign_Extension_7 port map (ip => SE7_inp, op => SE7_outp);
Left_shifter: Left_shift_1 port map (ip => ls_i, op => ls_o);
alu1: ALU port map (ALU_op=>alu_op,
	  ALU_A=>alu_inp1,
	  ALU_B=>alu_inp2,
	  carry_in=>carry_in,
	  ALU_C=>alu_outp1,
	  ALU_zero=>alu_zflag,
	  ALU_carry=>alu_cflag);

clk <= clock;
clock <= not clock after 10ns;

clock_proc: process(clock)
begin
	if(clock' event and clock = '1') then
		change_if_rising <= not change_if_rising;
	elsif(clock' event and clock = '0') then
		change_if_falling <= not change_if_falling;
	end if;
end process clock_proc;

fetch: process(change_if_rising, outp_0, add_c, add_c2, stall, repeat)
begin
	read_0 <= "000";
	mem_inp <= outp_0;
	mem_re <= '1';
	mem_we <= '0';
	if_id_temp(2*operand_width-1 downto operand_width) <= mem_read;
	instr <= mem_read;
	if_id_temp(operand_width-1 downto 0) <= outp_0;
	
	add_a <= outp_0;
	add_b <= "0000000000000001";
	
	write_1 <= "000";

---------------------------------------------------------------------------------------------------
	if(stall = '1') then
		inp_1 <= add_c2;
	elsif(repeat = '1') then
		inp_1 <= pc_reassign;
	elsif(ma_wb(18 downto 12) = "1110110" and ma_wb(0) = '1') then
		inp_1 <= ma_wb(3*operand_width-1 downto 2*operand_width);
	else
		inp_1 <= add_c; -- pc is inp_1
	end if;
---------------------------------------------------------------------------------------------------
	
	reg_we <= '1';
end process fetch;





if_id_update: process(change_if_falling, remove)
begin
	if(stall = '1' or remove = '1') then
		if_id(2*operand_width-1 downto 2*operand_width-4) <= "1110";
	else
		if_id <= if_id_temp; --if_id_temp is 32 bit
	end if;
	-- if_id = instr+pc		(2*operand_width)
end process if_id_update;





-- in ID stage we assign control bits to the instructions and store them in the next pipeline rg
-- First 5 control bits are for - 
--1) MUX_SE - to check if we want to do which sign extension(0 for 10bit extension and 1 for 7bit extension)
--2) MUX_BEQ- to check if we are going to branch or not
--3) MUX_ALU- to take value of Ra from register or SE(imm) (0 for Register and 1 for SE)
--4) MEM_WR - control bit for writing to memory
--5) MUX_WB - to write back value to register from result of memory or alu(0 for alu and 1 for mem)

instruction_decode: process(change_if_rising)
begin 
	id_rr_temp(2*operand_width-1 downto 0) <= if_id(2*operand_width-1 downto 0);
	-- add
	if (if_id(2*operand_width-1 downto 2*operand_width-4) = "0001")  then
		id_rr_temp(2*operand_width-1+11 downto 2*operand_width-1+7) <= "00000";
		if (if_id(operand_width+2 downto operand_width) = "000") then
			id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="000000"; -- +6 
		elsif (if_id(operand_width+2 downto operand_width) = "010") then 
			id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="010000";
		elsif (if_id(operand_width+2 downto operand_width) = "001") then 
			id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="001000";
		elsif (if_id(operand_width+2 downto operand_width) = "011") then 
			id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="000100";
		elsif (if_id(operand_width+2 downto operand_width) = "100") then 
			id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="000001";
		elsif (if_id(operand_width+2 downto operand_width) = "110") then 
			id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="010001";
		elsif (if_id(operand_width+2 downto operand_width) = "101") then 
			id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="001001";
		elsif (if_id(operand_width+2 downto operand_width) = "111") then 
			id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="000101";	
		end if;
	-- nand
	elsif ( if_id(2*operand_width-1 downto 2*operand_width-4) = "0010" ) then
		id_rr_temp(2*operand_width-1+11 downto 2*operand_width-1+7) <= "00000";
		if (if_id(operand_width+2 downto operand_width) = "000") then
			id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="100000"; -- +6 
		elsif (if_id(operand_width+2 downto operand_width) = "010") then 
			id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="110000";
		elsif (if_id(operand_width+2 downto operand_width) = "001") then 
			id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="101000";
		elsif (if_id(operand_width+2 downto operand_width) = "100") then 
			id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="100001";
		elsif (if_id(operand_width+2 downto operand_width) = "110") then 
			id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="110001";
		elsif (if_id(operand_width+2 downto operand_width) = "101") then 
			id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="101001";
		end if;
	--adi
	elsif (if_id(2*operand_width-1 downto 2*operand_width-4) = "0000") then
		id_rr_temp(2*operand_width-1+11 downto 2*operand_width-1+7) <= "00100";
		id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="000000";
	--lli
	elsif (if_id(2*operand_width-1 downto 2*operand_width-4) = "0011") then	
		id_rr_temp(2*operand_width-1+11 downto 2*operand_width-1+7) <= "10100"; 
		id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="000000"; 
	--lw
	elsif (if_id(2*operand_width-1 downto 2*operand_width-4) = "0100") then	
		id_rr_temp(2*operand_width-1+11 downto 2*operand_width-1+7) <= "00101";
		id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="000000";

	--beq,blt,ble
	--Here last 2 bits are set to a contradiction
	--MUX_BEQ=0 initially, branch_pred can be implemented here as well
	elsif (if_id(2*operand_width-1 downto 2*operand_width-2) = "10") then
		id_rr_temp(2*operand_width-1+11 downto 2*operand_width-1+7) <= "00011";
		id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="000000";
		
	
	--JAL
	elsif (if_id(2*operand_width-1 downto 2*operand_width-4) = "1100") then
		id_rr_temp(2*operand_width-1+11 downto 2*operand_width-1+7) <= "01100";
		id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <= "000000";
		
	--JLR
	elsif (if_id(2*operand_width-1 downto 2*operand_width-4) = "1101") then
		id_rr_temp(2*operand_width-1+11 downto 2*operand_width-1+7) <= "01000";
		id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <= "000000";
	--sw
	elsif (if_id(2*operand_width-1 downto 2*operand_width-4) = "0101") then	
		id_rr_temp(2*operand_width-1+11 downto 2*operand_width-1+7) <= "00110"; 
		id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="000000";  
		-- CONTROL SIGNALS FOR MEMERY_ACCESS NOT YET ASSIGNED
	-- lm
	elsif (if_id(2*operand_width-1 downto 2*operand_width-4) = "0110") then	
		id_rr_temp(2*operand_width-1+11 downto 2*operand_width-1+7) <= "00001"; 
		id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="000000"; 
		
	-- sm
	elsif (if_id(2*operand_width-1 downto 2*operand_width-4) = "0111") then	
		id_rr_temp(2*operand_width-1+11 downto 2*operand_width-1+7) <= "00010";                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
		id_rr_temp(2*operand_width-1+6 downto 2*operand_width) <="000000";
	
	end if;
end process	instruction_decode;-- id_rr =  ma_control_bits + alu_control_bits + instr + pc 		(5+6+2*operand_width)end process instruction_decode;




id_rr_update: process(change_if_falling)
begin
	if(stall = '1') then
		id_rr(2*operand_width-1 downto 2*operand_width-4) <= "1110";
	else
		id_rr <= id_rr_temp;
	end if;
	
---------------------------------------------------------------------------------------------------
	-- for lm,sm we need to stall the cycles and add the current PC to an temporary register which we can increment to get values for loading or storing from different registers
	if(id_rr_temp(2*operand_width-1 downto 2*operand_width-3) = "011") then
		if(repeat = '0' and not(rr_ex_temp(2*operand_width-1 downto 2*operand_width-3) = "011")) then
			start <= '1';
			remove <= '1';
			repeat <= '1';
			pc_reassign <= id_rr_temp(operand_width-1 downto 0);
--		elsif(ma_wb(18 downto 16) = "111") then
--			repeat <= '0';
		end if;
	end if;
	
	if(repeat = '1' and ma_wb(18 downto 16) = "110") then
		repeat <= '0';
	end if;
	
	if(remove = '1') then
		remove <= '0';
	end if;
	
	if(ex_ma_temp(operand_width-1 downto operand_width-3) = "011" and start = '1') then
		start <= '0';
	end if;
---------------------------------------------------------------------------------------------------
end process id_rr_update;




--rr_ex=11 control bits+ valu of r_a + value of r_b + instr+ pc(74 bits)
register_read: process(change_if_rising, outp_1, outp_2, alu_outp1)
begin
	rr_ex_temp(4*operand_width-1+11 downto 4*operand_width) <= id_rr(2*operand_width-1+11 downto 2*operand_width); -- control bits(11)
	rr_ex_temp(2*operand_width-1 downto 0) <= id_rr(2*operand_width-1 downto 0);-- Intsr and PC passed to rr_ex	
	read_1 <= id_rr(2*operand_width-5 downto 2*operand_width-7); --reads value of Ra
	read_2 <= id_rr(2*operand_width-8 downto 2*operand_width-10);--reads value of Rb                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
	
-- Below we have implemented data forwarding in which we check if there is any dependency on previous instructions,
-- and if there is, then we get the value directly from the corresponding stage but in an order sequence. Suppose we
-- have register dependency on previous instruction and the one before the previous as well, then we'll have to
-- consider the value written in previous instruction because it is the latest updated one.
	
	-- ISSUE OVER HERE: CHECK WHETHER RHS IS REALLY SIGNIFYING THE LOCATION WHERE WE ARE WRITING
	-- Data forwarding for Ra
	if(((rr_ex(2*operand_width-1 downto 2*operand_width-4) = "0010" or rr_ex(2*operand_width-1 downto 2*operand_width-4) = "0001") and read_1 = rr_ex(operand_width+5 downto operand_width+3)) or
		((rr_ex(2*operand_width-1 downto 2*operand_width-3) = "110" or rr_ex(2*operand_width-1 downto 2*operand_width-4) = "0011" or rr_ex(2*operand_width-1 downto 2*operand_width-4) = "0100") and read_1 = rr_ex(operand_width+11 downto operand_width+9)) or
		(rr_ex(2*operand_width-1 downto 2*operand_width-4) = "0000" and read_1 = rr_ex(operand_width+8 downto operand_width+6))) then
		
		rr_ex_temp(4*operand_width-1 downto 3*operand_width) <= alu_outp1;
		
	elsif(((ex_ma(operand_width-1 downto operand_width-4) = "0010" or ex_ma(operand_width-1 downto operand_width-4) = "0001") and read_1 = ex_ma(5 downto 3)) or
		  ((ex_ma(operand_width-1 downto operand_width-3) = "110" or ex_ma(operand_width-1 downto operand_width-4) = "0011" or ex_ma(operand_width-1 downto operand_width-4) = "0100") and read_1 = ex_ma(11 downto 9)) or
		   (ex_ma(operand_width-1 downto operand_width-4) = "0000" and read_1 = ex_ma(8 downto 6))) then
		
		rr_ex_temp(4*operand_width-1 downto 3*operand_width) <= ex_ma(2*operand_width-1 downto operand_width);
	
	elsif(((ma_wb(operand_width-1 downto operand_width-4) = "0010" or ma_wb(operand_width-1 downto operand_width-4) = "0001") and read_1 = ma_wb(5 downto 3)) or
		  ((ma_wb(operand_width-1 downto operand_width-3) = "110" or ma_wb(operand_width-1 downto operand_width-4) = "0011" or ma_wb(operand_width-1 downto operand_width-4) = "0100") and read_1 = ma_wb(11 downto 9)) or
		   (ma_wb(operand_width-1 downto operand_width-4) = "0000" and read_1 = ma_wb(8 downto 6))) then
	
		rr_ex_temp(4*operand_width-1 downto 3*operand_width) <= ma_wb(2*operand_width-1 downto operand_width);
	
	else
	
		rr_ex_temp(4*operand_width-1 downto 3*operand_width) <= outp_1; --stores value of Ra
	
	end if;
	
	-- Data forwarding for Rb
	if(((rr_ex(2*operand_width-1 downto 2*operand_width-4) = "0010" or rr_ex(2*operand_width-1 downto 2*operand_width-4) = "0001") and read_2 = rr_ex(operand_width+5 downto operand_width+3)) or
		((rr_ex(2*operand_width-1 downto 2*operand_width-3) = "110" or rr_ex(2*operand_width-1 downto 2*operand_width-4) = "0011" or rr_ex(2*operand_width-1 downto 2*operand_width-4) = "0100") and read_2 = rr_ex(operand_width+11 downto operand_width+9)) or
		(rr_ex(2*operand_width-1 downto 2*operand_width-4) = "0000" and read_2 = rr_ex(operand_width+8 downto operand_width+6))) then
		
		rr_ex_temp(3*operand_width-1 downto 2*operand_width) <= alu_outp1;
		
	elsif(((ex_ma(operand_width-1 downto operand_width-4) = "0010" or ex_ma(operand_width-1 downto operand_width-4) = "0001") and read_2 = ex_ma(5 downto 3)) or
		  ((ex_ma(operand_width-1 downto operand_width-3) = "110" or ex_ma(operand_width-1 downto operand_width-4) = "0011" or ex_ma(operand_width-1 downto operand_width-4) = "0100") and read_2 = ex_ma(11 downto 9)) or
		   (ex_ma(operand_width-1 downto operand_width-4) = "0000" and read_2 = ex_ma(8 downto 6))) then
		
		rr_ex_temp(3*operand_width-1 downto 2*operand_width) <= ex_ma(2*operand_width-1 downto operand_width);
	
	elsif(((ma_wb(operand_width-1 downto operand_width-4) = "0010" or ma_wb(operand_width-1 downto operand_width-4) = "0001") and read_2 = ma_wb(5 downto 3)) or
		  ((ma_wb(operand_width-1 downto operand_width-3) = "110" or ma_wb(operand_width-1 downto operand_width-4) = "0011" or ma_wb(operand_width-1 downto operand_width-4) = "0100") and read_2 = ma_wb(11 downto 9)) or
		   (ma_wb(operand_width-1 downto operand_width-4) = "0000" and read_2 = ma_wb(8 downto 6))) then
	
		rr_ex_temp(3*operand_width-1 downto 2*operand_width) <= ma_wb(2*operand_width-1 downto operand_width);
	
	else
	
		rr_ex_temp(3*operand_width-1 downto 2*operand_width) <= outp_2; --stores value of Rb
	
	end if;

end process register_read;




rr_ex_update: process(change_if_falling)
begin
	if(stall = '1') then
		rr_ex(2*operand_width-1 downto 2*operand_width-4) <= "1110";
	else
		rr_ex <= rr_ex_temp; --if_id_temp is 32 bit
	end if;
end process rr_ex_update;

--rr_ex = control bits + value of Ra + value of Rb + instruction + PC = 75 bits




execute: process(change_if_rising, alu_outp1, SE10_outp, SE7_outp, ls_o, lm_sm_reg_temp)
begin
	SE7_inp <= rr_ex(operand_width+8 downto operand_width); 
	SE10_inp <= rr_ex(operand_width+5 downto operand_width);
	alu_op <= rr_ex(4*operand_width-1+6 downto 4*operand_width); --assigning ALU_op as alu 6 control bits
	
	if(rr_ex(72)='0') then
		alu_inp1 <= rr_ex(4*operand_width-1 downto 4*operand_width-1-15); --Value of Ra
		alu_inp2 <= rr_ex(3*operand_width-1 downto 2*operand_width); --Value of Rb
	else
		if(rr_ex(74)='0') then
			alu_inp1 <= SE10_outp; -- value of SE10
			alu_inp2 <= rr_ex(3*operand_width-1 downto 2*operand_width); --Value of Rb
		elsif(rr_ex(74 downto 70)="10100") then
			alu_inp1 <= SE7_outp; -- value of SE7
			alu_inp2 <= "0000000000000000";
		else
			alu_inp1 <= SE7_outp; -- value of SE7
			alu_inp2 <= rr_ex(3*operand_width-1 downto 2*operand_width); --Value of Rb
		end if;
	end if;
	
	-- branch, jmp, lm, sm
	if ((rr_ex(2*operand_width-1 downto 2*operand_width-1-3) = "1000" and rr_ex(4*operand_width-1 downto 3*operand_width) = rr_ex(3*operand_width-1 downto 2*operand_width)) or
		   (rr_ex(2*operand_width-1 downto 2*operand_width-1-3) = "1001" and rr_ex(4*operand_width-1 downto 3*operand_width) < rr_ex(3*operand_width-1 downto 2*operand_width)) or
		   (rr_ex(2*operand_width-1 downto 2*operand_width-1-3) = "1010" and rr_ex(4*operand_width-1 downto 3*operand_width) <= rr_ex(3*operand_width-1 downto 2*operand_width)) or
		    rr_ex(2*operand_width-1 downto 2*operand_width-1-2) = "110" or rr_ex(2*operand_width-1 downto 2*operand_width-1-3) = "1111") then
		
		if(rr_ex(2*operand_width-1 downto 2*operand_width-1-3) = "1100" or rr_ex(2*operand_width-1 downto 2*operand_width-1-3) = "1111") then
			--SE7_inp <= rr_ex(operand_width+8 downto operand_width);                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
			ls_i <= SE7_outp;
		elsif(not(rr_ex(2*operand_width-1 downto 2*operand_width-1-3) = "1101")) then
			--SE10_inp <= rr_ex(operand_width+5 downto operand_width);
			ls_i <= SE10_outp;
		end if;
		
		if(rr_ex(2*operand_width-1 downto 2*operand_width-1-3) = "1111") then
			add_a2 <= rr_ex(4*operand_width-1 downto 3*operand_width);	-- value of Ra
		elsif(rr_ex(2*operand_width-1 downto 2*operand_width-1-3) = "1101") then
			add_a2 <= rr_ex(3*operand_width-1 downto 2*operand_width);	-- value of Rb
		else
			add_a2 <= rr_ex(operand_width-1 downto 0);	-- value of PC
		end if;
		
		if(rr_ex(2*operand_width-1 downto 2*operand_width-1-3) = "1101" or rr_ex(2*operand_width-1 downto 2*operand_width-1-2) = "011") then
			add_b2 <= "0000000000000000";
		else
			add_b2 <= ls_o;
		end if;

		stall <= '1';
	end if;
	
	--jal,jlr
	if(rr_ex(2*operand_width-1 downto 2*operand_width-1-2) = "110") then
		alu_op <= rr_ex(4*operand_width-1+6 downto 4*operand_width); --assigning ALU_op as 1st 6 control bits
		alu_inp1 <= rr_ex(operand_width-1 downto 0); --Value of PC
		alu_inp2 <= "0000000000000010";
	end if;
	
---------------------------------------------------------------------------------------------------
	if(rr_ex(2*operand_width-1 downto 2*operand_width-1-2) = "011") then
		add_a2 <= lm_sm_reg_temp;
		add_b2 <= "0000000000000001";
		if(start = '1') then
			lm_sm_reg_temp <= "0000000000000000";
			temp_D <= rr_ex(4*operand_width-1 downto 3*operand_width);	-- value of Ra
		else
			lm_sm_reg_temp <= add_c2;
			temp_D <= alu_outp1; -- ALU output
		end if;
		alu_op <= rr_ex(4*operand_width-1+6 downto 4*operand_width); --assigning ALU_op as 1st 6 control bits
		alu_inp1 <= temp_Q; --Value of Ra
		alu_inp2 <= "0000000000000001";
	end if;
---------------------------------------------------------------------------------------------------

	if(not((rr_ex(2*operand_width-1 downto 2*operand_width-1-3) = "1000" and rr_ex(4*operand_width-1 downto 3*operand_width) = rr_ex(3*operand_width-1 downto 2*operand_width)) or
		   (rr_ex(2*operand_width-1 downto 2*operand_width-1-3) = "1001" and rr_ex(4*operand_width-1 downto 3*operand_width) < rr_ex(3*operand_width-1 downto 2*operand_width)) or
		   (rr_ex(2*operand_width-1 downto 2*operand_width-1-3) = "1010" and rr_ex(4*operand_width-1 downto 3*operand_width) <= rr_ex(3*operand_width-1 downto 2*operand_width)) or
		    rr_ex(2*operand_width-1 downto 2*operand_width-1-2) = "110" or rr_ex(2*operand_width-1 downto 2*operand_width-1-3) = "1111")) then
		stall <= '0';
	end if;
	--ex_ma = control bits(only 5 here) + output of Ra + output of ALU + instr 	(5+3*operand_width)
	ex_ma_temp(3*operand_width+4 downto 3*operand_width) <= rr_ex(4*operand_width-1+11 downto 4*operand_width+6); -- control bits 
	ex_ma_temp(3*operand_width-1 downto 2*operand_width) <= rr_ex(4*operand_width-1 downto 3*operand_width); -- value of Ra
	ex_ma_temp(2*operand_width-1 downto operand_width) <= alu_outp1; -- ALU output

	ex_ma_temp(operand_width-1 downto 0) <= rr_ex(2*operand_width-1 downto operand_width); -- instr
end process execute;




ex_ma_update: process(change_if_falling)
begin
	ex_ma <= ex_ma_temp;
	temp_Q <= temp_D;
	lm_sm_reg <= lm_sm_reg_temp;
end process ex_ma_update;
--ex_ma = control bits(only 5 here) + output of Ra + output of ALU + instr 	(5+3*operand_width)
--This stage deals with DATA memory
mem_access: process(change_if_rising, d_mem_read)
begin
	if(ex_ma(49)='1') then -- then we have to store
		d_mem_inp <= ex_ma(31 downto 16);
		d_mem_store <= ex_ma(3*operand_width-1 downto 2*operand_width);-- value of Ra
		d_mem_re <= '0';
		d_mem_we <= '1';	--write data to mem
	else
		d_mem_inp <= ex_ma(31 downto 16);	--address
		d_mem_store <= ex_ma(3*operand_width-1 downto 2*operand_width);-- useless, take care not to use anywhere
		d_mem_re <= '1';	--read data from mem 
		d_mem_we <= '0';
	end if;
	if(ex_ma(15 downto 13) = "011") then
		ma_wb_temp(31 downto 16) <= lm_sm_reg;
	else
		ma_wb_temp(31 downto 16) <= ex_ma(31 downto 16);
	end if;
	ma_wb_temp(15 downto 0) <= ex_ma(15 downto 0);
	ma_wb_temp(47 downto 32) <= d_mem_read;	-- useless in the case of STORE
end process mem_access;




ma_wb_update: process(change_if_falling)
begin
	ma_wb <= ma_wb_temp;
end process ma_wb_update;

-- ma_wb = control bits (only 5 here)+ output of memory + output of ALU/lm_sm_reg + instr 	(5+3*operand_width)




write_back: process(change_if_rising)
begin
	if (ma_wb(operand_width-1 downto operand_width-4)="0001") or (ma_wb(operand_width-1 downto operand_width-4)="0010") then
		write_2 <= ma_wb(5 downto 3); -- Rc where me
		inp_2 <= ma_wb(2*operand_width-1 downto operand_width);
		
	elsif (ma_wb(operand_width-1 downto operand_width-4)="0000") then
		write_2 <= ma_wb(8 downto 6);
		inp_2 <= ma_wb(2*operand_width-1 downto operand_width); -- output has been stored in the register specified in the above line
		
	elsif (ma_wb(operand_width-1 downto operand_width-4)="0011") or 
			(ma_wb(operand_width-1 downto operand_width-3) = "110") then
		write_2 <= ma_wb(11 downto 9);
		inp_2 <= ma_wb(2*operand_width-1 downto operand_width);
		--output to register
		
	elsif (ma_wb(operand_width-1 downto operand_width-4) = "0100") then
		write_2 <= ma_wb(11 downto 9);
		inp_2 <= ma_wb(3*operand_width-1 downto 2*operand_width);
		
	elsif (ma_wb(operand_width-1 downto operand_width-4) = "0110") then
		if(ma_wb(to_integer(unsigned(ma_wb(18 downto 16)))) = '1') then
			write_2 <= not(ma_wb(18 downto 16));
			inp_2 <= ma_wb(3*operand_width-1 downto 2*operand_width);
		end if;
	end if;

end process write_back;
end bhv;
