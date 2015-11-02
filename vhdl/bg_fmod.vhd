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
    type NodeStates is (idle, new_data, compute, data_out, sync);
    -- Add signals here
    signal NodeState : NodeStates;

    signal internal_input_req : std_logic;
    signal internal_input_ack : std_logic;
    signal internal_output_req : std_logic;
    signal internal_output_ack : std_logic;

    -- FP stuff
    signal fp_opa : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_opb : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_div_to_mul : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_mul_to_sub : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_result : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal fp_start : std_logic;
    signal fp_start_div_to_mul : std_logic;
    signal fp_start_mul_to_sub : std_logic;
    signal fp_rdy : std_logic;
    signal fp_finished : std_logic; -- this is a flipflopped version

begin
    internal_input_req <= in_req(0) and in_req(1);
    in_ack <= (others => internal_input_ack);
    out_req <= internal_output_req;
    internal_output_ack <= out_ack;

    fp_opa <= in_port(0);
    fp_opb <= in_port(1);

    -- The following stages calculate f = x - y * round_to_zero(x/y)
    -- This is the behaviour of fmodf
    fp_div : entity work.fpu_div(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_opa,
                    opb_i => fp_opb,
                    rmode_i => "01", -- round to ZERO !
                    output_o => fp_div_to_mul,
                    start_i => fp_start,
                    ready_o => fp_start_div_to_mul,
                    ine_o => open,
                    overflow_o => open,
                    underflow_o => open,
                    div_zero_o => open,
                    inf_o => open,
                    zero_o => open,
                    qnan_o => open,
                    snan_o => open
                 );

    fp_mul : entity work.fpu_mul(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_start_div_to_mul,
                    opb_i => fp_opb,
                    rmode_i => "00", -- round to nearest even
                    output_o => fp_mul_to_sub,
                    start_i => fp_start_div_to_mul,
                    ready_o => fp_start_mul_to_sub,
                    ine_o => open,
                    overflow_o => open,
                    underflow_o => open,
                    div_zero_o => open,
                    inf_o => open,
                    zero_o => open,
                    qnan_o => open,
                    snan_o => open
                 );

    fp_sub : entity work.fpu_sub(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_opa,
                    opb_i => fp_mul_to_sub,
                    rmode_i => "00", -- round to nearest even
                    output_o => fp_result,
                    start_i => fp_start_mul_to_sub,
                    ready_o => fp_rdy,
                    ine_o => open,
                    overflow_o => open,
                    underflow_o => open,
                    div_zero_o => open,
                    inf_o => open,
                    zero_o => open,
                    qnan_o => open,
                    snan_o => open
                 );

        -- Process to detect if the fp stage has raised fp_rdy since last fp_start signal
        process(clk)
        begin
            if rising_edge(clk) then
                if rst = '1' then
                    fp_finished <= '1';
                else
                    if (fp_start = '1') then
                        fp_finished <= '0';
                    elsif (fp_rdy = '1') then
                        fp_finished <= '1';
                    end if;
                end if;
            end if;
        end process;

    -- Add processes here
    NodeProcess : process(clk)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                internal_input_ack <= '0';
                internal_output_req <= '0';
                fp_start <= '0';
                out_port <= (others => '0');
                NodeState <= idle;
            else
                fp_start <= '0';
                if (halt = '0') then
                    -- defaults
                    case NodeState is
                        when idle =>
                            internal_input_ack <= '0';
                            internal_output_req <= '0';
                            if ((internal_input_req = '1') and (fp_finished = '1')) then
                                internal_input_ack <= '1';
                                fp_start <= '1';
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
                                out_port <= fp_result;
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
