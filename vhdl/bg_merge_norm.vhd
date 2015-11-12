library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
-- Add additional libraries here

entity bg_merge_norm is
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
end bg_merge_norm;

architecture Behavioral of bg_merge_norm is
    -- Add types here
    type NodeStates is (idle, new_data, compute, compute1, data_out, sync);
    -- Add signals here
    signal NodeState : NodeStates;

    signal internal_output_req : std_logic;
    signal internal_output_ack : std_logic;

    signal currInput : integer range 0 to NO_INPUTS-1;

    -- FP stuff
    signal fp_opa : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_opb : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_mul_result : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_sum_result : std_logic_vector(DATA_WIDTH-1 downto 0);

    -- mul & sub stage
    signal fp_start : std_logic;
    signal fp_mul_rdy : std_logic;
    signal fp_rdy : std_logic;
    signal fp_finished : std_logic; -- this is a flipflopped version

    -- sqrt stage
    signal fp_sqrt_start : std_logic;
    signal fp_sqrt_rdy : std_logic;
    signal fp_result : std_logic_vector(DATA_WIDTH-1 downto 0);
begin
    out_req <= internal_output_req;
    internal_output_ack <= out_ack;

    assert (NO_INPUTS > 0)
    report "bg_merge_norm: need one input at least. Use bg_source instead."
    severity failure;

    GENERATE_FULL_MERGE : if (NO_INPUTS>0) generate
        fp_mul : entity work.fpu_add(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_opa,
                    opb_i => fp_opa,
                    rmode_i => "00", -- round to nearest even
                    output_o => fp_mul_result,
                    start_i => fp_start,
                    ready_o => fp_mul_rdy
                 );
        fp_add : entity work.fpu_add(rtl)
        port map (
                    clk_i => clk,
                    opa_i => fp_mul_result,
                    opb_i => fp_opb,
                    rmode_i => "00", -- round to nearest even
                    output_o => fp_sum_result,
                    start_i => fp_mul_rdy,
                    ready_o => fp_rdy
                 );
        fp_sqrt : entity work.fpu_sqrt(rtl)
            port map (
                        clk_i => clk,
                        opa_i => fp_sum_result,
                        rmode_i => "00", -- round to nearest even
                        output_o => fp_result,
                        start_i => fp_sqrt_start,
                        ready_o => fp_sqrt_rdy
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

        -- TODO: It might be better to ack after pushing data to the fp unit
        NodeProcess : process(clk)
        begin
            if clk'event and clk = '1' then
                if rst = '1' then
                    in_ack <= (others => '0');
                    internal_output_req <= '0';
                    currInput <= 0;
                    fp_start <= '0';
                    fp_sqrt_start <= '0';
                    fp_opa <= (others => '0');
                    fp_opb <= (others => '0');
                    out_port <= (others => '0');
                    NodeState <= idle;
                else
                    fp_start <= '0';
                    fp_sqrt_start <= '0';
                    if (halt = '0') then
                        -- defaults
                        case NodeState is
                            when idle =>
                                in_ack(currInput) <= '0';
                                internal_output_req <= '0';
                                if ((in_req(currInput) = '1') and (fp_finished = '1')) then
                                    -- pass incoming data to opa
                                    fp_opa <= in_port(currInput);
                                    if (currInput = 0) then
                                        -- when we have the first value, we should set opb to bias
                                        fp_opb <= in_bias;
                                    else
                                        -- otherwise we assign the last result to opb
                                        fp_opb <= fp_sum_result;
                                    end if;
                                    -- raise ack for currInput
                                    in_ack(currInput) <= '1';
                                    -- trigger fp_func and go to new data
                                    fp_start <= '1';
                                    NodeState <= new_data;
                                else
                                    NodeState <= idle;
                                end if;

                            when new_data =>
                                in_ack(currInput) <= '1';
                                internal_output_req <= '0';
                                if (in_req(currInput) = '0') then
                                    in_ack(currInput) <= '0';
                                    if (currInput < NO_INPUTS-1) then
                                        -- we still have inputs to process
                                        currInput <= currInput + 1;
                                        NodeState <= idle;
                                    else
                                        -- we have no more inputs to process
                                        currInput <= 0;
                                        NodeState <= compute;
                                    end if;
                                else
                                    NodeState <= new_data;
                                end if;

                            when compute =>
                                in_ack <= (others => '0');
                                internal_output_req <= '0';
                                if (fp_finished = '1') then
                                    -- trigger sqrt
                                    fp_sqrt_start <= '1';
                                    NodeState <= compute1;
                                else
                                    NodeState <= compute;
                                end if;
                            when compute1 =>
                                in_ack <= (others => '0');
                                internal_output_req <= '0';
                                if (fp_sqrt_rdy = '1') then
                                    out_port <= fp_result;
                                    NodeState <= data_out;
                                else
                                    NodeState <= compute1;
                                end if;

                            when data_out =>
                                in_ack <= (others => '0');
                                internal_output_req <= '1';
                                if (internal_output_ack = '1') then
                                    internal_output_req <= '0';
                                    NodeState <= sync;
                                else
                                    NodeState <= data_out;
                                end if;
                            when sync =>
                                in_ack <= (others => '0');
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
    end generate;

end Behavioral;
