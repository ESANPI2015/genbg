--
-- TEMPLATE FOR BEHAVIOUR GRAPHS TO VHDL
--
-- Components are instantiated and wired for synthesis
--
-- Instance: @name@
-- @info@
--
-- Author: M. Schilling
-- Date: 2015/10/14

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
use work.bg_graph_components.all;
use work.bg_graph_@name@_config.all;
-- Add additional libraries here

entity bg_graph_@name@ is
    port(
    -- Inputs
        in_port : in DATA_PORT(NO_INPUTS-1 downto 0);
        in_req : in DATA_SIGNAL(NO_INPUTS-1 downto 0);
        in_ack : out DATA_SIGNAL(NO_INPUTS-1 downto 0);
    -- Outputs
        out_port : out DATA_PORT(NO_OUTPUTS-1 downto 0);
        out_req : out DATA_SIGNAL(NO_OUTPUTS-1 downto 0);
        out_ack : in DATA_SIGNAL(NO_OUTPUTS-1 downto 0);
    -- Other signals
        halt : in std_logic;
        rst : in std_logic;
        clk : in std_logic
        );
end bg_graph_@name@;

architecture Behavioral of bg_graph_@name@ is

    signal from_external     : DATA_PORT(NO_INPUTS-1 downto 0);
    signal from_external_req : DATA_SIGNAL(NO_INPUTS-1 downto 0);
    signal from_external_ack : DATA_SIGNAL(NO_INPUTS-1 downto 0);
    signal to_external     : DATA_PORT(NO_OUTPUTS-1 downto 0);
    signal to_external_req : DATA_SIGNAL(NO_OUTPUTS-1 downto 0);
    signal to_external_ack : DATA_SIGNAL(NO_OUTPUTS-1 downto 0);
    -- for each source
    signal from_source     : source_ports_t;
    signal from_source_req : source_signal_t;
    signal from_source_ack : source_signal_t;
    -- for each sink
    signal to_sink         : sink_ports_t;
    signal to_sink_req     : sink_signal_t;
    signal to_sink_ack     : sink_signal_t;
    -- for each edge
    signal to_edge         : edge_ports_t;
    signal to_edge_req     : edge_signals_t;
    signal to_edge_ack     : edge_signals_t;
    signal from_edge       : edge_ports_t;
    signal from_edge_req   : edge_signals_t;
    signal from_edge_ack   : edge_signals_t;
    -- for each merge
    signal to_merge        : merge_input_ports_t;
    signal to_merge_req    : merge_input_signals_t;
    signal to_merge_ack    : merge_input_signals_t;
    signal from_merge      : merge_output_ports_t;
    signal from_merge_req  : merge_output_signals_t;
    signal from_merge_ack  : merge_output_signals_t;
    -- for each copy
    signal to_copy         : copy_input_ports_t;
    signal to_copy_req     : copy_input_signals_t;
    signal to_copy_ack     : copy_input_signals_t;
    signal from_copy       : copy_output_ports_t;
    signal from_copy_req   : copy_output_signals_t;
    signal from_copy_ack   : copy_output_signals_t;
    -- for each unary node
    signal to_unary         : unary_ports_t;
    signal to_unary_req     : unary_signals_t;
    signal to_unary_ack     : unary_signals_t;
    signal from_unary       : unary_ports_t;
    signal from_unary_req   : unary_signals_t;
    signal from_unary_ack   : unary_signals_t;

begin
    -- connections
    from_external <= in_port;
    from_external_req <= in_req;
    in_ack <= from_external_ack;

    out_port <= to_external;
    out_req  <= to_external_req;
    to_external_ack <= out_ack;

    -- Generated connections
    @connection0@

    -- instantiate sources
    GENERATE_SOURCES : for i in NO_SOURCES-1 downto 0 generate
        source : bg_source
        port map (
                clk => clk,
                rst => rst,
                halt => halt,
                in_port => SOURCE_VALUES(i),
                out_port => from_source(i),
                out_req => from_source_req(i),
                out_ack => from_source_ack(i)
                 );
        end generate;

    -- instantiate sinks
    GENERATE_SINKS : for i in NO_SINKS-1 downto 0 generate
        sink : bg_sink
        port map (
                clk => clk,
                rst => rst,
                halt => halt,
                in_port => to_sink(i),
                in_req => to_sink_req(i),
                in_ack => to_sink_ack(i),
                out_port => open -- NOTE: A sink internal of an behaviour graph is just a trash can!
                 );
        end generate;

    -- instantiate edges
    GENERATE_EDGES : for i in NO_EDGES-1 downto 0 generate
        edge : bg_edge
        generic map (
                        IS_BACKEDGE => EDGE_TYPES(i)
                    )
        port map (
                clk => clk,
                rst => rst,
                halt => halt,
                in_weight => EDGE_WEIGHTS(i),
                in_port => to_edge(i),
                in_req => to_edge_req(i),
                in_ack => to_edge_ack(i),
                out_port => from_edge(i),
                out_req => from_edge_req(i),
                out_ack => from_edge_ack(i)
                 );
        end generate;

    -- instantiate merges
    GENERATE_MERGES : for i in NO_MERGES-1 downto 0 generate

        GENERATE_MERGE_SUM : if (MERGE_TYPE(i) = sum) generate
            merge_sum : bg_merge_sum
            generic map (
                            NO_INPUTS => MERGE_INPUTS(i)
                        )
            port map (
                        clk => clk,
                        rst => rst,
                        halt => halt,
                        in_bias  => MERGE_BIAS(i),
                        in_port  => to_merge(i)(MERGE_INPUTS(i)-1 downto 0),
                        in_req   => to_merge_req(i)(MERGE_INPUTS(i)-1 downto 0),
                        in_ack   => to_merge_ack(i)(MERGE_INPUTS(i)-1 downto 0),
                        out_port => from_merge(i),
                        out_req  => from_merge_req(i),
                        out_ack  => from_merge_ack(i)
                     );
            end generate;

        GENERATE_MERGE_PROD : if (MERGE_TYPE(i) = prod) generate
            merge_prod : bg_merge_prod
            generic map (
                            NO_INPUTS => MERGE_INPUTS(i)
                        )
            port map (
                        clk => clk,
                        rst => rst,
                        halt => halt,
                        in_bias  => MERGE_BIAS(i),
                        in_port  => to_merge(i)(MERGE_INPUTS(i)-1 downto 0),
                        in_req   => to_merge_req(i)(MERGE_INPUTS(i)-1 downto 0),
                        in_ack   => to_merge_ack(i)(MERGE_INPUTS(i)-1 downto 0),
                        out_port => from_merge(i),
                        out_req  => from_merge_req(i),
                        out_ack  => from_merge_ack(i)
                     );
            end generate;

        end generate;

    -- instantiate copies
    GENERATE_COPIES : for i in NO_COPIES-1 downto 0 generate
        copy : bg_copy
            generic map (
                       NO_OUTPUTS => COPY_OUTPUTS(i)
                   )
            port map (
                    clk => clk,
                    rst => rst,
                    halt => halt,
                    in_port => to_copy(i),
                    in_req =>  to_copy_req(i),
                    in_ack =>  to_copy_ack(i),
                    out_port => from_copy(i)(COPY_OUTPUTS(i)-1 downto 0),
                    out_req  => from_copy_req(i)(COPY_OUTPUTS(i)-1 downto 0),
                    out_ack  => from_copy_ack(i)(COPY_OUTPUTS(i)-1 downto 0)
                );
        end generate;

    -- instantiate unary nodes
    GENERATE_UNARY : for i in NO_UNARY-1 downto 0 generate
        GENERATE_PIPE : if (UNARY_TYPES(i) = pipe) generate
            pipe : bg_pipe
            port map (
                    clk => clk,
                    rst => rst,
                    halt => halt,
                    in_port => to_unary(i)(0),
                    in_req => to_unary_req(i)(0),
                    in_ack => to_unary_ack(i)(0),
                    out_port => from_unary(i)(0),
                    out_req => from_unary_req(i)(0),
                    out_ack => from_unary_ack(i)(0)
                     );
                 end generate;
        end generate;

end Behavioral;