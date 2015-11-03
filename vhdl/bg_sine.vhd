library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
-- Add additional libraries here

entity bg_sine is
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
end bg_sine;

architecture Behavioral of bg_sine is

begin

-- Instantiate the GENERATED SINE :D
    sine : entity work.bg_graph_sine(Behavioral)
    port map (
                clk => clk,
                rst => rst,
                halt => halt,
                in_port(0) => in_port,
                in_req(0) => in_req,
                in_ack(0) => in_ack,
                out_port(0) => out_port,
                out_req(0) => out_req,
                out_ack(0) => out_ack
             );

end Behavioral;
