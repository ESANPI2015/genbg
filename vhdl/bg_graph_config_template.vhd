--
-- TEMPLATE FOR BEHAVIOUR GRAPHS TO VHDL
--
-- Contains all necessary constants, types etc. for synthesis 
--
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
    constant NO_INPUTS  : integer := @topLvlInputs@;
    constant NO_OUTPUTS : integer := @topLvlOutputs@;
    constant NO_EDGES   : integer := @edges@;
    constant NO_PIPES   : integer := @pipes@;
    constant NO_SOURCES : integer := @sources@;
    constant NO_SINKS   : integer := @sinks@;
    constant NO_COPIES  : integer := @copies@;
    constant NO_MERGE   : integer := @merges@;

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
    type edge_types_t is array (NO_EDGES downto 0) of boolean;
    constant EDGE_WEIGHTS : edge_weights_t := 
    (
        @weight0@
        others => ("00000000000000000000000000000000") -- dummy
    );
    constant EDGE_TYPES : edge_types_t :=
    (
        @backEdge0@
        others => false
    );

    -----
    -- Pipe types (replaces an edge with weight 1.0)
    ----
    type pipe_ports_t is array (NO_EDGES-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type pipe_signals_t is array (NO_EDGES-1 downto 0) of std_logic;

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
    type merge_type_t is (none, sum, prod);
    type merge_types_t is array (NO_MERGE downto 0) of merge_type_t;
    constant MERGE_TYPE : merge_types_t :=
    (
        @mergeType0@
        others => none
    );
    type merge_bias_t is array (NO_MERGE downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    constant MERGE_BIAS : merge_bias_t :=
    (
        @mergeBias0@
        others => ("00000000000000000000000000000000") -- dummy
    );
    constant MERGE_INPUTS : int_array_t(NO_MERGE downto 0) :=
    (
        @mergeInputs0@
        others => (0) -- dummy
    );
    -- NOTE: We need the maximum number of merge inputs to generate signals for the merges
    constant MAX_MERGE_INPUTS : integer := find_max_int(MERGE_INPUTS); -- this has to be equal to the max of the MERGE_INPUTS array
    type merge_input_ports_t is array(NO_MERGE-1 downto 0) of DATA_PORT(MAX_MERGE_INPUTS-1 downto 0);
    type merge_input_signals_t is array(NO_MERGE-1 downto 0) of DATA_SIGNAL(MAX_MERGE_INPUTS-1 downto 0);
    type merge_output_ports_t is array(NO_MERGE-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type merge_output_signals_t is array(NO_MERGE-1 downto 0) of std_logic;

    -----
    -- Copy types and constant bias
    ----
    constant COPY_OUTPUTS : int_array_t(NO_COPIES downto 0) :=
    (
        @copyOutputs0@
        others => (0) -- dummy
    );
    -- NOTE: We need the maximum number of copy outputs to generate signals for the copies
    constant MAX_COPY_OUTPUTS : integer := find_max_int(COPY_OUTPUTS); -- this has to be equal to the max of the COPY_OUTPUTS array
    type copy_input_ports_t is array(NO_COPIES-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    type copy_input_signals_t is array(NO_COPIES-1 downto 0) of std_logic;
    type copy_output_ports_t is array(NO_COPIES-1 downto 0) of DATA_PORT(MAX_COPY_OUTPUTS-1 downto 0);
    type copy_output_signals_t is array(NO_COPIES-1 downto 0) of DATA_SIGNAL(MAX_COPY_OUTPUTS-1 downto 0);
end;
