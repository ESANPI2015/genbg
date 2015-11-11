----
-- Less than and greater than functionality for Floating Point
--
-- Author: M. Schilling
-- Date: 2015/10/28
---

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.fpupack.all;


entity fpu_cmp is
    port (
        clk_i 			: in std_logic;

        -- Input Operands A & B
        opa_i        	: in std_logic_vector(FP_WIDTH-1 downto 0);  -- Default: FP_WIDTH=32 
        opb_i           : in std_logic_vector(FP_WIDTH-1 downto 0);

        -- Output port   
        less_than_o     : out std_logic; -- a < b ?
        greater_than_o  : out std_logic; -- a > b ?
        
        -- Control signals
        start_i			: in std_logic; -- is also restart signal
        ready_o 		: out std_logic
	);   
end fpu_cmp;

architecture rtl of fpu_cmp is
    
	type   t_state is (waiting,busy);
	signal s_state : t_state;
	signal s_count : integer range 0 to 3;

    -- Compare stuff
    signal both_zero : std_logic;
    signal is_nan : std_logic;
    signal sign_a : std_logic;
    signal sign_b : std_logic;
    signal rest_a : std_logic_vector(FP_WIDTH-2 downto 0);
    signal rest_b : std_logic_vector(FP_WIDTH-2 downto 0);
    signal rest_a_greater_than_b : std_logic;
    signal rest_a_less_than_b : std_logic;
    signal selection : std_logic_vector(1 downto 0);
    signal a_greater_than_b : std_logic;
    signal a_less_than_b : std_logic;
    signal greater_than : std_logic;
    signal less_than : std_logic;
	
begin
-----------------------------------------------------------------			

	-- FSM
	process(clk_i)
	begin
		if rising_edge(clk_i) then
            ready_o <= '0';
			if start_i ='1' then
                sign_a <= opa_i(FP_WIDTH-1);
                sign_b <= opb_i(FP_WIDTH-1);
                rest_a <= opa_i(FP_WIDTH-2 downto 0);
                rest_b <= opb_i(FP_WIDTH-2 downto 0);
				s_state <= busy;
				s_count <= 0;
			elsif s_count=3 then
				s_state <= waiting;
                less_than_o <= less_than;
                greater_than_o <= greater_than;
				ready_o <= '1';
				s_count <=0;
			elsif s_state=busy then
				s_count <= s_count + 1;
			else
				s_state <= waiting;
			end if;
	end if;	
	end process;
	        
    -- third stage
    greater_than <= '1' when ((is_nan = '0') and (both_zero = '0') and (a_greater_than_b = '1')) else '0';
    less_than <= '1' when ((is_nan = '0') and (both_zero = '0') and (a_less_than_b = '1')) else '0';

    -- second stage
    with selection select
        a_greater_than_b <= rest_a_greater_than_b when "00",
                            '1' when "01",
                            '0' when "10",
                            rest_a_less_than_b when "11";
    with selection select
        a_less_than_b    <= rest_a_less_than_b when "00",
                            '0' when "01",
                            '1' when "10",
                            rest_a_greater_than_b when "11";
    -- first stage
    selection(0) <= sign_b;
    selection(1) <= sign_a;
    rest_a_greater_than_b <= '1' when (unsigned(rest_a) > unsigned(rest_b)) else '0';
    rest_a_less_than_b <= '1' when (unsigned(rest_a) < unsigned(rest_b)) else '0';
    both_zero <= not (or_reduce(rest_a & rest_b));
    is_nan <= '1' when rest_a=SNAN or rest_a=QNAN or rest_b=SNAN or rest_b=QNAN else '0';

end rtl;
