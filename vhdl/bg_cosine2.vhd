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
    type NodeStates is (idle, 
                        new_data, 
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
                        data_out, 
                        sync);
    -- Add signals here
    signal NodeState : NodeStates;

    signal internal_input_req : std_logic;
    signal internal_input_ack : std_logic;
    signal internal_output_req : std_logic;
    signal internal_output_ack : std_logic;

    signal din : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal cosval : std_logic_vector(DATA_WIDTH-1 downto 0);

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

    -- NOTE: we can get rid of add or sub, because negation is easy
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
    process(din)
    begin
        if (unsigned(din(DATA_WIDTH-2 downto 0)) > unsigned(three(DATA_WIDTH-2 downto 0))) then -- greater 3
            quadrant <= "11";
        elsif (unsigned(din(DATA_WIDTH-2 downto 0)) > unsigned(two(DATA_WIDTH-2 downto 0))) then -- greater 2
            quadrant <= "10";
        elsif (unsigned(din(DATA_WIDTH-2 downto 0)) > unsigned(one(DATA_WIDTH-2 downto 0))) then -- greater 1
            quadrant <= "01";
        else
            quadrant <= "00";
        end if;
    end process;

    NodeProcess : process(clk)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                internal_input_ack <= '0';
                internal_output_req <= '0';
                fp_div_start <= '0';
                fp_mul_start <= '0';
                fp_add_start <= '0';
                fp_sub_start <= '0';
                fp_trunc_start <= '0';
                out_port <= (others => '0');
                NodeState <= idle;
            else
                fp_div_start <= '0';
                fp_mul_start <= '0';
                fp_add_start <= '0';
                fp_sub_start <= '0';
                fp_trunc_start <= '0';
                if (halt = '0') then
                    -- defaults
                    case NodeState is
                        when idle =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (internal_input_req = '1') then
                                din <= in_port;
                                internal_input_ack <= '1';
                                NodeState <= new_data;
                            else
                                NodeState <= idle;
                            end if;
                        when new_data =>
                            internal_input_ack <= '1';
                            internal_output_req <= '0';
                            if (internal_input_req = '0') then
                                -- start first calc (|x|*2/pi)
                                fp_mul_opa <= "0" & din(DATA_WIDTH-2 downto 0);
                                fp_mul_opb <= div_pi; -- 2/pi
                                fp_mul_start <= '1';
                                internal_input_ack <= '0';
                                NodeState <= normalize;
                            else
                                NodeState <= new_data;
                            end if;
                        when normalize =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (fp_mul_rdy = '1') then
                                -- start second calc (z/4)
                                fp_div_opa <= fp_mul_result;
                                fp_div_opb <= four; -- 4.0
                                fp_div_start <= '1';
                                din <= fp_mul_result; -- store mul result (needed in normalize 4)
                                NodeState <= normalize1;
                            else
                                NodeState <= normalize;
                            end if;
                        when normalize1 =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (fp_div_rdy = '1') then
                                --start third calc (trunc(z/4))
                                fp_trunc_op <= fp_div_result;
                                fp_trunc_start <= '1';
                                NodeState <= normalize2;
                            else
                                NodeState <= normalize1;
                            end if;
                        when normalize2 =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (fp_trunc_rdy = '1') then
                                --start fourth calc (4 * trunc(z/4))
                                fp_mul_opa <= fp_trunc_result;
                                fp_mul_opb <= four; -- 4.0
                                fp_mul_start <= '1';
                                NodeState <= normalize3;
                            else
                                NodeState <= normalize2;
                            end if;
                        when normalize3 =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (fp_mul_rdy = '1') then
                                --start fifth calc (z - 4 * trunc(z/4))
                                fp_sub_opa <= din;
                                fp_sub_opb <= fp_mul_result;
                                fp_sub_start <= '1';
                                NodeState <= normalize4;
                            else
                                NodeState <= normalize3;
                            end if;
                        when normalize4 =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (fp_sub_rdy = '1') then
                                din <= fp_sub_result; -- store normalized value (now quadrant calc starts)
                                NodeState <= normalize5;
                            else
                                NodeState <= normalize4;
                            end if;
                        when normalize5 =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            NodeState <= normalize6;
                            if (quadrant = 1) then
                                fp_sub_opa <= two;
                                fp_sub_opb <= din;
                                fp_sub_start <= '1';
                            elsif (quadrant = 2) then
                                fp_sub_opa <= din;
                                fp_sub_opb <= two;
                                fp_sub_start <= '1';
                            elsif (quadrant = 3) then
                                fp_sub_opa <= four;
                                fp_sub_opb <= din;
                                fp_sub_start <= '1';
                            else
                                cosval <= din;
                                NodeState <= cosine; -- assumes the correct value in cosval
                            end if;
                        when normalize6 =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (fp_sub_rdy = '1') then
                                cosval <= fp_sub_result;
                                NodeState <= cosine; -- assumes the correct value in cosval
                            else
                                NodeState <= normalize6;
                            end if;

                        when cosine =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            --calculate cosval * cosval
                            fp_mul_opa <= cosval;
                            fp_mul_opb <= cosval;
                            fp_mul_start <= '1';
                            NodeState <= cosine1;

                        when cosine1 =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (fp_mul_rdy = '1') then
                                cosval <= fp_mul_result; -- store z^2
                                -- calculate cos_param1 * z^2
                                fp_mul_opa <= cos_param1;
                                fp_mul_opb <= fp_mul_result;
                                fp_mul_start <= '1';
                                NodeState <= cosine2;
                            else
                                NodeState <= cosine1;
                            end if;
                        when cosine2 =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (fp_mul_rdy = '1') then
                                -- calculate 1 - cos_param1*z^2
                                fp_sub_opa <= one;
                                fp_sub_opb <= fp_mul_result;
                                fp_sub_start <= '1';
                                -- calculate z^4
                                fp_mul_opa <= cosval;
                                fp_mul_opb <= cosval;
                                fp_mul_start <= '1';
                                NodeState <= cosine3;
                            else
                                NodeState <= cosine2;
                            end if;
                        when cosine3 =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (fp_mul_rdy = '1') then -- mul is the slower op, so we just wait on it
                                -- calculate cos_param2 * z^4
                                fp_mul_opa <= cos_param2;
                                fp_mul_opb <= fp_mul_result;
                                fp_mul_start <= '1';
                                NodeState <= cosine4;
                            else
                                NodeState <= cosine3;
                            end if;
                        when cosine4 =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (fp_mul_rdy = '1') then
                                -- calculate 1 - cos_param1*z^2 + cos_param2*z^4
                                fp_add_opa <= fp_sub_result;
                                fp_add_opb <= fp_mul_result;
                                fp_add_start <= '1';
                                NodeState <= cosine5;
                            else
                                NodeState <= cosine4;
                            end if;
                        when cosine5 =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if (fp_add_rdy = '1') then
                                cosval <= fp_add_result;
                                NodeState <= fixsign;
                            else
                                NodeState <= cosine5;
                            end if;
                        when fixsign =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            NodeState <= data_out;
                            if (quadrant = 1 or quadrant = 2) then
                                out_port <= "1"&cosval(DATA_WIDTH-2 downto 0);
                            else
                                out_port <= "0"&cosval(DATA_WIDTH-2 downto 0);
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
