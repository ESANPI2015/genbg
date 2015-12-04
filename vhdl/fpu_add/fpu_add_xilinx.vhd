library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.fpupack.all;

entity fpu_add is
    port (
        clk_i 			: in std_logic;

        -- Input Operands A & B
        opa_i        	: in std_logic_vector(FP_WIDTH-1 downto 0);  -- Default: FP_WIDTH=32 
        opb_i           : in std_logic_vector(FP_WIDTH-1 downto 0);
        
        -- Rounding Mode: 
        -- ==============
        -- 00 = round to nearest even(default), 
        -- 01 = round to zero, 
        -- 10 = round up, 
        -- 11 = round down
        rmode_i 		: in std_logic_vector(1 downto 0);
        
        -- Output port   
        output_o        : out std_logic_vector(FP_WIDTH-1 downto 0);
        
        -- Control signals
        start_i			: in std_logic; -- is also restart signal
        ready_o 		: out std_logic
	);   
end fpu_add;

architecture rtl of fpu_add is

COMPONENT fpu_add_xilinx
  PORT (
    a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    operation_nd : IN STD_LOGIC;
    clk : IN STD_LOGIC;
    result : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    rdy : OUT STD_LOGIC
  );
END COMPONENT;

begin

fp_add : fpu_add_xilinx
  PORT MAP (
    a => opa_i,
    b => opb_i,
    operation_nd => start_i,
    clk => clk_i,
    result => output_o,
    rdy => ready_o
  );

end rtl;
