library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_misc.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
use work.fpupack.all;
-- Add additional libraries here

entity bg_fmod is
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
end bg_fmod;

architecture Behavioral of bg_fmod is
    -- Add types here
    type InputStates is (idle, waiting, pushing);
    type ComputeStates is (idle, computing, pushing);
    type OutputStates is (idle, pushing, sync);
    -- Add signals here
    signal InputState : InputStates;
    signal ComputeState0 : ComputeStates;
    signal ComputeState1 : ComputeStates;
    signal ComputeState2 : ComputeStates;
    signal ComputeState3 : ComputeStates;
    signal OutputState : OutputStates;

    signal internal_input_req : std_logic;
    signal internal_input_ack : std_logic;
    signal internal_output_req : std_logic;
    signal internal_output_ack : std_logic;

    -- FP stuff
    signal fp_opa  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_opa1 : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_opa2 : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_opa3 : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_opb  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_opb1 : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_opb2 : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_div_to_trunc : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_trunc_to_mul : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_mul_to_sub : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_result : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal fp_div_start : std_logic;
    signal fp_div_rdy   : std_logic;
    signal fp_trunc_start : std_logic;
    signal fp_trunc_rdy   : std_logic;
    signal fp_mul_start : std_logic;
    signal fp_mul_rdy   : std_logic;
    signal fp_sub_start : std_logic;
    signal fp_sub_rdy   : std_logic;

    signal fp_in_req : std_logic;
    signal fp_in_ack : std_logic;
    signal fp_out_req0 : std_logic;
    signal fp_out_ack0 : std_logic;
    signal fp_out_req1 : std_logic;
    signal fp_out_ack1 : std_logic;
    signal fp_out_req2 : std_logic;
    signal fp_out_ack2 : std_logic;
    signal fp_out_req : std_logic;
    signal fp_out_ack : std_logic;

begin
    internal_input_req <= in_req(0) and in_req(1);
    in_ack <= (others => internal_input_ack);
    out_req <= internal_output_req;
    internal_output_ack <= out_ack;

    -- The following stages calculate f = x - y * round_to_zero(x/y)
    -- This is the behaviour of fmodf
    fp_div : entity work.fpu_div(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_opa,
                    opb_i => fp_opb,
                    rmode_i => "00",
                    output_o => fp_div_to_trunc,
                    start_i => fp_div_start,
                    ready_o => fp_div_rdy
                 );
    fp_trunc : entity work.fpu_trunc(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_div_to_trunc,
                    output_o => fp_trunc_to_mul,
                    start_i => fp_trunc_start,
                    ready_o => fp_trunc_rdy
                 );

    fp_mul : entity work.fpu_mul(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_trunc_to_mul,
                    opb_i => fp_opb2,
                    rmode_i => "00", -- round to nearest even
                    output_o => fp_mul_to_sub,
                    start_i => fp_mul_start,
                    ready_o => fp_mul_rdy
                 );

    fp_sub : entity work.fpu_sub(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_opa3,
                    opb_i => fp_mul_to_sub,
                    rmode_i => "00", -- round to nearest even
                    output_o => fp_result,
                    start_i => fp_sub_start,
                    ready_o => fp_sub_rdy
                 );

    ComputeProcess0 : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fp_out_req0 <= '0';
                fp_in_ack <= '0';
                fp_div_start <= '0';
                ComputeState0 <= idle;
            else
                fp_in_ack <= '0';
                fp_div_start <= '0';
                ComputeState0 <= ComputeState0;
                case ComputeState0 is
                    when idle =>
                        fp_out_req0 <= '0';
                        if (fp_in_req = '1') then
                            fp_in_ack <= '1';
                            fp_div_start <= '1';
                            ComputeState0 <= computing;
                        end if;
                    when computing =>
                        fp_out_req0 <= '0';
                        if (fp_div_rdy = '1') then
                            fp_out_req0 <= '1';
                            fp_opa1 <= fp_opa;
                            fp_opb1 <= fp_opb;
                            ComputeState0 <= pushing;
                        end if;
                    when pushing =>
                        fp_out_req0 <= '1';
                        if (fp_out_ack0 = '1') then
                            fp_out_req0 <= '0';
                            ComputeState0 <= idle;
                        end if;
                end case;
            end if;
        end if;
    end process ComputeProcess0;

    ComputeProcess1 : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fp_out_req1 <= '0';
                fp_out_ack0 <= '0';
                fp_trunc_start <= '0';
                ComputeState1 <= idle;
            else
                fp_out_ack0 <= '0';
                fp_trunc_start <= '0';
                ComputeState1 <= ComputeState1;
                case ComputeState1 is
                    when idle =>
                        fp_out_req1 <= '0';
                        if (fp_out_req0 = '1') then
                            fp_out_ack0 <= '1';
                            fp_trunc_start <= '1';
                            ComputeState1 <= computing;
                        end if;
                    when computing =>
                        fp_out_req1 <= '0';
                        if (fp_trunc_rdy = '1') then
                            fp_out_req1 <= '1';
                            fp_opa2 <= fp_opa1;
                            fp_opb2 <= fp_opb1;
                            ComputeState1 <= pushing;
                        end if;
                    when pushing =>
                        fp_out_req1 <= '1';
                        if (fp_out_ack1 = '1') then
                            fp_out_req1 <= '0';
                            ComputeState1 <= idle;
                        end if;
                end case;
            end if;
        end if;
    end process ComputeProcess1;

    ComputeProcess2 : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fp_out_req2 <= '0';
                fp_out_ack1 <= '0';
                fp_mul_start <= '0';
                ComputeState2 <= idle;
            else
                fp_out_ack1 <= '0';
                fp_mul_start <= '0';
                ComputeState2 <= ComputeState2;
                case ComputeState2 is
                    when idle =>
                        fp_out_req2 <= '0';
                        if (fp_out_req1 = '1') then
                            fp_out_ack1 <= '1';
                            fp_mul_start <= '1';
                            ComputeState2 <= computing;
                        end if;
                    when computing =>
                        fp_out_req2 <= '0';
                        if (fp_mul_rdy = '1') then
                            fp_out_req2 <= '1';
                            fp_opa3 <= fp_opa2;
                            ComputeState2 <= pushing;
                        end if;
                    when pushing =>
                        fp_out_req2 <= '1';
                        if (fp_out_ack2 = '1') then
                            fp_out_req2 <= '0';
                            ComputeState2 <= idle;
                        end if;
                end case;
            end if;
        end if;
    end process ComputeProcess2;

    ComputeProcess3 : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fp_out_req <= '0';
                fp_out_ack2 <= '0';
                fp_sub_start <= '0';
                ComputeState3 <= idle;
            else
                fp_out_ack2 <= '0';
                fp_sub_start <= '0';
                ComputeState3 <= ComputeState3;
                case ComputeState3 is
                    when idle =>
                        fp_out_req <= '0';
                        if (fp_out_req2 = '1') then
                            fp_out_ack2 <= '1';
                            fp_sub_start <= '1';
                            ComputeState3 <= computing;
                        end if;
                    when computing =>
                        fp_out_req <= '0';
                        if (fp_sub_rdy = '1') then
                            fp_out_req <= '1';
                            ComputeState3 <= pushing;
                        end if;
                    when pushing =>
                        fp_out_req <= '1';
                        if (fp_out_ack = '1') then
                            fp_out_req <= '0';
                            ComputeState3 <= idle;
                        end if;
                end case;
            end if;
        end if;
    end process ComputeProcess3;

    InputProcess : process(clk)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                fp_in_req <= '0';
                fp_opa <= (others => '0');
                fp_opb <= (others => '0');
                internal_input_ack <= '0';
                InputState <= idle;
            else
                InputState <= InputState;
                internal_input_ack <= '0';
                fp_in_req <= '0';
                case InputState is
                    when idle =>
                        if (internal_input_req = '1' and halt = '0') then
                            internal_input_ack <= '1';
                            fp_opa <= in_port(0);
                            fp_opb <= in_port(1);
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
                fp_out_ack <= '0';
                internal_output_req <= '0';
                out_port <= (others => '0');
                OutputState <= idle;
            else
                fp_out_ack <= '0';
                internal_output_req <= '0';
                OutputState <= OutputState;
                case OutputState is
                    when idle =>
                        if (fp_out_req = '1') then
                            out_port <= fp_result;
                            fp_out_ack <= '1';
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
