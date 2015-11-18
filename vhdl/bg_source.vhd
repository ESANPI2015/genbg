library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
-- Add additional libraries here

entity bg_source is
    port(
    -- Inputs
        in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
    -- Outputs
        out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
        out_req : out std_logic;
        out_ack : in std_logic;
    -- Other signals
        halt : in std_logic;
        rst : in std_logic;
        clk : in std_logic
        );
end bg_source;

architecture Behavioral of bg_source is
    -- Add types here
    type NodeStates is (idle, data_out, sync);
    -- Add signals here
    signal NodeState : NodeStates;

    signal internal_output_req : std_logic;
    signal internal_output_ack : std_logic;
begin
    out_req <= internal_output_req;
    internal_output_ack <= out_ack;

    -- Add processes here
    NodeProcess : process(clk)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                internal_output_req <= '0';
                out_port <= (others => '0');
                NodeState <= idle;
            else
                -- defaults
                internal_output_req <= '0';
                NodeState <= NodeState;
                case NodeState is
                    when idle =>
                        if (halt = '0') then
                            out_port <= in_port; -- sample input port
                            NodeState <= data_out;
                        end if;
                    when data_out =>
                        internal_output_req <= '1';
                        if (internal_output_ack = '1') then
                            internal_output_req <= '0';
                            NodeState <= sync;
                        end if;
                    when sync =>
                        if (internal_output_ack = '0') then
                            NodeState <= idle;
                        end if;
                end case;
            end if;
        end if;
    end process NodeProcess;
end Behavioral;
