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
    type NodeStates is (
                        idle, 
                        new_data, 
                        compute,
                        data_out, 
                        sync
                    );
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
                        fixsign
                    );
    -- Add signals here
    signal NodeState : NodeStates;
    signal CalcState : CalcStates;

    signal internal_input_req : std_logic;
    signal internal_input_ack : std_logic;
    signal internal_output_req : std_logic;
    signal internal_output_ack : std_logic;

    signal din : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal dout : std_logic_vector(DATA_WIDTH-1 downto 0);

    -- FP stuff
    constant div_pi : std_logic_vector(DATA_WIDTH-1 downto 0) := x"3f22f983";
    constant one : std_logic_vector(DATA_WIDTH-1 downto 0) := x"3f800000";
    constant two : std_logic_vector(DATA_WIDTH-1 downto 0) := x"40000000";
    constant three : std_logic_vector(DATA_WIDTH-1 downto 0) := x"40400000";
    constant four : std_logic_vector(DATA_WIDTH-1 downto 0) := x"40800000";
    constant cos_param2 : std_logic_vector(DATA_WIDTH-1 downto 0) := x"3e66c299";
    constant cos_param1 : std_logic_vector(DATA_WIDTH-1 downto 0) := x"3f9cd853";

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
    signal fp_add_opa : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_add_opb : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_add_result : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_add_start : std_logic;
    signal fp_add_rdy : std_logic;
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

    signal fp_finished : std_logic;
    signal fp_start : std_logic;

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

    -- NOTE: we can get rid of add or sub, because negation is easy, instead we could use an additional MUL :D
    fp_add : entity work.fpu_add(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_add_opa,
                    opb_i => fp_add_opb,
                    rmode_i => "00", -- round to nearest even
                    output_o => fp_add_result,
                    start_i => fp_add_start,
                    ready_o => fp_add_rdy
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
                fp_finished <= '0';
                fp_div_start <= '0';
                fp_mul_start <= '0';
                fp_add_start <= '0';
                fp_sub_start <= '0';
                fp_trunc_start <= '0';
                dout <= (others => '0');
                CalcState <= idle;
            else
                -- defaults
                fp_div_start <= '0';
                fp_mul_start <= '0';
                fp_add_start <= '0';
                fp_sub_start <= '0';
                fp_trunc_start <= '0';
                fp_finished <= '0';
                case CalcState is
                    when idle =>
                        fp_finished <= '1';
                        if (fp_start = '1') then
                            -- start first calc (|x|*2/pi)
                            fp_mul_opa <= "0" & din(DATA_WIDTH-2 downto 0);
                            fp_mul_opb <= div_pi; -- 2/pi
                            fp_mul_start <= '1';
                            fp_finished <= '0';
                            CalcState <= normalize;
                        else
                            CalcState <= idle;
                        end if;
                    when normalize =>
                        if (fp_mul_rdy = '1') then
                            -- start second calc (z/4)
                            fp_div_opa <= fp_mul_result;
                            fp_div_opb <= four; -- 4.0
                            fp_div_start <= '1';
                            dout <= fp_mul_result; -- store mul result (needed in normalize 4)
                            CalcState <= normalize1;
                        else
                            CalcState <= normalize;
                        end if;
                    when normalize1 =>
                        if (fp_div_rdy = '1') then
                            --start third calc (trunc(z/4))
                            fp_trunc_op <= fp_div_result;
                            fp_trunc_start <= '1';
                            CalcState <= normalize2;
                        else
                            CalcState <= normalize1;
                        end if;
                    when normalize2 =>
                        if (fp_trunc_rdy = '1') then
                            --start fourth calc (4 * trunc(z/4))
                            fp_mul_opa <= fp_trunc_result;
                            fp_mul_opb <= four; -- 4.0
                            fp_mul_start <= '1';
                            CalcState <= normalize3;
                        else
                            CalcState <= normalize2;
                        end if;
                    when normalize3 =>
                        if (fp_mul_rdy = '1') then
                            --start fifth calc (z - 4 * trunc(z/4))
                            fp_sub_opa <= dout;
                            fp_sub_opb <= fp_mul_result;
                            fp_sub_start <= '1';
                            CalcState <= normalize4;
                        else
                            CalcState <= normalize3;
                        end if;
                    when normalize4 =>
                        if (fp_sub_rdy = '1') then
                            dout <= fp_sub_result; -- store normalized value (now quadrant calc starts)
                            CalcState <= normalize5;
                        else
                            CalcState <= normalize4;
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
                        else
                            CalcState <= normalize6;
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
                            -- calculate cos_param1 * z^2
                            fp_mul_opa <= cos_param1;
                            fp_mul_opb <= fp_mul_result;
                            fp_mul_start <= '1';
                            CalcState <= cosine2;
                        else
                            CalcState <= cosine1;
                        end if;
                    when cosine2 =>
                        if (fp_mul_rdy = '1') then
                            -- calculate 1 - cos_param1*z^2
                            fp_sub_opa <= one;
                            fp_sub_opb <= fp_mul_result;
                            fp_sub_start <= '1';
                            -- calculate z^4
                            fp_mul_opa <= fp_trunc_op;
                            fp_mul_opb <= fp_trunc_op;
                            fp_mul_start <= '1';
                            CalcState <= cosine3;
                        else
                            CalcState <= cosine2;
                        end if;
                    when cosine3 =>
                        if (fp_mul_rdy = '1') then -- mul is the slower op, so we just wait on it
                            -- calculate cos_param2 * z^4
                            fp_mul_opa <= cos_param2;
                            fp_mul_opb <= fp_mul_result;
                            fp_mul_start <= '1';
                            CalcState <= cosine4;
                        else
                            CalcState <= cosine3;
                        end if;
                    when cosine4 =>
                        if (fp_mul_rdy = '1') then
                            -- calculate 1 - cos_param1*z^2 + cos_param2*z^4
                            fp_add_opa <= fp_sub_result;
                            fp_add_opb <= fp_mul_result;
                            fp_add_start <= '1';
                            CalcState <= cosine5;
                        else
                            CalcState <= cosine4;
                        end if;
                    when cosine5 =>
                        if (fp_add_rdy = '1') then
                            fp_trunc_op <= fp_add_result;
                            CalcState <= fixsign;
                        else
                            CalcState <= cosine5;
                        end if;
                    when fixsign =>
                        fp_finished <= '1';
                        CalcState <= idle;
                        if (quadrant = 1 or quadrant = 2) then
                            dout <= "1"&fp_trunc_op(DATA_WIDTH-2 downto 0);
                        else
                            dout <= "0"&fp_trunc_op(DATA_WIDTH-2 downto 0);
                        end if;
                end case;
            end if;
        end if;
    end process;

    NodeProcess : process(clk)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                internal_input_ack <= '0';
                internal_output_req <= '0';
                out_port <= (others => '0');
                NodeState <= idle;
            else
                if (halt = '0') then
                    -- defaults
                    case NodeState is
                        when idle =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (internal_input_req = '1' and fp_finished='1') then
                                din <= in_port;
                                fp_start <= '1';
                                internal_input_ack <= '1';
                                NodeState <= new_data;
                            else
                                NodeState <= idle;
                            end if;
                        when new_data =>
                            internal_input_ack <= '1';
                            internal_output_req <= '0';
                            if (internal_input_req = '0') then
                                internal_input_ack <= '0';
                                NodeState <= compute;
                            else
                                NodeState <= new_data;
                            end if;
                        when compute =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (fp_finished = '1') then
                                out_port <= dout;
                                NodeState <= data_out;
                            else
                                NodeState <= compute;
                            end if;
                        when data_out =>
                            internal_input_ack <= '0';
                            internal_output_req <= '1';
                            if (internal_output_ack = '1') then
                                internal_output_req <= '0';
                                NodeState <= sync;
                            else
                                NodeState <= data_out;
                            end if;
                        when sync =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (internal_output_ack = '0') then
                                NodeState <= idle;
                            else
                                NodeState <= sync;
                            end if;
                    end case;
                end if;
            end if;
        end if;
    end process NodeProcess;

end Behavioral;
