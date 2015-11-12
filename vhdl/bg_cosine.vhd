library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
-- Add additional libraries here

entity bg_cosine is
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
end bg_cosine;

architecture Behavioral of bg_cosine is

    -- Add types here
    type CalcStates is (
                        idle,
                        normalize,
                        normalize1,
                        normalize2,
                        normalize3,
                        normalize4,
                        normalize5,
                        normalize6,
                        cosine,
                        cosine1,
                        cosine2,
                        cosine3,
                        cosine4,
                        cosine5,
                        fixsign,
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

    signal din : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal dout : std_logic_vector(DATA_WIDTH-1 downto 0);

    -- FP stuff
    constant div_pi : std_logic_vector(DATA_WIDTH-1 downto 0) := x"3f22f983"; -- 0.636620f
    constant one : std_logic_vector(DATA_WIDTH-1 downto 0) := x"3f800000";
    constant two : std_logic_vector(DATA_WIDTH-1 downto 0) := x"40000000";
    constant three : std_logic_vector(DATA_WIDTH-1 downto 0) := x"40400000";
    constant four : std_logic_vector(DATA_WIDTH-1 downto 0) := x"40800000";
    constant cos_param2 : std_logic_vector(DATA_WIDTH-1 downto 0) := x"3e66c299"; -- 0.225352f
    constant cos_param1 : std_logic_vector(DATA_WIDTH-1 downto 0) := x"3f9cd853"; -- 1.225352f

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
    signal fp_trunc_op : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_trunc_result : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_trunc_start : std_logic;
    signal fp_trunc_rdy : std_logic;
    signal quadrant : unsigned(1 downto 0);

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
    fp_trunc : entity work.fpu_trunc(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_trunc_op,
                    output_o => fp_trunc_result,
                    start_i => fp_trunc_start,
                    ready_o => fp_trunc_rdy
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

    internal_input_req <= in_req;
    in_ack <= internal_input_ack;
    out_req <= internal_output_req;
    internal_output_ack <= out_ack;

    -- get quadrant
    process(dout)
    begin
        if (unsigned(dout(DATA_WIDTH-2 downto 0)) > unsigned(three(DATA_WIDTH-2 downto 0))) then -- greater 3
            quadrant <= "11";
        elsif (unsigned(dout(DATA_WIDTH-2 downto 0)) > unsigned(two(DATA_WIDTH-2 downto 0))) then -- greater 2
            quadrant <= "10";
        elsif (unsigned(dout(DATA_WIDTH-2 downto 0)) > unsigned(one(DATA_WIDTH-2 downto 0))) then -- greater 1
            quadrant <= "01";
        else
            quadrant <= "00";
        end if;
    end process;

    -- cosine calculation
    process(clk)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                fp_in_ack <= '0';
                fp_out_req <= '0';
                fp_div_start <= '0';
                fp_mul_start <= '0';
                fp_sub_start <= '0';
                fp_trunc_start <= '0';
                dout <= (others => '0');
                CalcState <= idle;
            else
                -- defaults
                fp_in_ack <= '0';
                fp_out_req <= '0';
                fp_div_start <= '0';
                fp_mul_start <= '0';
                fp_sub_start <= '0';
                fp_trunc_start <= '0';
                CalcState <= CalcState;
                case CalcState is
                    when idle =>
                        if (fp_in_req = '1') then
                            -- start first calc (x*2/pi)
                            fp_mul_opa <= din;
                            fp_mul_opb <= div_pi; -- 2/pi
                            fp_mul_start <= '1';
                            fp_in_ack <= '1';
                            CalcState <= normalize;
                        end if;
                    when normalize =>
                        if (fp_mul_rdy = '1') then
                            -- start second calc (z/4)
                            fp_div_opa <= "0" & fp_mul_result(DATA_WIDTH-2 downto 0); -- abs value
                            fp_div_opb <= four; -- 4.0
                            fp_div_start <= '1';
                            dout <= "0" & fp_mul_result(DATA_WIDTH-2 downto 0); -- store abs value (needed in normalize 5)
                            CalcState <= normalize1;
                        end if;
                    when normalize1 =>
                        if (fp_div_rdy = '1') then
                            --start third calc (trunc(z/4))
                            fp_trunc_op <= fp_div_result;
                            fp_trunc_start <= '1';
                            CalcState <= normalize2;
                        end if;
                    when normalize2 =>
                        if (fp_trunc_rdy = '1') then
                            --start fourth calc (4 * trunc(z/4))
                            fp_mul_opa <= fp_trunc_result;
                            fp_mul_opb <= four; -- 4.0
                            fp_mul_start <= '1';
                            CalcState <= normalize3;
                        end if;
                    when normalize3 =>
                        if (fp_mul_rdy = '1') then
                            --start fifth calc (z - 4 * trunc(z/4))
                            fp_sub_opa <= dout;
                            fp_sub_opb <= fp_mul_result;
                            fp_sub_start <= '1';
                            CalcState <= normalize4;
                        end if;
                    when normalize4 =>
                        if (fp_sub_rdy = '1') then
                            dout <= fp_sub_result; -- store normalized value (now quadrant calc starts)
                            CalcState <= normalize5;
                        end if;
                    when normalize5 =>
                        CalcState <= normalize6;
                        if (quadrant = 1) then
                            fp_sub_opa <= two;
                            fp_sub_opb <= dout;
                            fp_sub_start <= '1';
                        elsif (quadrant = 2) then
                            fp_sub_opa <= dout;
                            fp_sub_opb <= two;
                            fp_sub_start <= '1';
                        elsif (quadrant = 3) then
                            fp_sub_opa <= four;
                            fp_sub_opb <= dout;
                            fp_sub_start <= '1';
                        else
                            fp_trunc_op <= dout;
                            CalcState <= cosine; -- assumes the correct value in fp_trunc_op
                        end if;

                    when normalize6 =>
                        if (fp_sub_rdy = '1') then
                            fp_trunc_op <= fp_sub_result;
                            CalcState <= cosine; -- assumes the correct value in fp_trunc_op
                        end if;

                    when cosine =>
                        --calculate fp_trunc_op * fp_trunc_op
                        fp_mul_opa <= fp_trunc_op;
                        fp_mul_opb <= fp_trunc_op;
                        fp_mul_start <= '1';
                        CalcState <= cosine1;

                    when cosine1 =>
                        if (fp_mul_rdy = '1') then
                            fp_trunc_op <= fp_mul_result; -- store z^2
                            -- calculate cos_param2 * z^2
                            fp_mul_opa <= cos_param2;
                            fp_mul_opb <= fp_mul_result;
                            fp_mul_start <= '1';
                            CalcState <= cosine2;
                        end if;
                    when cosine2 =>
                        if (fp_mul_rdy = '1') then
                            -- calculate cos_param1 - cos_param2*z^2
                            fp_sub_opa <= cos_param1;
                            fp_sub_opb <= fp_mul_result;
                            fp_sub_start <= '1';
                            CalcState <= cosine3;
                        end if;
                    when cosine3 =>
                        if (fp_sub_rdy = '1') then
                            -- calculate z^2*(cos_param1 - cos_param2*z^2)
                            fp_mul_opa <= fp_trunc_op;
                            fp_mul_opb <= fp_sub_result;
                            fp_mul_start <= '1';
                            CalcState <= cosine4;
                        end if;
                    when cosine4 =>
                        if (fp_mul_rdy = '1') then
                            -- calculate 1 - z^2(cos_param1 - cos_param2*z^2)
                            fp_sub_opa <= one;
                            fp_sub_opb <= fp_mul_result;
                            fp_sub_start <= '1';
                            CalcState <= cosine5;
                        end if;
                    when cosine5 =>
                        if (fp_sub_rdy = '1') then
                            fp_trunc_op <= fp_sub_result;
                            CalcState <= fixsign;
                        end if;
                    when fixsign =>
                        fp_out_req <= '1';
                        CalcState <= sync;
                        if (quadrant = 1 or quadrant = 2) then
                            dout <= "1"&fp_trunc_op(DATA_WIDTH-2 downto 0);
                        else
                            dout <= "0"&fp_trunc_op(DATA_WIDTH-2 downto 0);
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
                            din <= in_port;
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
