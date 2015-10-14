library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package bg_vhdl_types is

    constant DATA_WIDTH : integer := 32; -- Change this to be equal to FP_WIDTH

    type DATA_PORT is array(natural range <>) of std_logic_vector(data_width-1 downto 0);
    type DATA_SIGNAL is array(natural range <>) of std_logic;

end;
