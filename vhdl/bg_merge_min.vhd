library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
-- Add additional libraries here

entity bg_merge_min is
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
end bg_merge_min;

architecture Behavioral of bg_merge_min is
    -- Add types here
    type InputStates is (idle, waiting, pushing);
    type CalcStates is (idle, computing, pushing);
    type OutputStates is (idle, pushing, sync);

    -- Add signals here
    signal InputState : InputStates;
    signal CalcState : CalcStates;
    signal OutputState : OutputStates;

    signal internal_output_req : std_logic;
    signal internal_output_ack : std_logic;

    signal currInput : integer range 0 to NO_INPUTS-1;

    -- FP stuff
    signal fp_opa : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_acc : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_result : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_start : std_logic;
    signal fp_rdy : std_logic;
    signal fp_accumulate : std_logic_vector(1 downto 0);
    signal fp_lesser : std_logic;

    signal fp_in_req : std_logic;
    signal fp_in_ack : std_logic;
    signal fp_out_req : std_logic;
    signal fp_out_ack : std_logic;
begin
    out_req <= internal_output_req;
    internal_output_ack <= out_ack;

    assert (NO_INPUTS > 0)
    report "bg_merge_min: need one input at least. Use bg_source instead."
    severity failure;

    GENERATE_FULL_MERGE : if (NO_INPUTS>0) generate
        fp_cmp : entity work.fpu_cmp(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_opa,
                    opb_i => fp_acc,
                    less_than_o => fp_lesser,
                    greater_than_o => open,
                    start_i => fp_start,
                    ready_o => fp_rdy
                 );

        InputProcess : process(clk)
        begin
            if clk'event and clk = '1' then
                if rst = '1' then
                    fp_in_req <= '0';
                    currInput <= 0;
                    fp_opa <= (others => '0');
                    fp_accumulate <= "00";
                    in_ack <= (others => '0');
                    InputState <= idle;
                else
                    fp_in_req <= '0';
                    in_ack(currInput) <= '0';
                    InputState <= InputState;
                    case InputState is
                        when idle =>
                            if (in_req(currInput) = '1' and halt = '0') then
                                -- pass incoming data to opa
                                fp_opa <= in_port(currInput);
                                in_ack(currInput) <= '1';
                                InputState <= waiting;
                            end if;
                        when waiting =>
                            in_ack(currInput) <= '1';
                            if (in_req(currInput) = '0') then
                                in_ack(currInput) <= '0';
                                if (currInput = 0) then
                                    -- when we have the first value, we should reset the accumulator to in_bias
                                    fp_accumulate <= "00";
                                elsif (currInput = NO_INPUTS-1) then
                                    -- when we have the last value, the accumulator signals the output process after accumulation
                                    fp_accumulate <= "10";
                                else
                                    -- otherwise we just accumulate
                                    fp_accumulate <= "01";
                                end if;
                                fp_in_req <= '1';
                                InputState <= pushing;
                            end if;
                        when pushing =>
                            fp_in_req <= '1';
                            if (fp_in_ack = '1') then
                                fp_in_req <= '0';
                                if (currInput < NO_INPUTS-1) then
                                    -- we still have inputs to process
                                    currInput <= currInput + 1;
                                else
                                    -- we have no more inputs to process, so we signal the OutputProcess
                                    currInput <= 0;
                                end if;
                                InputState <= idle;
                            end if;
                    end case;
                end if;
            end if;
        end process InputProcess;

        AccumulatorProcess : process (clk)
            variable accumulate : std_logic_vector(1 downto 0);
        begin
            if rising_edge(clk) then
                if rst = '1' then
                    fp_out_req <= '0';
                    fp_start <= '0';
                    fp_in_ack <= '0';
                    fp_acc <= in_bias;
                    fp_result <= in_bias;
                    accumulate := "00";
                    CalcState <= idle;
                else
                    fp_out_req <= '0';
                    fp_start <= '0';
                    fp_in_ack <= '0';
                    CalcState <= CalcState;
                    case CalcState is
                        when idle =>
                            if (fp_in_req = '1') then
                                fp_in_ack <= '1';
                                accumulate := fp_accumulate; -- we have to sample accumulate because InputProcess can change it!
                                if (accumulate = "00") then
                                    fp_acc <= in_bias;   -- set accumulator to initial value
                                else
                                    fp_acc <= fp_result;
                                end if;
                                fp_result <= fp_opa;     -- store opa to protect it from overwriting by InputProcess
                                fp_start <= '1';
                                CalcState <= computing;
                            end if;
                        when computing =>
                            if (fp_rdy = '1') then
                                CalcState <= idle;
                                if (fp_lesser = '0') then
                                    fp_result <= fp_acc; -- fp_result is fp_opa, if opa is NOT lesser than fp_acc, overwrite
                                end if;
                                if (accumulate = "10") then
                                    fp_out_req <= '1';
                                    CalcState <= pushing;
                                end if;
                            end if;
                        when pushing =>
                            fp_out_req <= '1';
                            if (fp_out_ack = '1') then
                                fp_out_req <= '0';
                                CalcState <= idle;
                            end if;
                    end case;
                end if;
            end if;
        end process AccumulatorProcess;

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
    end generate;

end Behavioral;
