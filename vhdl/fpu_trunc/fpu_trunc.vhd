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
signal s_output_o : std_logic_vector(FP_WIDTH-1 downto 0);
signal exponent : signed(7 downto 0);
signal pass_through : std_logic;
signal is_neg : std_logic;
signal mux_select : std_logic_vector(1 downto 0);
signal dec_point : integer range 0 to 23;
signal s_inf_o, s_nan_o : std_logic;

begin

-- this is pure combinatorical, so to increase reg usage, we have to make it sequential.
--exponent <= signed(s_opa_i(30 downto 23)) - 127; -- first stage (1 adder)
--dec_point <= to_integer(23 - exponent); -- second stage (conversion)
--s_output1 <= (others => '0') when exponent < 0 else s_opa_i(FP_WIDTH-1 downto dec_point) & ZERO_VECTOR(dec_point-1 downto 0); -- third stage (1 comparator, 1 mux)
--s_output_o <= s_opa_i when (s_snan_o or s_inf_o)='1' else s_output1; -- fourth stage (1 mux)

-- First parallel stuff
exponent <= signed(s_opa_i(30 downto 23)) - 127;
pass_through <= s_nan_o or s_inf_o;
-- Second parallel stuff
is_neg <= '1' when exponent < 0 else '0';
-- Third parallel stuff
dec_point <= to_integer(23 - exponent) when is_neg='0' else 0;
-- Fourth parallel stuff
mux_select(1) <= pass_through;
mux_select(0) <= is_neg;

with mux_select select
    s_output_o <= s_opa_i when "10",
                  s_opa_i when "11",
                  (others => '0') when "01",
                  s_opa_i(FP_WIDTH-1 downto dec_point) & ZERO_VECTOR(dec_point-1 downto 0) when "00";

-- FSM
process(clk_i)
begin
	if rising_edge(clk_i) then
        ready_o <= '0';
		if start_i ='1' then
            s_opa_i <= opa_i;
			s_state <= busy;
			s_count <= 4; 
		elsif s_count=0 and s_state=busy then
			s_state <= waiting;
            output_o <= s_output_o;
			ready_o <= '1';
			s_count <= 4; 
		elsif s_state=busy then
			s_count <= s_count - 1;
		else
			s_state <= waiting;
		end if;
	end if;	
end process;

-- Generate Exceptions 
s_inf_o <= '1' when s_opa_i(30 downto 23)="11111111" and s_nan_o='0' else '0';
s_nan_o <= '1' when s_opa_i(30 downto 0)=SNAN or s_opa_i(30 downto 0)=QNAN else '0';

end rtl;
