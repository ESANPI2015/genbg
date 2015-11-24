library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_misc.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
-- Add additional libraries here

entity bg_atan2 is
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
end bg_atan2;

architecture Behavioral of bg_atan2 is

    -- Add types here
    type CalcStates is (
                        idle,
                        choices,
                        divide,
                        atangens,
                        atangens1,
                        atangens2,
                        atangens3,
                        atangens4,
                        atangens5,
                        atangens6,
                        atangens7,
                        fix_outer_interval,
                        waiting,
                        fix_atan,
                        fix_atan2,
                        sync
                    );
    type InputStates is (idle, waiting, pushing);
    type OutputStates is (idle, pushing, sync);

    -- Add signals here
    signal InputState : InputStates;
    signal OutputState : OutputStates;
    signal CalcState : CalcStates;

    signal internal_input_req : std_logic;
    signal internal_input_ack : std_logic;
    signal internal_output_req : std_logic;
    signal internal_output_ack : std_logic;

    signal din1 : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal din2 : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal din : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal dout : std_logic_vector(DATA_WIDTH-1 downto 0);

    -- FP stuff
    constant pi_div_4 : std_logic_vector(DATA_WIDTH-1 downto 0) := x"3f490fdb"; -- 0.785398f
    constant pi_div_2  : std_logic_vector(DATA_WIDTH-1 downto 0) := x"3fc90fdb"; -- 1.570796f
    constant pi : std_logic_vector(DATA_WIDTH-1 downto 0) := x"40490fdb"; -- 3.141593f
    constant one : std_logic_vector(DATA_WIDTH-1 downto 0) := x"3f800000";
    constant atan_param1 : std_logic_vector(DATA_WIDTH-1 downto 0) := x"3e7a92a3"; -- 0.2447f
    constant atan_param2 : std_logic_vector(DATA_WIDTH-1 downto 0) := x"3d87c84b"; -- 0.0663f

    signal fp_div_opa : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_div_opb : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_div_result : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_div_start : std_logic;
    signal fp_div_rdy : std_logic;
    signal fp_mul_opa : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_mul_opb : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_mul_result : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_mul_start : std_logic;
    signal fp_mul_rdy : std_logic;
    signal fp_sub_opa : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_sub_opb : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_sub_result : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_sub_start : std_logic;
    signal fp_sub_rdy : std_logic;
    signal inner_interval : std_logic;
    signal x_less_zero : std_logic;
    signal sgn_y : std_logic;

    signal fp_in_req : std_logic;
    signal fp_in_ack : std_logic;
    signal fp_out_req : std_logic;
    signal fp_out_ack : std_logic;

begin
    fp_div : entity work.fpu_div(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_div_opa,
                    opb_i => fp_div_opb,
                    rmode_i => "00",
                    output_o => fp_div_result,
                    start_i => fp_div_start,
                    ready_o => fp_div_rdy
                 );
    fp_mul : entity work.fpu_mul(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_mul_opa,
                    opb_i => fp_mul_opb,
                    rmode_i => "00", -- round to nearest even
                    output_o => fp_mul_result,
                    start_i => fp_mul_start,
                    ready_o => fp_mul_rdy
                 );

    fp_sub : entity work.fpu_sub(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_sub_opa,
                    opb_i => fp_sub_opb,
                    rmode_i => "00", -- round to nearest even
                    output_o => fp_sub_result,
                    start_i => fp_sub_start,
                    ready_o => fp_sub_rdy
                 );

    internal_input_req <= in_req(0) and in_req(1);
    in_ack(0) <= internal_input_ack;
    in_ack(1) <= internal_input_ack;
    out_req <= internal_output_req;
    internal_output_ack <= out_ack;

    -- get inner interval
    process(dout)
    begin
        if (unsigned(dout(DATA_WIDTH-2 downto 0)) > unsigned(one(DATA_WIDTH-2 downto 0))) then -- |dout| greater 1
            inner_interval <= '0';
        else
            inner_interval <= '1';
        end if;
    end process;

    -- arcus tangens calculation
    process(clk)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                fp_in_ack <= '0';
                fp_out_req <= '0';
                fp_div_start <= '0';
                fp_mul_start <= '0';
                fp_sub_start <= '0';
                dout <= (others => '0');
                x_less_zero <= '0';
                sgn_y <= '0';
                CalcState <= idle;
            else
                -- defaults
                fp_in_ack <= '0';
                fp_out_req <= '0';
                fp_div_start <= '0';
                fp_mul_start <= '0';
                fp_sub_start <= '0';
                CalcState <= CalcState;
                case CalcState is
                    when idle =>
                        if (fp_in_req = '1') then
                            fp_div_opa <= din1; -- Y value
                            fp_div_opb <= din2; -- X value
                            fp_in_ack <= '1';
                            CalcState <= choices;
                        end if;
                    when choices =>
                        CalcState <= divide;
                        sgn_y <= fp_div_opa(DATA_WIDTH-1);
                        if (fp_div_opb(DATA_WIDTH-1) = '0' and or_reduce(fp_div_opb(DATA_WIDTH-2 downto 0)) = '1') then
                            -- X > 0: atan(y/x)
                            x_less_zero <= '0';
                            fp_div_start <= '1';
                        elsif (or_reduce(fp_div_opb(DATA_WIDTH-2 downto 0)) = '1') then
                            -- X < 0: atan(y/x) + sgn(y)*pi
                            x_less_zero <= '1';
                            fp_div_start <= '1';
                        elsif (or_reduce(fp_div_opa(DATA_WIDTH-2 downto 0)) = '1') then
                            -- X == 0, Y /= 0: sgn(y)*pi/2
                            dout <= fp_div_opa(DATA_WIDTH-1) & pi_div_2(DATA_WIDTH-2 downto 0);
                            fp_out_req <= '1';
                            CalcState <= sync;
                        else
                            -- X == 0, Y == 0: 0
                            dout <= (others => '0');
                            fp_out_req <= '1';
                            CalcState <= sync;
                        end if;
                    when divide =>
                        if (fp_div_rdy = '1') then
                            dout <= fp_div_result;
                            CalcState <= atangens;
                        end if;

                    -- NORMAL ATAN
                    when atangens =>
                        -- Decide whether to calc with x or 1/x
                        fp_div_opb <= dout;
                        if (inner_interval = '0') then
                            fp_div_opa <= one;
                            fp_div_start <= '1';
                            CalcState <= atangens1;
                        else
                            CalcState <= atangens2;
                        end if;
                    when atangens1 =>
                        if (fp_div_rdy = '1') then
                            fp_div_opb <= fp_div_result;
                            CalcState <= atangens2;
                        end if;
                    when atangens2 =>
                        -- In fp_div_opb is the potentially modified din value
                        -- Calc: param2 * |x'| and |x'| - 1
                        fp_mul_opa <= atan_param2;
                        fp_mul_opb <= "0" & fp_div_opb(DATA_WIDTH-2 downto 0);
                        fp_sub_opa <= "0" & fp_div_opb(DATA_WIDTH-2 downto 0);
                        fp_sub_opb <= one;
                        fp_mul_start <= '1';
                        fp_sub_start <= '1';
                        CalcState <= atangens3;
                    when atangens3 =>
                        if (fp_mul_rdy = '1') then
                            fp_mul_opa <= fp_sub_result; -- store sub result
                            -- Calc: param1 + param2 * |x'|
                            fp_sub_opa <= atan_param1;
                            fp_sub_opb <= "1" & fp_mul_result(DATA_WIDTH-2 downto 0);
                            fp_sub_start <= '1';
                            CalcState <= atangens4;
                        end if;
                    when atangens4 =>
                        if (fp_sub_rdy = '1') then
                            -- Calc: (|x'| - 1) * (param1 + param2 * |x'|)
                            fp_mul_opb <= fp_sub_result;
                            fp_mul_start <= '1';
                            CalcState <= atangens5;
                        end if;
                    when atangens5 =>
                        if (fp_mul_rdy = '1') then
                            -- Calc: x' * previous
                            fp_mul_opa <= fp_div_opb;
                            fp_mul_opb <= fp_mul_result;
                            fp_mul_start <= '1';
                            CalcState <= atangens6;
                        end if;
                    when atangens6 =>
                        if (fp_mul_rdy = '1') then
                            fp_sub_opb <= fp_mul_result; -- store mul result
                            -- Calc: pi/4 * x'
                            fp_mul_opa <= pi_div_4;
                            fp_mul_opb <= fp_div_opb;
                            fp_mul_start <= '1';
                            CalcState <= atangens7;
                        end if;
                    when atangens7 =>
                        if (fp_mul_rdy = '1') then
                            -- Calc: pi/4 * x' - x'*(|x'|-1)*(param1+param2*|x'|)
                            fp_sub_opa <= fp_mul_result;
                            fp_sub_start <= '1';
                            CalcState <= fix_outer_interval;
                        end if;
                    when fix_outer_interval =>
                        if (fp_sub_rdy = '1') then
                            -- Calc: sgn(x)*pi/2 - previous(x') iff |x| > 1
                            fp_sub_opa <= dout(DATA_WIDTH-1) & pi_div_2(DATA_WIDTH-2 downto 0);
                            fp_sub_opb <= fp_sub_result;
                            CalcState <= waiting;
                            dout <= fp_sub_result;
                            if (inner_interval = '1') then
                                CalcState <= fix_atan;
                            else
                                fp_sub_start <= '1';
                            end if;
                        end if;
                    when waiting =>
                        if (fp_sub_rdy = '1') then
                            dout <= fp_sub_result;
                            CalcState <= fix_atan;
                        end if;
                    -- NORMAL ATAN END

                    when fix_atan =>
                        if (x_less_zero = '1') then
                            fp_sub_opa <= dout;
                            fp_sub_opb <= not sgn_y & pi(DATA_WIDTH-2 downto 0);
                            fp_sub_start <= '1';
                            CalcState <= fix_atan2;
                        else
                            fp_out_req <= '1';
                            CalcState <= sync;
                        end if;
                    when fix_atan2 =>
                        if (fp_sub_rdy = '1') then
                            dout <= fp_sub_result;
                            fp_out_req <= '1';
                            CalcState <= sync;
                        end if;
                    when sync =>
                        fp_out_req <= '1';
                        if (fp_out_ack = '1') then
                            fp_out_req <= '0';
                            CalcState <= idle;
                        end if;
                end case;
            end if;
        end if;
    end process;

    InputProcess : process(clk)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                fp_in_req <= '0';
                din <= (others => '0');
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
                            din1 <= in_port(0);
                            din2 <= in_port(1);
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
                            out_port <= dout;
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
