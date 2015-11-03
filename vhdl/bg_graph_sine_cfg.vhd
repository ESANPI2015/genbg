--
-- TEMPLATE FOR BEHAVIOUR GRAPHS TO VHDL
--
-- Contains all necessary constants, types etc. for synthesis 
--
-- Instance: sine
-- GENERATED: Tue Nov  3 17:31:47 2015
--
--
-- Author: M. Schilling
-- Date: 2015/10/14

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.bg_vhdl_types.all;

package bg_graph_sine_config is

    -----
    -- Important constants for instantiation
    ----
    constant NO_INPUTS  : integer := 1;
    constant NO_OUTPUTS : integer := 1;
    constant NO_EDGES   : integer := 45;
    constant NO_SOURCES : integer := 1;
    constant NO_SINKS   : integer := 0;
    constant NO_COPIES  : integer := 31;
    constant NO_MERGES  : integer := 37;
    -- TODO: Add other nodes
    constant NO_UNARY   : integer := 28;
    constant NO_BINARY  : integer := 1;
    constant NO_TERNARY : integer := 3;
    constant EPSILON : std_logic_vector(DATA_WIDTH-1 downto 0) := x"358637bd"; -- 0.000001f;

    -----
    -- Helper function to find the maximum in a 1D array
    -----
    type int_array_t is array (natural range <>) of integer;
    function find_max_int (X : int_array_t) return integer is
        variable max : integer;
    begin
        max := X(0);
        for i in X'range loop
            if (X(i) > max) then
                max := X(i);
            end if;
        end loop;
        return max;
    end find_max_int;

    -----
    -- Edge types and constant weights
    ----
    type edge_ports_t is array (NO_EDGES-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type edge_signals_t is array (NO_EDGES-1 downto 0) of std_logic;
    type edge_weights_t is array (NO_EDGES downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type edge_type_t is (simple, normal, simple_backedge, backedge); -- simple* will be replaced by bg_edge_simple
    type edge_types_t is array (NO_EDGES downto 0) of edge_type_t;
    constant EDGE_WEIGHTS : edge_weights_t := 
    (
        0 => x"3f800000", -- 1.000000f
1 => x"3f800000", -- 1.000000f
2 => x"3f800000", -- 1.000000f
3 => x"3f800000", -- 1.000000f
4 => x"bf800000", -- -1.000000f
5 => x"3f800000", -- 1.000000f
6 => x"bf800000", -- -1.000000f
7 => x"3f800000", -- 1.000000f
8 => x"3f800000", -- 1.000000f
9 => x"3f800000", -- 1.000000f
10 => x"3f800000", -- 1.000000f
11 => x"3f800000", -- 1.000000f
12 => x"3f800000", -- 1.000000f
13 => x"3f800000", -- 1.000000f
14 => x"3f800000", -- 1.000000f
15 => x"3f800000", -- 1.000000f
16 => x"3f800000", -- 1.000000f
17 => x"3f800000", -- 1.000000f
18 => x"3f800000", -- 1.000000f
19 => x"3f800000", -- 1.000000f
20 => x"3f800000", -- 1.000000f
21 => x"3f800000", -- 1.000000f
22 => x"3f800000", -- 1.000000f
23 => x"3f800000", -- 1.000000f
24 => x"3f800000", -- 1.000000f
25 => x"bf800000", -- -1.000000f
26 => x"3f800000", -- 1.000000f
27 => x"3f800000", -- 1.000000f
28 => x"3f800000", -- 1.000000f
29 => x"3f800000", -- 1.000000f
30 => x"3f800000", -- 1.000000f
31 => x"3f800000", -- 1.000000f
32 => x"3f800000", -- 1.000000f
33 => x"bf800000", -- -1.000000f
34 => x"3f800000", -- 1.000000f
35 => x"3f800000", -- 1.000000f
36 => x"3f800000", -- 1.000000f
37 => x"3f800000", -- 1.000000f
38 => x"3f800000", -- 1.000000f
39 => x"3f800000", -- 1.000000f
40 => x"3f800000", -- 1.000000f
41 => x"3f800000", -- 1.000000f
42 => x"3f800000", -- 1.000000f
43 => x"3f800000", -- 1.000000f
44 => x"3f800000", -- 1.000000f
-- DONE
        others => ("00000000000000000000000000000000") -- dummy
    );
    constant EDGE_TYPES : edge_types_t :=
    (
        0 => simple,
1 => simple,
2 => simple,
3 => simple,
5 => simple,
7 => simple,
8 => simple,
9 => simple,
10 => simple,
11 => simple,
12 => simple,
13 => simple,
14 => simple,
15 => simple,
16 => simple,
17 => simple,
18 => simple,
19 => simple,
20 => simple,
21 => simple,
22 => simple,
23 => simple,
24 => simple,
26 => simple,
27 => simple,
28 => simple,
29 => simple,
30 => simple,
31 => simple,
32 => simple,
34 => simple,
35 => simple,
36 => simple,
37 => simple,
38 => simple,
39 => simple,
40 => simple,
41 => simple,
42 => simple,
43 => simple,
44 => simple,
-- DONE
        others => normal
    );

    -----
    -- Unary types
    ----
    type unary_ports_t is array (NO_UNARY-1 downto 0) of DATA_PORT(0 downto 0);
    type unary_signals_t is array (NO_UNARY-1 downto 0) of DATA_SIGNAL(0 downto 0);
    type unary_type_t is (none, pipe, div, sqrt, absolute);
    type unary_types_t is array (NO_UNARY downto 0) of unary_type_t;
    constant UNARY_TYPES : unary_types_t :=
    (
        0 => pipe,
1 => pipe,
2 => pipe,
3 => pipe,
4 => pipe,
5 => pipe,
6 => pipe,
7 => pipe,
8 => pipe,
9 => pipe,
10 => pipe,
11 => pipe,
12 => pipe,
13 => pipe,
14 => pipe,
15 => pipe,
16 => pipe,
17 => pipe,
18 => pipe,
19 => pipe,
20 => pipe,
21 => pipe,
22 => pipe,
23 => pipe,
24 => pipe,
25 => pipe,
26 => pipe,
27 => pipe,
-- DONE
        others => none
    );

    -----
    -- Binary types
    ----
    type binary_input_ports_t is array (NO_BINARY-1 downto 0) of DATA_PORT(1 downto 0);
    type binary_input_signals_t is array (NO_BINARY-1 downto 0) of DATA_SIGNAL(1 downto 0);
    type binary_output_ports_t is array (NO_BINARY-1 downto 0) of DATA_PORT(0 downto 0);
    type binary_output_signals_t is array (NO_BINARY-1 downto 0) of DATA_SIGNAL(0 downto 0);
    type binary_type_t is (none, fmod);
    type binary_types_t is array (NO_BINARY downto 0) of binary_type_t;
    constant BINARY_TYPES : binary_types_t :=
    (
        0 => fmod,
-- DONE
        others => none
    );

    -----
    -- Ternary types
    ----
    type ternary_input_ports_t is array (NO_TERNARY-1 downto 0) of DATA_PORT(2 downto 0);
    type ternary_input_signals_t is array (NO_TERNARY-1 downto 0) of DATA_SIGNAL(2 downto 0);
    type ternary_output_ports_t is array (NO_TERNARY-1 downto 0) of DATA_PORT(0 downto 0);
    type ternary_output_signals_t is array (NO_TERNARY-1 downto 0) of DATA_SIGNAL(0 downto 0);
    type ternary_type_t is (none, greater_than_zero, less_than_epsilon);
    type ternary_types_t is array (NO_TERNARY downto 0) of ternary_type_t;
    constant TERNARY_TYPES : ternary_types_t :=
    (
        0 => greater_than_zero,
1 => greater_than_zero,
2 => greater_than_zero,
-- DONE
        others => none
    );

    -----
    -- Source types and constant values (replaces a merge with no inputs)
    ----
    type source_ports_t is array (NO_SOURCES-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type source_signal_t is array (NO_SOURCES-1 downto 0) of std_logic;
    type source_values_t is array (NO_SOURCES downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    constant SOURCE_VALUES : source_values_t :=
    (
        0 => x"40c90fdb", -- 6.283185f
-- DONE
        others => ("00000000000000000000000000000000") -- dummy
    );

    -----
    -- Sink types
    ----
    type sink_ports_t is array (NO_SINKS-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type sink_signal_t is array (NO_SINKS-1 downto 0) of std_logic;

    -----
    -- Merge types and constant bias
    ----
    type merge_type_t is (none, simple_sum, sum, simple_prod, prod); -- simple* will be replaced by pipe
    type merge_types_t is array (NO_MERGES downto 0) of merge_type_t;
    type merge_bias_t is array (NO_MERGES downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type merge_output_ports_t is array(NO_MERGES-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type merge_output_signals_t is array(NO_MERGES-1 downto 0) of std_logic;
    constant MERGE_TYPE : merge_types_t :=
    (
        0 => simple_sum,
1 => simple_sum,
2 => prod,
3 => sum,
4 => prod,
5 => prod,
6 => sum,
7 => prod,
8 => sum,
9 => sum,
10 => prod,
11 => prod,
12 => sum,
13 => prod,
14 => sum,
15 => sum,
16 => prod,
17 => prod,
18 => sum,
19 => prod,
20 => sum,
21 => simple_sum,
22 => prod,
23 => prod,
24 => sum,
25 => prod,
26 => sum,
27 => sum,
28 => prod,
29 => simple_sum,
30 => sum,
31 => prod,
32 => simple_sum,
33 => sum,
34 => simple_sum,
35 => simple_sum,
36 => simple_sum,
-- DONE
        others => none
    );
    constant MERGE_BIAS : merge_bias_t :=
    (
        0 => x"00000000", -- 0.000000f
1 => x"00000000", -- 0.000000f
2 => x"3f22f983", -- 0.636620f
3 => x"40800000", -- 4.000000f
4 => x"3f800000", -- 1.000000f
5 => x"be5bc095", -- -0.214602f
6 => x"3f9b7813", -- 1.214602f
7 => x"bf800000", -- -1.000000f
8 => x"3f800000", -- 1.000000f
9 => x"c0000000", -- -2.000000f
10 => x"3f800000", -- 1.000000f
11 => x"be5bc095", -- -0.214602f
12 => x"3f9b7813", -- 1.214602f
13 => x"bf800000", -- -1.000000f
14 => x"3f800000", -- 1.000000f
15 => x"40000000", -- 2.000000f
16 => x"3f800000", -- 1.000000f
17 => x"be5bc095", -- -0.214602f
18 => x"3f9b7813", -- 1.214602f
19 => x"bf800000", -- -1.000000f
20 => x"3f800000", -- 1.000000f
21 => x"00000000", -- 0.000000f
22 => x"3f800000", -- 1.000000f
23 => x"be5bc095", -- -0.214602f
24 => x"3f9b7813", -- 1.214602f
25 => x"bf800000", -- -1.000000f
26 => x"3f800000", -- 1.000000f
27 => x"bf800000", -- -1.000000f
28 => x"bf800000", -- -1.000000f
29 => x"00000000", -- 0.000000f
30 => x"c0000000", -- -2.000000f
31 => x"bf800000", -- -1.000000f
32 => x"00000000", -- 0.000000f
33 => x"c0400000", -- -3.000000f
34 => x"00000000", -- 0.000000f
35 => x"00000000", -- 0.000000f
36 => x"00000000", -- 0.000000f
-- DONE
        others => ("00000000000000000000000000000000") -- dummy
    );
    constant MERGE_INPUTS : int_array_t(NO_MERGES downto 0) :=
    (
        0 => 1,
1 => 1,
2 => 1,
3 => 1,
4 => 2,
5 => 1,
6 => 1,
7 => 2,
8 => 1,
9 => 1,
10 => 2,
11 => 1,
12 => 1,
13 => 2,
14 => 1,
15 => 1,
16 => 2,
17 => 1,
18 => 1,
19 => 2,
20 => 1,
21 => 1,
22 => 2,
23 => 1,
24 => 1,
25 => 2,
26 => 1,
27 => 1,
28 => 1,
29 => 1,
30 => 1,
31 => 1,
32 => 1,
33 => 1,
34 => 1,
35 => 1,
36 => 1,
-- DONE
        others => 0 -- dummy
    );
    -- NOTE: We need the maximum number of merge inputs to generate signals for the merges
    constant MAX_MERGE_INPUTS : integer := find_max_int(MERGE_INPUTS); -- this has to be equal to the max of the MERGE_INPUTS array
    type merge_input_ports_t is array(NO_MERGES-1 downto 0) of DATA_PORT(MAX_MERGE_INPUTS-1 downto 0);
    type merge_input_signals_t is array(NO_MERGES-1 downto 0) of DATA_SIGNAL(MAX_MERGE_INPUTS-1 downto 0);

    -----
    -- Copy types and constant bias
    ----
    type copy_input_ports_t is array(NO_COPIES-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type copy_input_signals_t is array(NO_COPIES-1 downto 0) of std_logic;
    constant COPY_OUTPUTS : int_array_t(NO_COPIES downto 0) :=
    (
        0 => 1,
1 => 1,
2 => 1,
3 => 7,
4 => 2,
5 => 2,
6 => 1,
7 => 1,
8 => 1,
9 => 1,
10 => 2,
11 => 2,
12 => 1,
13 => 1,
14 => 1,
15 => 1,
16 => 2,
17 => 2,
18 => 1,
19 => 1,
20 => 1,
21 => 1,
22 => 2,
23 => 2,
24 => 1,
25 => 1,
26 => 1,
27 => 1,
28 => 1,
29 => 1,
30 => 1,
-- DONE
        others => 0 -- dummy
    );
    -- NOTE: We need the maximum number of copy outputs to generate signals for the copies
    constant MAX_COPY_OUTPUTS : integer := find_max_int(COPY_OUTPUTS); -- this has to be equal to the max of the COPY_OUTPUTS array
    type copy_output_ports_t is array(NO_COPIES-1 downto 0) of DATA_PORT(MAX_COPY_OUTPUTS-1 downto 0);
    type copy_output_signals_t is array(NO_COPIES-1 downto 0) of DATA_SIGNAL(MAX_COPY_OUTPUTS-1 downto 0);
end;
