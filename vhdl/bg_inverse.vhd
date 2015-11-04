library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
-- Add additional libraries here

entity bg_inverse is
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
end bg_inverse;

architecture Behavioral of bg_inverse is
    -- Add types here
    type NodeStates is (idle, new_data, compute, data_out, sync);
    -- Add signals here
    signal NodeState : NodeStates;

    signal internal_input_req : std_logic;
    signal internal_input_ack : std_logic;
    signal internal_output_req : std_logic;
    signal internal_output_ack : std_logic;

    -- FP stuff
    signal fp_opb : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fp_result : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal fp_start : std_logic;
    signal fp_rdy : std_logic;
    signal fp_finished : std_logic; -- this is a flipflopped version

begin
    internal_input_req <= in_req;
    in_ack <= internal_input_ack;
    out_req <= internal_output_req;
    internal_output_ack <= out_ack;

    fp_div : entity work.fpu_div(rtl)
        port map (
                    clk_i => clk,
                    opa_i => x"3f800000",
                    opb_i => fp_opb,
                    rmode_i => "00", -- round to nearest even
                    output_o => fp_result,
                    start_i => fp_start,
                    ready_o => fp_rdy
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
                fp_opb <= (others => '0');
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
                                fp_opb <= in_port;
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
