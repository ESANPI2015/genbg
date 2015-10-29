library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
-- Add additional libraries here

entity bg_abs is
    port(
    -- Inputs
        in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
        in_req : in std_logic;
        in_ack : out std_logic;
    -- Outputs
        out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
        out_req : out std_logic;
        out_ack : in std_logic;
    -- Other signals
        halt : in std_logic;
        rst : in std_logic;
        clk : in std_logic
        );
end bg_abs;

architecture Behavioral of bg_abs is

begin

    -- The floating point abs is just wires :) Its all about deleting the sign :D
    out_port(DATA_WIDTH-1) <= '0';
    out_port(DATA_WIDTH-2 downto 0) <= in_port(DATA_WIDTH-2 downto 0);
    out_req <= in_req;
    in_ack <= out_ack;

end Behavioral;
