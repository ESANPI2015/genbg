library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
-- Add additional libraries here

entity bg_log is
    port(
    -- Inputs
        in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
        in_req  : in std_logic;
        in_ack  : out std_logic;
    -- Outputs
        out_port : out std_logic_vector(DATA_WIDTH-1 downto 0);
        out_req  : out std_logic;
        out_ack  : in std_logic;
    -- Other signals
        halt : in std_logic;
        rst : in std_logic;
        clk : in std_logic
        );
end bg_log;

architecture Behavioral of bg_log is
    -- Add types here
    type InputStates is (idle, waiting, pushing);
    type ComputeStates is (idle, computing, pushing);
    type OutputStates is (idle, pushing, sync);
    -- Add signals here
    signal InputState : InputStates;
    signal ComputeState0 : ComputeStates;
    signal ComputeState1 : ComputeStates;
    signal OutputState : OutputStates;

    signal internal_input_req : std_logic;
    signal internal_input_ack : std_logic;
    signal internal_output_req : std_logic;
    signal internal_output_ack : std_logic;

    -- FP stuff
    constant log2e_inv : std_logic_vector(DATA_WIDTH-1 downto 0) := x"3f317218"; -- 0.693147f
    signal fp_opa : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_mul_result : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_log2_result : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal fp_mul_start : std_logic;
    signal fp_mul_rdy : std_logic;
    signal fp_log2_start : std_logic;
    signal fp_log2_rdy : std_logic;

    signal fp_in_req : std_logic;
    signal fp_in_ack : std_logic;
    signal fp_out_req0 : std_logic;
    signal fp_out_ack0 : std_logic;
    signal fp_out_req : std_logic;
    signal fp_out_ack : std_logic;

begin
    internal_input_req <= in_req;
    in_ack <= internal_input_ack;
    out_req <= internal_output_req;
    internal_output_ack <= out_ack;

    fp_log2 : entity work.fpu_log2(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_opa,
                    output_o => fp_log2_result,
                    start_i => fp_log2_start,
                    ready_o => fp_log2_rdy
                 );

    fp_mul : entity work.fpu_mul(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_log2_result,
                    opb_i => log2e_inv,
                    rmode_i => "00", -- round to nearest even
                    output_o => fp_mul_result,
                    start_i => fp_mul_start,
                    ready_o => fp_mul_rdy
                 );

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
                internal_input_ack <= '0';
                fp_in_req <= '0';
                InputState <= InputState;
                case InputState is
                    when idle =>
                        if (internal_input_req = '1' and halt = '0') then
                            internal_input_ack <= '1';
                            fp_opa <= in_port;
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

    ComputeProcess0 : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fp_out_req0 <= '0';
                fp_in_ack <= '0';
                fp_log2_start <= '0';
                ComputeState0 <= idle;
            else
                fp_out_req0 <= '0';
                fp_in_ack <= '0';
                fp_log2_start <= '0';
                ComputeState0 <= ComputeState0;
                case ComputeState0 is
                    when idle =>
                        if (fp_in_req = '1') then
                            fp_in_ack <= '1';
                            fp_log2_start <= '1';
                            ComputeState0 <= computing;
                        end if;
                    when computing =>
                        if (fp_log2_rdy = '1') then
                            fp_out_req0 <= '1';
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
                fp_out_req <= '0';
                fp_out_ack0 <= '0';
                fp_mul_start <= '0';
                ComputeState1 <= idle;
            else
                fp_out_req <= '0';
                fp_out_ack0 <= '0';
                fp_mul_start <= '0';
                ComputeState1 <= ComputeState1;
                case ComputeState1 is
                    when idle =>
                        if (fp_out_req0 = '1') then
                            fp_out_ack0 <= '1';
                            fp_mul_start <= '1';
                            ComputeState1 <= computing;
                        end if;
                    when computing =>
                        if (fp_mul_rdy = '1') then
                            fp_out_req <= '1';
                            ComputeState1 <= pushing;
                        end if;
                    when pushing =>
                        fp_out_req <= '1';
                        if (fp_out_ack = '1') then
                            fp_out_req <= '0';
                            ComputeState1 <= idle;
                        end if;
                end case;
            end if;
        end if;
    end process ComputeProcess1;

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
                            fp_out_ack <= '1';
                            out_port <= fp_mul_result;
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
