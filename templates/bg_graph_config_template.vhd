--
-- TEMPLATE FOR BEHAVIOUR GRAPHS TO VHDL
--
-- Contains all necessary constants, types etc. for synthesis 
--
-- Instance: @name@
-- @info@
--
-- Author: M. Schilling
-- Date: 2015/10/14

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.bg_vhdl_types.all;

package bg_graph_@name@_config is

    -----
    -- Important constants for instantiation
    ----
    constant NO_INPUTS  : integer := @toplvlInputs@;
    constant NO_OUTPUTS : integer := @toplvlOutputs@;
    constant NO_EDGES   : integer := @edges@;
    constant NO_SOURCES : integer := @sources@;
    constant NO_SINKS   : integer := @sinks@;
    constant NO_COPIES  : integer := @copies@;
    -- TODO: Add other merges
    constant NO_MERGES  : integer := @merges@;
    -- TODO: Add other nodes
    constant NO_UNARY   : integer := @unaryNodes@;
    constant NO_BINARY  : integer := @binaryNodes@;
    constant NO_TERNARY : integer := @ternaryNodes@;
    constant EPSILON : std_logic_vector(DATA_WIDTH-1 downto 0) := @epsilon@;

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
    type edge_type_t is (simple, simple_inv, normal, simple_backedge, simple_inv_backedge, backedge); -- simple* will be replaced by bg_edge_simple
    type edge_types_t is array (NO_EDGES downto 0) of edge_type_t;
    constant EDGE_WEIGHTS : edge_weights_t := 
    (
        @weight0@
        others => ("00000000000000000000000000000000") -- dummy
    );
    constant EDGE_TYPES : edge_types_t :=
    (
        @edgeType0@
        others => normal
    );

    -----
    -- Unary types
    ----
    type unary_ports_t is array (NO_UNARY-1 downto 0) of DATA_PORT(0 downto 0);
    type unary_signals_t is array (NO_UNARY-1 downto 0) of DATA_SIGNAL(0 downto 0);
    type unary_type_t is (none, pipe, div, sqrt, absolute, cosine, sine, tan, acos, asin, atan);
    type unary_types_t is array (NO_UNARY downto 0) of unary_type_t;
    constant UNARY_TYPES : unary_types_t :=
    (
        @unaryType0@
        others => none
    );

    -----
    -- Binary types
    ----
    type binary_input_ports_t is array (NO_BINARY-1 downto 0) of DATA_PORT(1 downto 0);
    type binary_input_signals_t is array (NO_BINARY-1 downto 0) of DATA_SIGNAL(1 downto 0);
    type binary_output_ports_t is array (NO_BINARY-1 downto 0) of DATA_PORT(0 downto 0);
    type binary_output_signals_t is array (NO_BINARY-1 downto 0) of DATA_SIGNAL(0 downto 0);
    type binary_type_t is (none, fmod, atan2, pow);
    type binary_types_t is array (NO_BINARY downto 0) of binary_type_t;
    constant BINARY_TYPES : binary_types_t :=
    (
        @binaryType0@
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
        @ternaryType0@
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
        @srcValue0@
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
    type merge_type_t is (none, simple_sum, sum, simple_prod, prod, max, min, simple_norm, norm, mean, wsum); -- simple* will be replaced by pipe
    type merge_types_t is array (NO_MERGES downto 0) of merge_type_t;
    type merge_bias_t is array (NO_MERGES downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type merge_output_ports_t is array(NO_MERGES-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type merge_output_signals_t is array(NO_MERGES-1 downto 0) of std_logic;
    constant MERGE_TYPE : merge_types_t :=
    (
        @mergeType0@
        others => none
    );
    constant MERGE_BIAS : merge_bias_t :=
    (
        @mergeBias0@
        others => ("00000000000000000000000000000000") -- dummy
    );
    constant MERGE_INPUTS : int_array_t(NO_MERGES downto 0) :=
    (
        @mergeInputs0@
        others => 0 -- dummy
    );
    constant MERGE_INPUTS_F : merge_bias_t :=
    (
        @mergeInputsFloat0@
        others => (x"00000000") -- dummy
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
        @copyOutputs0@
        others => 0 -- dummy
    );
    -- NOTE: We need the maximum number of copy outputs to generate signals for the copies
    constant MAX_COPY_OUTPUTS : integer := find_max_int(COPY_OUTPUTS); -- this has to be equal to the max of the COPY_OUTPUTS array
    type copy_output_ports_t is array(NO_COPIES-1 downto 0) of DATA_PORT(MAX_COPY_OUTPUTS-1 downto 0);
    type copy_output_signals_t is array(NO_COPIES-1 downto 0) of DATA_SIGNAL(MAX_COPY_OUTPUTS-1 downto 0);
end;
