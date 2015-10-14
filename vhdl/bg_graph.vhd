--
-- This file contains a test graph and is a precursor for a template which is used to instantiate generated behaviour graphs
--

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
use work.bg_graph_components.all;
use work.bg_graph_config.all;
-- Add additional libraries here

entity bg_graph is
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
end bg_graph;

architecture Behavioral of bg_graph is

    -- for each source
    signal from_source     : source_ports_t;
    signal from_source_req : source_signal_t;
    signal from_source_ack : source_signal_t;
    -- for each sink
    signal to_sink         : sink_ports_t;
    signal to_sink_req     : sink_signal_t;
    signal to_sink_ack     : sink_signal_t;
    -- for each pipe
    signal to_pipe         : pipe_ports_t;
    signal to_pipe_req     : pipe_signals_t;
    signal to_pipe_ack     : pipe_signals_t;
    signal from_pipe       : pipe_ports_t;
    signal from_pipe_req   : pipe_signals_t;
    signal from_pipe_ack   : pipe_signals_t;
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

begin
    -- connections
    to_copy(0) <= in_port(0);
    to_copy(1) <= in_port(1);
    to_copy_req(0) <= in_req(0);
    to_copy_req(1) <= in_req(1);
    in_ack(0) <= to_copy_ack(0);
    in_ack(1) <= to_copy_ack(1);

    to_edge(0) <= from_copy(0)(0);
    to_edge(1) <= from_copy(1)(0);
    to_edge(2) <= from_copy(0)(1);
    to_edge(3) <= from_copy(1)(1);
    to_edge_req(0) <= from_copy_req(0)(0);
    to_edge_req(1) <= from_copy_req(1)(0);
    to_edge_req(2) <= from_copy_req(0)(1);
    to_edge_req(3) <= from_copy_req(1)(1);
    from_copy_ack(0)(0) <= to_edge_ack(0);
    from_copy_ack(1)(0) <= to_edge_ack(1);
    from_copy_ack(0)(1) <= to_edge_ack(2);
    from_copy_ack(1)(1) <= to_edge_ack(3);

    to_merge(0)(0) <= from_edge(0);
    to_merge(0)(1) <= from_edge(1);
    to_merge(1)(0) <= from_edge(2);
    to_merge(1)(1) <= from_edge(3);
    to_merge_req(0)(0) <= from_edge_req(0);
    to_merge_req(0)(1) <= from_edge_req(1);
    to_merge_req(1)(0) <= from_edge_req(2);
    to_merge_req(1)(1) <= from_edge_req(3);
    from_edge_ack(0) <= to_merge_ack(0)(0);
    from_edge_ack(1) <= to_merge_ack(0)(1);
    from_edge_ack(2) <= to_merge_ack(1)(0);
    from_edge_ack(3) <= to_merge_ack(1)(1);

    out_port(0) <= from_merge(0);
    out_port(1) <= from_merge(1);
    out_req(0) <= from_merge_req(0);
    out_req(1) <= from_merge_req(1);
    from_merge_ack(0) <= out_ack(0);
    from_merge_ack(1) <= out_ack(1);

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

    -- instantiate pipes
    GENERATE_PIPES : for i in NO_PIPES-1 downto 0 generate
        pipe : bg_pipe
        port map (
                clk => clk,
                rst => rst,
                halt => halt,
                in_port => to_pipe(i),
                in_req => to_pipe_req(i),
                in_ack => to_pipe_ack(i),
                out_port => from_pipe(i),
                out_req => from_pipe_req(i),
                out_ack => from_pipe_ack(i)
                 );
        end generate;

    -- instantiate edges
    GENERATE_EDGES : for i in NO_EDGES-1 downto 0 generate
        edge : bg_edge
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
    GENERATE_MERGE : for i in NO_MERGE-1 downto 0 generate

        GENERATE_MERGE_SUM : if (MERGE_TYPE(i) = sum) generate
            merge : bg_merge_sum
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
            merge : bg_merge_prod
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

end Behavioral;
