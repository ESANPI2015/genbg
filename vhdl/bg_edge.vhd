library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
-- Add additional libraries here

entity bg_edge is
    port(
    -- Inputs
        in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
        in_req : in std_logic;
        in_ack : out std_logic;
    -- Weight
        in_weight : in std_logic_vector(DATA_WIDTH-1 downto 0);
    -- Outputs
        out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
        out_req : out std_logic;
        out_ack : in std_logic;
    -- Other signals
        halt : in std_logic;
        rst : in std_logic;
        clk : in std_logic
        );
end bg_edge;

architecture Behavioral of bg_edge is
    -- Add types here
    type NodeStates is (idle, new_data, compute, data_out, sync);
    -- Add signals here
    signal NodeState : NodeStates;

    signal data : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal internal_input_req : std_logic;
    signal internal_input_ack : std_logic;
    signal internal_output_req : std_logic;
    signal internal_output_ack : std_logic;

    -- FP stuff
    signal fp_start : std_logic;
    signal fp_rdy : std_logic;
    signal fp_finished : std_logic; -- this is a flipflopped version
begin

    -- Instantiate floating point multiplier here
    -- NOTE: if the weight is 1.0, we should replace an edge with a pipe!
    fp_mul : entity work.fpu_mul(rtl)
    port map (
                clk_i => clk,
                opa_i => in_weight,
                opb_i => data,
                rmode_i => "00", -- round to nearest even
                output_o => out_port,
                start_i => fp_start,
                ready_o => fp_rdy,
                ine_o => open,
                overflow_o => open,
                underflow_o => open,
                div_zero_o => open,
                inf_o => open,
                zero_o => open,
                qnan_o => open,
                snan_o => open
             );

    internal_input_req <= in_req;
    in_ack <= internal_input_ack;
    out_req <= internal_output_req;
    internal_output_ack <= out_ack;

    -- Process to detect if the fp stage has finished since last fp_start signal
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fp_finished <= '1';
            else
                if (fp_start = '1') then
                    fp_finished <= '0';
                elsif (fp_rdy = '1') then
                    fp_finished <= '1';
                end if;
            end if;
        end if;
    end process;

    -- Add processes here
    NodeProcess : process(clk)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                internal_input_ack <= '0';
                internal_output_req <= '0';
                data <= (others => '0');
                fp_start <= '0';
                NodeState <= idle;
            else
                -- defaults
                fp_start <= '0';
                if (halt = '0') then
                    case NodeState is
                        when idle =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (internal_input_req = '1') then
                                data <= in_port;
                                fp_start <= '1';
                                internal_input_ack <= '1';
                                NodeState <= new_data;
                            else
                                NodeState <= idle;
                            end if;
                        when new_data =>
                            internal_input_ack <= '1';
                            internal_output_req <= '0';
                            if (internal_input_req = '0') then
                                internal_input_ack <= '0';
                                NodeState <= compute;
                            else
                                NodeState <= new_data;
                            end if;
                        when compute =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            -- Wait until the fp stage is ready
                            if (fp_finished = '1') then
                                --internal_output_req <= '1'; -- Check this! See also bg_merge
                                NodeState <= data_out;
                            else
                                NodeState <= compute;
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
