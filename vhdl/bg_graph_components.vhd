library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.bg_vhdl_types.all;

package bg_graph_components is
    -----
    -- Components of a VHDL behaviour graph
    ----
	component bg_edge is
        generic (
                    IS_BACKEDGE : boolean := false
                );
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
    end component;

	component bg_edge_simple is
        generic (
                    IS_BACKEDGE : boolean := false
                );
        port(
        -- Inputs
            in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
            in_req : in std_logic;
            in_ack : out std_logic;
        -- Outputs
            out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out_req : out std_logic;
            out_ack : in std_logic;
        -- Other signals
            halt : in std_logic;
            rst : in std_logic;
            clk : in std_logic
            );
    end component;

	component bg_pipe is
        port(
        -- Inputs
            in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
            in_req : in std_logic;
            in_ack : out std_logic;
        -- Outputs
            out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out_req : out std_logic;
            out_ack : in std_logic;
        -- Other signals
            halt : in std_logic;
            rst : in std_logic;
            clk : in std_logic
            );
    end component;

	component bg_pipe_simple is
        port(
        -- Inputs
            in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
            in_req : in std_logic;
            in_ack : out std_logic;
        -- Outputs
            out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out_req : out std_logic;
            out_ack : in std_logic;
        -- Other signals
            halt : in std_logic;
            rst : in std_logic;
            clk : in std_logic
            );
    end component;

	component bg_atan is
        port(
        -- Inputs
            in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
            in_req : in std_logic;
            in_ack : out std_logic;
        -- Outputs
            out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out_req : out std_logic;
            out_ack : in std_logic;
        -- Other signals
            halt : in std_logic;
            rst : in std_logic;
            clk : in std_logic
            );
    end component;

	component bg_cosine is
        port(
        -- Inputs
            in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
            in_req : in std_logic;
            in_ack : out std_logic;
        -- Outputs
            out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out_req : out std_logic;
            out_ack : in std_logic;
        -- Other signals
            halt : in std_logic;
            rst : in std_logic;
            clk : in std_logic
            );
    end component;

	component bg_sine is
        port(
        -- Inputs
            in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
            in_req : in std_logic;
            in_ack : out std_logic;
        -- Outputs
            out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out_req : out std_logic;
            out_ack : in std_logic;
        -- Other signals
            halt : in std_logic;
            rst : in std_logic;
            clk : in std_logic
            );
    end component;

	component bg_tan is
        port(
        -- Inputs
            in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
            in_req : in std_logic;
            in_ack : out std_logic;
        -- Outputs
            out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out_req : out std_logic;
            out_ack : in std_logic;
        -- Other signals
            halt : in std_logic;
            rst : in std_logic;
            clk : in std_logic
            );
    end component;

	component bg_abs is
        port(
        -- Inputs
            in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
            in_req : in std_logic;
            in_ack : out std_logic;
        -- Outputs
            out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out_req : out std_logic;
            out_ack : in std_logic;
        -- Other signals
            halt : in std_logic;
            rst : in std_logic;
            clk : in std_logic
            );
    end component;

	component bg_inverse is
        port(
        -- Inputs
            in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
            in_req : in std_logic;
            in_ack : out std_logic;
        -- Outputs
            out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out_req : out std_logic;
            out_ack : in std_logic;
        -- Other signals
            halt : in std_logic;
            rst : in std_logic;
            clk : in std_logic
            );
    end component;

	component bg_sqrt is
        port(
        -- Inputs
            in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
            in_req : in std_logic;
            in_ack : out std_logic;
        -- Outputs
            out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out_req : out std_logic;
            out_ack : in std_logic;
        -- Other signals
            halt : in std_logic;
            rst : in std_logic;
            clk : in std_logic
            );
    end component;

	component bg_source is
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
    end component;

	component bg_sink is
        port(
        -- Inputs
            in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
            in_req : in std_logic;
            in_ack : out std_logic;
        -- Outputs
            out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
        -- Other signals
            halt : in std_logic;
            rst : in std_logic;
            clk : in std_logic
            );
    end component;

	component bg_copy is
        generic(
                   NO_OUTPUTS : integer := 2
               );
        port(
            -- Inputs
                in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
                in_req : in std_logic;
                in_ack : out std_logic;
            -- Outputs
                out_port : out DATA_PORT(NO_OUTPUTS-1 downto 0);
                out_req : out DATA_SIGNAL(NO_OUTPUTS-1 downto 0);
                out_ack : in DATA_SIGNAL(NO_OUTPUTS-1 downto 0);
            -- Other signals
                halt : in std_logic;
                rst : in std_logic;
                clk : in std_logic
            );
    end component;

	component bg_merge_sum is
        generic(
                   NO_INPUTS : integer := 1
               );
        port(
            -- Inputs
                in_port : in DATA_PORT(NO_INPUTS-1 downto 0);
                in_req : in DATA_SIGNAL(NO_INPUTS-1 downto 0);
                in_ack : out DATA_SIGNAL(NO_INPUTS-1 downto 0);
            -- Special values
                in_bias : in std_logic_vector(DATA_WIDTH-1 downto 0);
            -- Outputs
                out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
                out_req : out std_logic;
                out_ack : in std_logic;
            -- Other signals
                halt : in std_logic;
                rst : in std_logic;
                clk : in std_logic
            );
    end component;

	component bg_merge_wsum is
        generic(
                   NO_INPUTS : integer := 1
               );
        port(
            -- Inputs
                in_port : in DATA_PORT(NO_INPUTS-1 downto 0);
                in_req : in DATA_SIGNAL(NO_INPUTS-1 downto 0);
                in_ack : out DATA_SIGNAL(NO_INPUTS-1 downto 0);
            -- Special values
                in_weights : in DATA_PORT(NO_INPUTS-1 downto 0);
                in_bias : in std_logic_vector(DATA_WIDTH-1 downto 0);
            -- Outputs
                out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
                out_req : out std_logic;
                out_ack : in std_logic;
            -- Other signals
                halt : in std_logic;
                rst : in std_logic;
                clk : in std_logic
            );
    end component;

	component bg_merge_mean is
        generic(
                   NO_INPUTS : integer := 2;
                   NO_INPUTS_F : std_logic_vector(DATA_WIDTH-1 downto 0) := x"40000000" -- 2.0f
               );
        port(
            -- Inputs
                in_port : in DATA_PORT(NO_INPUTS-1 downto 0);
                in_req : in DATA_SIGNAL(NO_INPUTS-1 downto 0);
                in_ack : out DATA_SIGNAL(NO_INPUTS-1 downto 0);
            -- Special values
                in_bias : in std_logic_vector(DATA_WIDTH-1 downto 0);
            -- Outputs
                out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
                out_req : out std_logic;
                out_ack : in std_logic;
            -- Other signals
                halt : in std_logic;
                rst : in std_logic;
                clk : in std_logic
            );
    end component;

	component bg_merge_prod is
        generic(
                   NO_INPUTS : integer := 1
               );
        port(
            -- Inputs
                in_port : in DATA_PORT(NO_INPUTS-1 downto 0);
                in_req : in DATA_SIGNAL(NO_INPUTS-1 downto 0);
                in_ack : out DATA_SIGNAL(NO_INPUTS-1 downto 0);
            -- Special values
                in_bias : in std_logic_vector(DATA_WIDTH-1 downto 0);
            -- Outputs
                out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
                out_req : out std_logic;
                out_ack : in std_logic;
            -- Other signals
                halt : in std_logic;
                rst : in std_logic;
                clk : in std_logic
            );
    end component;

	component bg_merge_max is
        generic(
                   NO_INPUTS : integer := 1
               );
        port(
            -- Inputs
                in_port : in DATA_PORT(NO_INPUTS-1 downto 0);
                in_req : in DATA_SIGNAL(NO_INPUTS-1 downto 0);
                in_ack : out DATA_SIGNAL(NO_INPUTS-1 downto 0);
            -- Special values
                in_bias : in std_logic_vector(DATA_WIDTH-1 downto 0);
            -- Outputs
                out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
                out_req : out std_logic;
                out_ack : in std_logic;
            -- Other signals
                halt : in std_logic;
                rst : in std_logic;
                clk : in std_logic
            );
    end component;

	component bg_merge_min is
        generic(
                   NO_INPUTS : integer := 1
               );
        port(
            -- Inputs
                in_port : in DATA_PORT(NO_INPUTS-1 downto 0);
                in_req : in DATA_SIGNAL(NO_INPUTS-1 downto 0);
                in_ack : out DATA_SIGNAL(NO_INPUTS-1 downto 0);
            -- Special values
                in_bias : in std_logic_vector(DATA_WIDTH-1 downto 0);
            -- Outputs
                out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
                out_req : out std_logic;
                out_ack : in std_logic;
            -- Other signals
                halt : in std_logic;
                rst : in std_logic;
                clk : in std_logic
            );
    end component;

	component bg_merge_norm is
        generic(
                   NO_INPUTS : integer := 1
               );
        port(
            -- Inputs
                in_port : in DATA_PORT(NO_INPUTS-1 downto 0);
                in_req : in DATA_SIGNAL(NO_INPUTS-1 downto 0);
                in_ack : out DATA_SIGNAL(NO_INPUTS-1 downto 0);
            -- Special values
                in_bias : in std_logic_vector(DATA_WIDTH-1 downto 0);
            -- Outputs
                out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
                out_req : out std_logic;
                out_ack : in std_logic;
            -- Other signals
                halt : in std_logic;
                rst : in std_logic;
                clk : in std_logic
            );
    end component;

    component bg_greater_than_zero is
        port(
        -- Inputs
            in_port : in DATA_PORT(2 downto 0);
            in_req : in DATA_SIGNAL(2 downto 0);
            in_ack : out DATA_SIGNAL(2 downto 0);
        -- Outputs
            out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out_req : out std_logic;
            out_ack : in std_logic;
        -- Other signals
            halt : in std_logic;
            rst : in std_logic;
            clk : in std_logic
            );
    end component;

    component bg_less_than_epsilon is
        port(
        -- Inputs
            in_port : in DATA_PORT(2 downto 0);
            in_req : in DATA_SIGNAL(2 downto 0);
            in_ack : out DATA_SIGNAL(2 downto 0);
        -- Epsilon value
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
    end component;

    component bg_fmod is
        port(
        -- Inputs
            in_port : in DATA_PORT(1 downto 0);
            in_req : in DATA_SIGNAL(1 downto 0);
            in_ack : out DATA_SIGNAL(1 downto 0);
        -- Outputs
            out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out_req : out std_logic;
            out_ack : in std_logic;
        -- Other signals
            halt : in std_logic;
            rst : in std_logic;
            clk : in std_logic
            );
    end component;

end;
