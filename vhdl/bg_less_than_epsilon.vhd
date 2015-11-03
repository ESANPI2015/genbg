library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_misc.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
use work.fpupack.all;
-- Add additional libraries here

entity bg_less_than_epsilon is
    port(
    -- Inputs
        in_port : in DATA_PORT(2 downto 0);
        in_req : in DATA_SIGNAL(2 downto 0);
        in_ack : out DATA_SIGNAL(2 downto 0);
    -- The epsilon for comparison
        in_epsilon : in std_logic_vector(DATA_WIDTH-1 downto 0);
    -- Outputs
        out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
        out_req : out std_logic;
        out_ack : in std_logic;
    -- Other signals
        halt : in std_logic;
        rst : in std_logic;
        clk : in std_logic
        );
end bg_less_than_epsilon;

architecture Behavioral of bg_less_than_epsilon is
    -- Add types here
    type NodeStates is (idle, new_data, data_out, sync);
    -- Add signals here
    signal NodeState : NodeStates;

    signal internal_input_req : std_logic;
    signal internal_input_ack : std_logic;
    signal internal_output_req : std_logic;
    signal internal_output_ack : std_logic;

    signal rest : std_logic_vector(DATA_WIDTH-2 downto 0);
    signal rest_epsilon : std_logic_vector(DATA_WIDTH-2 downto 0);
    signal less_than_epsilon : std_logic;
begin
    internal_input_req <= in_req(0) and in_req(1) and in_req(2);
    in_ack <= (others => internal_input_ack);
    out_req <= internal_output_req;
    internal_output_ack <= out_ack;

    -- The value on port 0 defines which of the values on port 1 or 2 gets selected
    rest <= in_port(0)(DATA_WIDTH-2 downto 0);
    rest_epsilon <= in_epsilon(DATA_WIDTH-2 downto 0);
    -- TODO: We might have to check epsilon for NAN as well?
    less_than_epsilon <= '1' when ((rest /= SNAN) and (rest /= QNAN) and (unsigned(rest) < unsigned(rest_epsilon))) else '0';

    -- Add processes here
    NodeProcess : process(clk)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                internal_input_ack <= '0';
                internal_output_req <= '0';
                out_port <= (others => '0');
                NodeState <= idle;
            else
                if (halt = '0') then
                    -- defaults
                    case NodeState is
                        when idle =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (internal_input_req = '1') then
                                if (less_than_epsilon = '1') then
                                    out_port <= in_port(1);
                                else
                                    out_port <= in_port(2);
                                end if;
                                internal_input_ack <= '1';
                                NodeState <= new_data;
                            else
                                NodeState <= idle;
                            end if;
                        when new_data =>
                            internal_input_ack <= '1';
                            internal_output_req <= '1'; -- early signalling
                            if (internal_input_req = '0') then
                                internal_input_ack <= '0';
                                NodeState <= data_out;
                            else
                                NodeState <= new_data;
                            end if;
                        when data_out =>
                            internal_input_ack <= '0';
                            internal_output_req <= '1';
                            if (internal_output_ack = '1') then
                                internal_output_req <= '0';
                                NodeState <= sync;
                            else
                                NodeState <= data_out;
                            end if;
                        when sync =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (internal_output_ack = '0') then
                                NodeState <= idle;
                            else
                                NodeState <= sync;
                            end if;
                    end case;
                end if;
            end if;
        end if;
    end process NodeProcess;
end Behavioral;
