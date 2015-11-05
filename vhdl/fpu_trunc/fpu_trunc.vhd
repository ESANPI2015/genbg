-----
-- This component truncates (round towards zero) a floating point number to the integer value towards zero
-- Example: 1.9 -> 1.0, -1.9 -> -1.0
--
-- Author: M.Schilling
-- Date: 2015/11/03
-- 
-- TODO: Optimize timing if possible
-----

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work;
use work.fpupack.all;


entity fpu_trunc is
	port(
        clk_i 			: in std_logic;

        -- Input Operand
        opa_i        	: in std_logic_vector(FP_WIDTH-1 downto 0);  -- Default: FP_WIDTH=32 
        
        -- Output port   
        output_o        : out std_logic_vector(FP_WIDTH-1 downto 0);
        
        -- Control signals
        start_i			: in std_logic; -- is also restart signal
        ready_o 		: out std_logic
		);
end fpu_trunc;

architecture rtl of fpu_trunc is

type t_state is (waiting,busy);
signal s_state : t_state;
signal s_count : integer range 0 to 4;

signal s_opa_i : std_logic_vector(FP_WIDTH-1 downto 0);
signal s_output1 : std_logic_vector(FP_WIDTH-1 downto 0);
signal exponent : signed(7 downto 0);
signal s_ine_o, s_overflow_o, s_underflow_o, s_div_zero_o, s_inf_o, s_zero_o, s_qnan_o, s_snan_o : std_logic;
signal dec_point : integer range 0 to 23;

begin

exponent <= signed(s_opa_i(30 downto 23)) - 127; -- first stage (1 adder)
dec_point <= to_integer(22 - exponent + 1); -- second stage (1 adder + conversion)
s_output1 <= (others => '0') when exponent < 0 else s_opa_i(FP_WIDTH-1 downto dec_point) & ZERO_VECTOR(dec_point-1 downto 0); -- third stage (1 comparator, 1 mux)
output_o  <= s_opa_i when (s_snan_o or s_inf_o)='1' else s_output1; -- fourth stage (1 mux)

-- FSM
process(clk_i)
begin
	if rising_edge(clk_i) then
		if start_i ='1' then
            s_opa_i <= opa_i;
			s_state <= busy;
			s_count <= 4; 
		elsif s_count=0 and s_state=busy then
			s_state <= waiting;
			s_count <= 4; 
			ready_o <= '1';
		elsif s_state=busy then
			s_count <= s_count - 1;
			ready_o <= '0';
		else
			s_state <= waiting;
			ready_o <= '0';
		end if;
	end if;	
end process;

-- Generate Exceptions 
s_ine_o <= '0';
s_underflow_o <= '0'; 
s_overflow_o <= '0';
s_div_zero_o <= '0';
s_inf_o <= '1' when s_opa_i(30 downto 23)="11111111" and (s_qnan_o or s_snan_o)='0' else '0';
s_zero_o <= '1' when or_reduce(s_output1(30 downto 0))='0' else '0';
s_qnan_o <= '0';
s_snan_o <= '1' when s_opa_i(30 downto 0)=SNAN else '0';

end rtl;
