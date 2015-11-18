library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
-- Add additional libraries here

entity bg_sink is
    port(
    -- Inputs
        in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
        in_req : in std_logic;
        in_ack : out std_logic;
    -- Outputs
        out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
    -- Other signals
        halt : in std_logic;
        rst : in std_logic;
        clk : in std_logic
        );
end bg_sink;

architecture Behavioral of bg_sink is
    -- Add types here
    type NodeStates is (idle, new_data);
    -- Add signals here
    signal NodeState : NodeStates;

    signal internal_input_req : std_logic;
    signal internal_input_ack : std_logic;
begin
    internal_input_req <= in_req;
    in_ack <= internal_input_ack;

    -- Add processes here
    NodeProcess : process(clk)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                internal_input_ack <= '0';
                out_port <= (others => '0');
                NodeState <= idle;
            else
                NodeState <= NodeState;
                -- defaults
                case NodeState is
                    when idle =>
                        internal_input_ack <= '0';
                        if (internal_input_req = '1' and halt = '0') then
                            out_port <= in_port; -- direct passing to output
                            internal_input_ack <= '1';
                            NodeState <= new_data;
                        end if;
                    when new_data =>
                        internal_input_ack <= '1';
                        if (internal_input_req = '0') then
                            internal_input_ack <= '0';
                            NodeState <= idle;
                        end if;
                end case;
            end if;
        end if;
    end process NodeProcess;
end Behavioral;
