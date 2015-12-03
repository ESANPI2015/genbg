library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
-- Add additional libraries here

entity bg_edge is
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
end bg_edge;

architecture Behavioral of bg_edge is
    -- Add types here
    type InputStates is (idle, waiting, pushing);
    type OutputStates is (idle, waiting, pushing, sync);
    -- Add signals here
    signal InputState : InputStates;
    signal OutputState : OutputStates;
    signal InitialState : OutputStates;

    signal internal_input_req : std_logic;
    signal internal_input_ack : std_logic;
    signal internal_output_req : std_logic;
    signal internal_output_ack : std_logic;

    -- FP stuff
    signal fp_opb : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_in_req : std_logic;
    signal fp_in_ack : std_logic;
    signal fp_start : std_logic;
    signal fp_rdy : std_logic;
    signal fp_result : std_logic_vector(DATA_WIDTH-1 downto 0);
begin

    GEN_BACK_EDGE : if (IS_BACKEDGE = true) generate
            InitialState <= pushing;
        end generate;

    GEN_NORMAL_EDGE : if (IS_BACKEDGE = false) generate
            InitialState <= idle;
        end generate;

    -- Instantiate floating point multiplier here
    -- NOTE: if the weight is 1.0, we should replace an edge with a pipe!
    fp_mul : entity work.fpu_mul(rtl)
    port map (
                clk_i => clk,
                opa_i => in_weight,
                opb_i => fp_opb,
                rmode_i => "00", -- round to nearest even
                output_o => fp_result,
                start_i => fp_start,
                ready_o => fp_rdy
             );

    internal_input_req <= in_req;
    in_ack <= internal_input_ack;
    out_req <= internal_output_req;
    internal_output_ack <= out_ack;

    InputProcess : process(clk)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                fp_in_req <= '0';
                fp_opb <= (others => '0');
                internal_input_ack <= '0';
                InputState <= idle;
            else
                internal_input_ack <= '0';
                fp_in_req <= '0';
                InputState <= InputState;
                case InputState is
                    when idle =>
                        if (internal_input_req = '1' and halt = '0') then
                            internal_input_ack <= '1';
                            fp_opb <= in_port;
                            InputState <= waiting;
                        end if;
                    when waiting =>
                        internal_input_ack <= '1';
                        if (internal_input_req = '0') then
                            internal_input_ack <= '0';
                            fp_in_req <= '1';
                            InputState <= pushing;
                        end if;
                    when pushing =>
                        fp_in_req <= '1';
                        if (fp_in_ack = '1') then
                            fp_in_req <= '0';
                            InputState <= idle;
                        end if;
                end case;
            end if;
        end if;
    end process InputProcess;

    OutputProcess : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fp_in_ack <= '0';
                fp_start <= '0';
                internal_output_req <= '0';
                out_port <= (others => '0');
                OutputState <= idle;
            else
                fp_in_ack <= '0';
                fp_start <= '0';
                internal_output_req <= '0';
                OutputState <= OutputState;
                case OutputState is
                    when idle =>
                        if (fp_in_req = '1') then
                            fp_in_ack <= '1';
                            fp_start <= '1';
                            OutputState <= waiting;
                        end if;
                    when waiting =>
                        out_port <= fp_result;
                        if (fp_rdy = '1') then
                            OutputState <= pushing;
                        end if;
                    when pushing =>
                        internal_output_req <= '1';
                        if (internal_output_ack = '1') then
                            internal_output_req <= '0';
                            OutputState <= sync;
                        end if;
                    when sync =>
                        if (internal_output_ack = '0') then
                            OutputState <= idle;
                        end if;
                end case;
            end if;
        end if;
    end process OutputProcess;
end Behavioral;
