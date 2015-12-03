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
    -- SPECIAL: weights for weighted sum
    signal merge_wsum_weights : merge_input_ports_t;
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
    -- for each binary node
    signal to_binary         : binary_input_ports_t;
    signal to_binary_req     : binary_input_signals_t;
    signal to_binary_ack     : binary_input_signals_t;
    signal from_binary       : binary_output_ports_t;
    signal from_binary_req   : binary_output_signals_t;
    signal from_binary_ack   : binary_output_signals_t;
    -- for each ternary node
    signal to_ternary         : ternary_input_ports_t;
    signal to_ternary_req     : ternary_input_signals_t;
    signal to_ternary_ack     : ternary_input_signals_t;
    signal from_ternary       : ternary_output_ports_t;
    signal from_ternary_req   : ternary_output_signals_t;
    signal from_ternary_ack   : ternary_output_signals_t;

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
        GENERATE_NORMAL_EDGE : if (EDGE_TYPES(i) = normal) generate
            edge : bg_edge
            generic map (
                            IS_BACKEDGE => false
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
        GENERATE_BACK_EDGE : if (EDGE_TYPES(i) = backedge) generate
            backedge : bg_edge
            generic map (
                            IS_BACKEDGE => true
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
        GENERATE_SIMPLE_EDGE : if (EDGE_TYPES(i) = simple) generate
            simpleedge : bg_edge_simple
            port map (
                    clk => clk,
                    rst => rst,
                    halt => halt,
                    in_port => to_edge(i),
                    in_req => to_edge_req(i),
                    in_ack => to_edge_ack(i),
                    out_port => from_edge(i),
                    out_req => from_edge_req(i),
                    out_ack => from_edge_ack(i)
                     );
             end generate;
        GENERATE_SIMPLE_BACKEDGE : if (EDGE_TYPES(i) = simple_backedge) generate
            simplebackedge : bg_edge_simple
            generic map (
                            IS_BACKEDGE => true
                        )
            port map (
                    clk => clk,
                    rst => rst,
                    halt => halt,
                    in_port => to_edge(i),
                    in_req => to_edge_req(i),
                    in_ack => to_edge_ack(i),
                    out_port => from_edge(i),
                    out_req => from_edge_req(i),
                    out_ack => from_edge_ack(i)
                     );
             end generate;
        GENERATE_SIMPLE_INV_EDGE : if (EDGE_TYPES(i) = simple_inv) generate
            simpleinvedge : bg_edge_simple
            generic map (
                            INVERTS => true
                        )
            port map (
                    clk => clk,
                    rst => rst,
                    halt => halt,
                    in_port => to_edge(i),
                    in_req => to_edge_req(i),
                    in_ack => to_edge_ack(i),
                    out_port => from_edge(i),
                    out_req => from_edge_req(i),
                    out_ack => from_edge_ack(i)
                     );
             end generate;
        GENERATE_SIMPLE_INV_BACKEDGE : if (EDGE_TYPES(i) = simple_inv_backedge) generate
            simpleinvbackedge : bg_edge_simple
            generic map (
                            INVERTS => true,
                            IS_BACKEDGE => true
                        )
            port map (
                    clk => clk,
                    rst => rst,
                    halt => halt,
                    in_port => to_edge(i),
                    in_req => to_edge_req(i),
                    in_ack => to_edge_ack(i),
                    out_port => from_edge(i),
                    out_req => from_edge_req(i),
                    out_ack => from_edge_ack(i)
                     );
             end generate;
        end generate;

    -- instantiate merges
    GENERATE_MERGES : for i in NO_MERGES-1 downto 0 generate

        GENERATE_MERGE_SUM_SIMPLE : if (MERGE_TYPE(i) = simple_sum) generate
            merge_sum_simple : bg_pipe_simple
            port map (
                        clk => clk,
                        rst => rst,
                        halt => halt,
                        in_port  => to_merge(i)(0),
                        in_req   => to_merge_req(i)(0),
                        in_ack   => to_merge_ack(i)(0),
                        out_port => from_merge(i),
                        out_req  => from_merge_req(i),
                        out_ack  => from_merge_ack(i)
                     );
            end generate;

        GENERATE_MERGE_PROD_SIMPLE : if (MERGE_TYPE(i) = simple_prod) generate
            merge_prod_simple : bg_pipe_simple
            port map (
                        clk => clk,
                        rst => rst,
                        halt => halt,
                        in_port  => to_merge(i)(0),
                        in_req   => to_merge_req(i)(0),
                        in_ack   => to_merge_ack(i)(0),
                        out_port => from_merge(i),
                        out_req  => from_merge_req(i),
                        out_ack  => from_merge_ack(i)
                     );
            end generate;

        GENERATE_MERGE_NORM_SIMPLE : if (MERGE_TYPE(i) = simple_norm) generate
            merge_norm_simple : bg_pipe_simple
            port map (
                        clk => clk,
                        rst => rst,
                        halt => halt,
                        in_port  => to_merge(i)(0),
                        in_req   => to_merge_req(i)(0),
                        in_ack   => to_merge_ack(i)(0),
                        out_port => from_merge(i),
                        out_req  => from_merge_req(i),
                        out_ack  => from_merge_ack(i)
                     );
            end generate;

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

        GENERATE_MERGE_MEAN : if (MERGE_TYPE(i) = mean) generate
            merge_mean : bg_merge_mean
            generic map (
                            NO_INPUTS => MERGE_INPUTS(i),
                            NO_INPUTS_F => MERGE_INPUTS_F(i)
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

        GENERATE_MERGE_WSUM : if (MERGE_TYPE(i) = wsum) generate
            merge_wsum : bg_merge_wsum
            generic map (
                            NO_INPUTS => MERGE_INPUTS(i)
                        )
            port map (
                        clk => clk,
                        rst => rst,
                        halt => halt,
                        in_bias  => MERGE_BIAS(i),
                        in_weights => merge_wsum_weights(i)(MERGE_INPUTS(i)-1 downto 0),
                        in_port  => to_merge(i)(MERGE_INPUTS(i)-1 downto 0),
                        in_req   => to_merge_req(i)(MERGE_INPUTS(i)-1 downto 0),
                        in_ack   => to_merge_ack(i)(MERGE_INPUTS(i)-1 downto 0),
                        out_port => from_merge(i),
                        out_req  => from_merge_req(i),
                        out_ack  => from_merge_ack(i)
                     );
            end generate;

        GENERATE_MERGE_NORM : if (MERGE_TYPE(i) = norm) generate
            merge_norm : bg_merge_norm
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

        GENERATE_MERGE_MAX : if (MERGE_TYPE(i) = max) generate
            merge_max : bg_merge_max
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

        GENERATE_MERGE_MIN : if (MERGE_TYPE(i) = min) generate
            merge_min : bg_merge_min
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
            pipe : bg_pipe_simple
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
        GENERATE_ABS : if (UNARY_TYPES(i) = absolute) generate
            absolute : bg_abs
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
        GENERATE_DIV : if (UNARY_TYPES(i) = div) generate
            div : bg_inverse
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
        GENERATE_SQRT : if (UNARY_TYPES(i) = sqrt) generate
            sqrt : bg_sqrt
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
        GENERATE_COSINE : if (UNARY_TYPES(i) = cosine) generate
            cosine : bg_cosine
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
        GENERATE_ACOS : if (UNARY_TYPES(i) = acos) generate
            acos : bg_acos
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
        GENERATE_SINE : if (UNARY_TYPES(i) = sine) generate
            sine : bg_sine
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
        GENERATE_ASIN : if (UNARY_TYPES(i) = asin) generate
            asin : bg_asin
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
        GENERATE_TAN : if (UNARY_TYPES(i) = tan) generate
            tan : bg_tan
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
        GENERATE_ATAN : if (UNARY_TYPES(i) = atan) generate
            atan : bg_atan
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
        GENERATE_LOG : if (UNARY_TYPES(i) = log) generate
            log : bg_log
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
        GENERATE_EXP : if (UNARY_TYPES(i) = exp) generate
            exp : bg_exp
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

    -- instantiate binary nodes
    GENERATE_BINARY : for i in NO_BINARY-1 downto 0 generate
        GENERATE_FMOD : if (BINARY_TYPES(i) = fmod) generate
            fmod : bg_fmod
            port map (
                    clk => clk,
                    rst => rst,
                    halt => halt,
                    in_port => to_binary(i),
                    in_req => to_binary_req(i),
                    in_ack => to_binary_ack(i),
                    out_port => from_binary(i)(0),
                    out_req => from_binary_req(i)(0),
                    out_ack => from_binary_ack(i)(0)
                     );
                 end generate;
        GENERATE_ATAN2 : if (BINARY_TYPES(i) = atan2) generate
            atan2 : bg_atan2
            port map (
                    clk => clk,
                    rst => rst,
                    halt => halt,
                    in_port => to_binary(i),
                    in_req => to_binary_req(i),
                    in_ack => to_binary_ack(i),
                    out_port => from_binary(i)(0),
                    out_req => from_binary_req(i)(0),
                    out_ack => from_binary_ack(i)(0)
                     );
                 end generate;
        GENERATE_POW : if (BINARY_TYPES(i) = pow) generate
            pow : bg_pow
            port map (
                    clk => clk,
                    rst => rst,
                    halt => halt,
                    in_port => to_binary(i),
                    in_req => to_binary_req(i),
                    in_ack => to_binary_ack(i),
                    out_port => from_binary(i)(0),
                    out_req => from_binary_req(i)(0),
                    out_ack => from_binary_ack(i)(0)
                     );
                 end generate;
        end generate;

    -- instantiate ternary nodes
    GENERATE_TERNARY : for i in NO_TERNARY-1 downto 0 generate
        GENERATE_GREATER_THAN_ZERO : if (TERNARY_TYPES(i) = greater_than_zero) generate
            greater : bg_greater_than_zero
            port map (
                    clk => clk,
                    rst => rst,
                    halt => halt,
                    in_port => to_ternary(i),
                    in_req => to_ternary_req(i),
                    in_ack => to_ternary_ack(i),
                    out_port => from_ternary(i)(0),
                    out_req => from_ternary_req(i)(0),
                    out_ack => from_ternary_ack(i)(0)
                     );
                 end generate;
        GENERATE_LESS_THAN_EPSILON : if (TERNARY_TYPES(i) = less_than_epsilon) generate
            less : bg_less_than_epsilon
            port map (
                    clk => clk,
                    rst => rst,
                    halt => halt,
                    in_port => to_ternary(i),
                    in_req => to_ternary_req(i),
                    in_ack => to_ternary_ack(i),
                    in_epsilon => EPSILON,
                    out_port => from_ternary(i)(0),
                    out_req => from_ternary_req(i)(0),
                    out_ack => from_ternary_ack(i)(0)
                     );
                 end generate;
        end generate;

end Behavioral;
