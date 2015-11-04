--
-- TEMPLATE FOR BEHAVIOUR GRAPHS TO VHDL
--
-- Components are instantiated and wired for synthesis
--
-- Instance: cosine
-- GENERATED: Wed Nov  4 10:52:09 2015
--
--
-- Author: M. Schilling
-- Date: 2015/10/14

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
use work.bg_graph_components.all;
use work.bg_graph_cosine_config.all;
-- Add additional libraries here

entity bg_graph_cosine is
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
end bg_graph_cosine;

architecture Behavioral of bg_graph_cosine is

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
    to_unary(0)(0) <= from_external(0);
to_unary_req(0)(0) <= from_external_req(0);
from_external_ack(0) <= to_unary_ack(0)(0);

to_copy(0) <= from_unary(0)(0);
to_copy_req(0) <= from_unary_req(0)(0);
from_unary_ack(0)(0) <=to_copy_ack(0);

to_edge(0) <= from_copy(0)(0);
to_edge_req(0) <= from_copy_req(0)(0);
from_copy_ack(0)(0) <=to_edge_ack(0);

to_merge(0)(0) <= from_edge(0);
to_merge_req(0)(0) <= from_edge_req(0);
from_edge_ack(0) <= to_merge_ack(0)(0);

to_unary(1)(0) <= from_merge(0);
to_unary_req(1)(0) <= from_merge_req(0);
from_merge_ack(0) <= to_unary_ack(1)(0);

to_copy(1) <= from_unary(1)(0);
to_copy_req(1) <= from_unary_req(1)(0);
from_unary_ack(1)(0) <=to_copy_ack(1);

to_edge(1) <= from_copy(1)(0);
to_edge_req(1) <= from_copy_req(1)(0);
from_copy_ack(1)(0) <=to_edge_ack(1);

to_merge(1)(0) <= from_edge(1);
to_merge_req(1)(0) <= from_edge_req(1);
from_edge_ack(1) <= to_merge_ack(1)(0);

to_unary(2)(0) <= from_merge(1);
to_unary_req(2)(0) <= from_merge_req(1);
from_merge_ack(1) <= to_unary_ack(2)(0);

to_copy(2) <= from_unary(2)(0);
to_copy_req(2) <= from_unary_req(2)(0);
from_unary_ack(2)(0) <=to_copy_ack(2);

to_edge(2) <= from_copy(2)(0);
to_edge_req(2) <= from_copy_req(2)(0);
from_copy_ack(2)(0) <=to_edge_ack(2);

to_merge(2)(0) <= from_edge(2);
to_merge_req(2)(0) <= from_edge_req(2);
from_edge_ack(2) <= to_merge_ack(2)(0);

to_binary(0)(0) <= from_merge(2);
to_binary_req(0)(0) <= from_merge_req(2);
from_merge_ack(2) <= to_binary_ack(0)(0);

to_binary(0)(1) <= from_source(0);
to_binary_req(0)(1) <= from_source_req(0);
from_source_ack(0) <= to_binary_ack(0)(1);

to_copy(3) <= from_binary(0)(0);
to_copy_req(3) <= from_binary_req(0)(0);
from_binary_ack(0)(0) <=to_copy_ack(3);

to_edge(3) <= from_copy(3)(0);
to_edge_req(3) <= from_copy_req(3)(0);
from_copy_ack(3)(0) <=to_edge_ack(3);

to_edge(4) <= from_copy(3)(1);
to_edge_req(4) <= from_copy_req(3)(1);
from_copy_ack(3)(1) <=to_edge_ack(4);

to_merge(3)(0) <= from_edge(4);
to_merge_req(3)(0) <= from_edge_req(4);
from_edge_ack(4) <= to_merge_ack(3)(0);

to_unary(3)(0) <= from_merge(3);
to_unary_req(3)(0) <= from_merge_req(3);
from_merge_ack(3) <= to_unary_ack(3)(0);

to_copy(4) <= from_unary(3)(0);
to_copy_req(4) <= from_unary_req(3)(0);
from_unary_ack(3)(0) <=to_copy_ack(4);

to_edge(5) <= from_copy(4)(0);
to_edge_req(5) <= from_copy_req(4)(0);
from_copy_ack(4)(0) <=to_edge_ack(5);

to_edge(6) <= from_copy(4)(1);
to_edge_req(6) <= from_copy_req(4)(1);
from_copy_ack(4)(1) <=to_edge_ack(6);

to_merge(4)(0) <= from_edge(3);
to_merge_req(4)(0) <= from_edge_req(3);
from_edge_ack(3) <= to_merge_ack(4)(0);

to_unary(4)(0) <= from_merge(4);
to_unary_req(4)(0) <= from_merge_req(4);
from_merge_ack(4) <= to_unary_ack(4)(0);

to_copy(5) <= from_unary(4)(0);
to_copy_req(5) <= from_unary_req(4)(0);
from_unary_ack(4)(0) <=to_copy_ack(5);

to_edge(7) <= from_copy(5)(0);
to_edge_req(7) <= from_copy_req(5)(0);
from_copy_ack(5)(0) <=to_edge_ack(7);

to_merge(5)(0) <= from_edge(7);
to_merge_req(5)(0) <= from_edge_req(7);
from_edge_ack(7) <= to_merge_ack(5)(0);

to_unary(5)(0) <= from_merge(5);
to_unary_req(5)(0) <= from_merge_req(5);
from_merge_ack(5) <= to_unary_ack(5)(0);

to_copy(6) <= from_unary(5)(0);
to_copy_req(6) <= from_unary_req(5)(0);
from_unary_ack(5)(0) <=to_copy_ack(6);

to_edge(8) <= from_copy(6)(0);
to_edge_req(8) <= from_copy_req(6)(0);
from_copy_ack(6)(0) <=to_edge_ack(8);

to_edge(9) <= from_copy(6)(1);
to_edge_req(9) <= from_copy_req(6)(1);
from_copy_ack(6)(1) <=to_edge_ack(9);

to_edge(10) <= from_copy(6)(2);
to_edge_req(10) <= from_copy_req(6)(2);
from_copy_ack(6)(2) <=to_edge_ack(10);

to_edge(11) <= from_copy(6)(3);
to_edge_req(11) <= from_copy_req(6)(3);
from_copy_ack(6)(3) <=to_edge_ack(11);

to_edge(12) <= from_copy(6)(4);
to_edge_req(12) <= from_copy_req(6)(4);
from_copy_ack(6)(4) <=to_edge_ack(12);

to_edge(13) <= from_copy(6)(5);
to_edge_req(13) <= from_copy_req(6)(5);
from_copy_ack(6)(5) <=to_edge_ack(13);

to_edge(14) <= from_copy(6)(6);
to_edge_req(14) <= from_copy_req(6)(6);
from_copy_ack(6)(6) <=to_edge_ack(14);

to_merge(6)(0) <= from_edge(9);
to_merge_req(6)(0) <= from_edge_req(9);
from_edge_ack(9) <= to_merge_ack(6)(0);

to_merge(7)(0) <= from_edge(6);
to_merge_req(7)(0) <= from_edge_req(6);
from_edge_ack(6) <= to_merge_ack(7)(0);

to_merge(8)(0) <= from_edge(12);
to_merge_req(8)(0) <= from_edge_req(12);
from_edge_ack(12) <= to_merge_ack(8)(0);

to_ternary(0)(0) <= from_merge(6);
to_ternary_req(0)(0) <= from_merge_req(6);
from_merge_ack(6) <= to_ternary_ack(0)(0);

to_ternary(0)(1) <= from_merge(7);
to_ternary_req(0)(1) <= from_merge_req(7);
from_merge_ack(7) <= to_ternary_ack(0)(1);

to_ternary(0)(2) <= from_merge(8);
to_ternary_req(0)(2) <= from_merge_req(8);
from_merge_ack(8) <= to_ternary_ack(0)(2);

to_copy(7) <= from_ternary(0)(0);
to_copy_req(7) <= from_ternary_req(0)(0);
from_ternary_ack(0)(0) <=to_copy_ack(7);

to_edge(15) <= from_copy(7)(0);
to_edge_req(15) <= from_copy_req(7)(0);
from_copy_ack(7)(0) <=to_edge_ack(15);

to_merge(9)(0) <= from_edge(8);
to_merge_req(9)(0) <= from_edge_req(8);
from_edge_ack(8) <= to_merge_ack(9)(0);

to_merge(10)(0) <= from_edge(5);
to_merge_req(10)(0) <= from_edge_req(5);
from_edge_ack(5) <= to_merge_ack(10)(0);

to_merge(11)(0) <= from_edge(11);
to_merge_req(11)(0) <= from_edge_req(11);
from_edge_ack(11) <= to_merge_ack(11)(0);

to_ternary(1)(0) <= from_merge(9);
to_ternary_req(1)(0) <= from_merge_req(9);
from_merge_ack(9) <= to_ternary_ack(1)(0);

to_ternary(1)(1) <= from_merge(10);
to_ternary_req(1)(1) <= from_merge_req(10);
from_merge_ack(10) <= to_ternary_ack(1)(1);

to_ternary(1)(2) <= from_merge(11);
to_ternary_req(1)(2) <= from_merge_req(11);
from_merge_ack(11) <= to_ternary_ack(1)(2);

to_copy(8) <= from_ternary(1)(0);
to_copy_req(8) <= from_ternary_req(1)(0);
from_ternary_ack(1)(0) <=to_copy_ack(8);

to_edge(16) <= from_copy(8)(0);
to_edge_req(16) <= from_copy_req(8)(0);
from_copy_ack(8)(0) <=to_edge_ack(16);

to_merge(12)(0) <= from_edge(10);
to_merge_req(12)(0) <= from_edge_req(10);
from_edge_ack(10) <= to_merge_ack(12)(0);

to_merge(13)(0) <= from_edge(15);
to_merge_req(13)(0) <= from_edge_req(15);
from_edge_ack(15) <= to_merge_ack(13)(0);

to_merge(14)(0) <= from_edge(16);
to_merge_req(14)(0) <= from_edge_req(16);
from_edge_ack(16) <= to_merge_ack(14)(0);

to_ternary(2)(0) <= from_merge(12);
to_ternary_req(2)(0) <= from_merge_req(12);
from_merge_ack(12) <= to_ternary_ack(2)(0);

to_ternary(2)(1) <= from_merge(13);
to_ternary_req(2)(1) <= from_merge_req(13);
from_merge_ack(13) <= to_ternary_ack(2)(1);

to_ternary(2)(2) <= from_merge(14);
to_ternary_req(2)(2) <= from_merge_req(14);
from_merge_ack(14) <= to_ternary_ack(2)(2);

to_copy(9) <= from_ternary(2)(0);
to_copy_req(9) <= from_ternary_req(2)(0);
from_ternary_ack(2)(0) <=to_copy_ack(9);

to_edge(17) <= from_copy(9)(0);
to_edge_req(17) <= from_copy_req(9)(0);
from_copy_ack(9)(0) <=to_edge_ack(17);

to_merge(15)(0) <= from_edge(17);
to_merge_req(15)(0) <= from_edge_req(17);
from_edge_ack(17) <= to_merge_ack(15)(0);

to_unary(6)(0) <= from_merge(15);
to_unary_req(6)(0) <= from_merge_req(15);
from_merge_ack(15) <= to_unary_ack(6)(0);

to_copy(10) <= from_unary(6)(0);
to_copy_req(10) <= from_unary_req(6)(0);
from_unary_ack(6)(0) <=to_copy_ack(10);

to_edge(18) <= from_copy(10)(0);
to_edge_req(18) <= from_copy_req(10)(0);
from_copy_ack(10)(0) <=to_edge_ack(18);

to_edge(19) <= from_copy(10)(1);
to_edge_req(19) <= from_copy_req(10)(1);
from_copy_ack(10)(1) <=to_edge_ack(19);

to_merge(16)(0) <= from_edge(18);
to_merge_req(16)(0) <= from_edge_req(18);
from_edge_ack(18) <= to_merge_ack(16)(0);

to_merge(16)(1) <= from_edge(19);
to_merge_req(16)(1) <= from_edge_req(19);
from_edge_ack(19) <= to_merge_ack(16)(1);

to_unary(7)(0) <= from_merge(16);
to_unary_req(7)(0) <= from_merge_req(16);
from_merge_ack(16) <= to_unary_ack(7)(0);

to_unary(7)(0) <= from_merge(16);
to_unary_req(7)(0) <= from_merge_req(16);
from_merge_ack(16) <= to_unary_ack(7)(0);

to_copy(11) <= from_unary(7)(0);
to_copy_req(11) <= from_unary_req(7)(0);
from_unary_ack(7)(0) <=to_copy_ack(11);

to_edge(20) <= from_copy(11)(0);
to_edge_req(20) <= from_copy_req(11)(0);
from_copy_ack(11)(0) <=to_edge_ack(20);

to_edge(21) <= from_copy(11)(1);
to_edge_req(21) <= from_copy_req(11)(1);
from_copy_ack(11)(1) <=to_edge_ack(21);

to_edge(22) <= from_copy(11)(2);
to_edge_req(22) <= from_copy_req(11)(2);
from_copy_ack(11)(2) <=to_edge_ack(22);

to_merge(17)(0) <= from_edge(20);
to_merge_req(17)(0) <= from_edge_req(20);
from_edge_ack(20) <= to_merge_ack(17)(0);

to_merge(17)(1) <= from_edge(21);
to_merge_req(17)(1) <= from_edge_req(21);
from_edge_ack(21) <= to_merge_ack(17)(1);

to_unary(8)(0) <= from_merge(17);
to_unary_req(8)(0) <= from_merge_req(17);
from_merge_ack(17) <= to_unary_ack(8)(0);

to_unary(8)(0) <= from_merge(17);
to_unary_req(8)(0) <= from_merge_req(17);
from_merge_ack(17) <= to_unary_ack(8)(0);

to_copy(12) <= from_unary(8)(0);
to_copy_req(12) <= from_unary_req(8)(0);
from_unary_ack(8)(0) <=to_copy_ack(12);

to_edge(23) <= from_copy(12)(0);
to_edge_req(23) <= from_copy_req(12)(0);
from_copy_ack(12)(0) <=to_edge_ack(23);

to_merge(18)(0) <= from_edge(22);
to_merge_req(18)(0) <= from_edge_req(22);
from_edge_ack(22) <= to_merge_ack(18)(0);

to_merge(18)(1) <= from_edge(23);
to_merge_req(18)(1) <= from_edge_req(23);
from_edge_ack(23) <= to_merge_ack(18)(1);

to_unary(9)(0) <= from_merge(18);
to_unary_req(9)(0) <= from_merge_req(18);
from_merge_ack(18) <= to_unary_ack(9)(0);

to_unary(9)(0) <= from_merge(18);
to_unary_req(9)(0) <= from_merge_req(18);
from_merge_ack(18) <= to_unary_ack(9)(0);

to_copy(13) <= from_unary(9)(0);
to_copy_req(13) <= from_unary_req(9)(0);
from_unary_ack(9)(0) <=to_copy_ack(13);

to_edge(24) <= from_copy(13)(0);
to_edge_req(24) <= from_copy_req(13)(0);
from_copy_ack(13)(0) <=to_edge_ack(24);

to_edge(25) <= from_copy(13)(1);
to_edge_req(25) <= from_copy_req(13)(1);
from_copy_ack(13)(1) <=to_edge_ack(25);

to_merge(19)(0) <= from_edge(25);
to_merge_req(19)(0) <= from_edge_req(25);
from_edge_ack(25) <= to_merge_ack(19)(0);

to_unary(10)(0) <= from_merge(19);
to_unary_req(10)(0) <= from_merge_req(19);
from_merge_ack(19) <= to_unary_ack(10)(0);

to_copy(14) <= from_unary(10)(0);
to_copy_req(14) <= from_unary_req(10)(0);
from_unary_ack(10)(0) <=to_copy_ack(14);

to_edge(26) <= from_copy(14)(0);
to_edge_req(26) <= from_copy_req(14)(0);
from_copy_ack(14)(0) <=to_edge_ack(26);

to_merge(20)(0) <= from_edge(24);
to_merge_req(20)(0) <= from_edge_req(24);
from_edge_ack(24) <= to_merge_ack(20)(0);

to_unary(11)(0) <= from_merge(20);
to_unary_req(11)(0) <= from_merge_req(20);
from_merge_ack(20) <= to_unary_ack(11)(0);

to_copy(15) <= from_unary(11)(0);
to_copy_req(15) <= from_unary_req(11)(0);
from_unary_ack(11)(0) <=to_copy_ack(15);

to_edge(27) <= from_copy(15)(0);
to_edge_req(27) <= from_copy_req(15)(0);
from_copy_ack(15)(0) <=to_edge_ack(27);

to_merge(21)(0) <= from_edge(27);
to_merge_req(21)(0) <= from_edge_req(27);
from_edge_ack(27) <= to_merge_ack(21)(0);

to_unary(12)(0) <= from_merge(21);
to_unary_req(12)(0) <= from_merge_req(21);
from_merge_ack(21) <= to_unary_ack(12)(0);

to_copy(16) <= from_unary(12)(0);
to_copy_req(16) <= from_unary_req(12)(0);
from_unary_ack(12)(0) <=to_copy_ack(16);

to_edge(28) <= from_copy(16)(0);
to_edge_req(28) <= from_copy_req(16)(0);
from_copy_ack(16)(0) <=to_edge_ack(28);

to_edge(29) <= from_copy(16)(1);
to_edge_req(29) <= from_copy_req(16)(1);
from_copy_ack(16)(1) <=to_edge_ack(29);

to_merge(22)(0) <= from_edge(13);
to_merge_req(22)(0) <= from_edge_req(13);
from_edge_ack(13) <= to_merge_ack(22)(0);

to_merge(23)(0) <= from_edge(26);
to_merge_req(23)(0) <= from_edge_req(26);
from_edge_ack(26) <= to_merge_ack(23)(0);

to_merge(24)(0) <= from_edge(28);
to_merge_req(24)(0) <= from_edge_req(28);
from_edge_ack(28) <= to_merge_ack(24)(0);

to_ternary(3)(0) <= from_merge(22);
to_ternary_req(3)(0) <= from_merge_req(22);
from_merge_ack(22) <= to_ternary_ack(3)(0);

to_ternary(3)(1) <= from_merge(23);
to_ternary_req(3)(1) <= from_merge_req(23);
from_merge_ack(23) <= to_ternary_ack(3)(1);

to_ternary(3)(2) <= from_merge(24);
to_ternary_req(3)(2) <= from_merge_req(24);
from_merge_ack(24) <= to_ternary_ack(3)(2);

to_copy(17) <= from_ternary(3)(0);
to_copy_req(17) <= from_ternary_req(3)(0);
from_ternary_ack(3)(0) <=to_copy_ack(17);

to_edge(30) <= from_copy(17)(0);
to_edge_req(30) <= from_copy_req(17)(0);
from_copy_ack(17)(0) <=to_edge_ack(30);

to_merge(25)(0) <= from_edge(14);
to_merge_req(25)(0) <= from_edge_req(14);
from_edge_ack(14) <= to_merge_ack(25)(0);

to_merge(26)(0) <= from_edge(29);
to_merge_req(26)(0) <= from_edge_req(29);
from_edge_ack(29) <= to_merge_ack(26)(0);

to_merge(27)(0) <= from_edge(30);
to_merge_req(27)(0) <= from_edge_req(30);
from_edge_ack(30) <= to_merge_ack(27)(0);

to_ternary(4)(0) <= from_merge(25);
to_ternary_req(4)(0) <= from_merge_req(25);
from_merge_ack(25) <= to_ternary_ack(4)(0);

to_ternary(4)(1) <= from_merge(26);
to_ternary_req(4)(1) <= from_merge_req(26);
from_merge_ack(26) <= to_ternary_ack(4)(1);

to_ternary(4)(2) <= from_merge(27);
to_ternary_req(4)(2) <= from_merge_req(27);
from_merge_ack(27) <= to_ternary_ack(4)(2);

to_copy(18) <= from_ternary(4)(0);
to_copy_req(18) <= from_ternary_req(4)(0);
from_ternary_ack(4)(0) <=to_copy_ack(18);

to_edge(31) <= from_copy(18)(0);
to_edge_req(31) <= from_copy_req(18)(0);
from_copy_ack(18)(0) <=to_edge_ack(31);

to_merge(28)(0) <= from_edge(31);
to_merge_req(28)(0) <= from_edge_req(31);
from_edge_ack(31) <= to_merge_ack(28)(0);

to_unary(13)(0) <= from_merge(28);
to_unary_req(13)(0) <= from_merge_req(28);
from_merge_ack(28) <= to_unary_ack(13)(0);

to_external(0) <= from_unary(13)(0);
to_external_req(0) <= from_unary_req(13)(0);
from_unary_ack(13)(0) <=to_external_ack(0);

-- DONE

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
            generic map (
                            IS_BACKEDGE => false
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
        -- REMOVED BECAUSE OF CIRCULAR REFERENCE
        --GENERATE_COSINE : if (UNARY_TYPES(i) = cosine) generate
            --cosine : bg_cosine
            --port map (
                    --clk => clk,
                    --rst => rst,
                    --halt => halt,
                    --in_port => to_unary(i)(0),
                    --in_req => to_unary_req(i)(0),
                    --in_ack => to_unary_ack(i)(0),
                    --out_port => from_unary(i)(0),
                    --out_req => from_unary_req(i)(0),
                    --out_ack => from_unary_ack(i)(0)
                     --);
                 --end generate;
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
