library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.bg_vhdl_types.all;
-- Add additional libraries here

entity bg_copy is
    generic(
               NO_OUTPUTS : integer := 2
           );
    port(
        -- Inputs
            in_port : in std_logic_vector(DATA_WIDTH-1 downto 0);
            in_req : in std_logic;
            in_ack : out std_logic;
        -- Outputs
            out_port : out DATA_PORT(NO_OUTPUTS-1 downto 0);
            out_req : out DATA_SIGNAL(NO_OUTPUTS-1 downto 0);
            out_ack : in DATA_SIGNAL(NO_OUTPUTS-1 downto 0);
        -- Other signals
            halt : in std_logic;
            rst : in std_logic;
            clk : in std_logic
        );
end bg_copy;

architecture Behavioral of bg_copy is
begin
    -- NOTE: Assertion is triggered on false!
    assert (NO_OUTPUTS>0)
    report "bg_copy: Need at least one output. Use bg_sink instead."
    severity failure;

    GENERATE_FULL_COPY : if (NO_OUTPUTS>0) generate
        -- When we have outputs we have to distribute the request signal
        process (in_req)
        begin
            for i in NO_OUTPUTS-1 downto 0 loop
                out_req(i) <= in_req;
            end loop;
        end process;

        -- as well as the data
        process (in_port)
        begin
            for i in NO_OUTPUTS-1 downto 0 loop
                out_port(i) <= in_port;
            end loop;
        end process;

        -- ... and gather all acknowledgements (logical and)
        process (out_ack)
            variable result : std_logic;
        begin
            result := '1';
            for i in NO_OUTPUTS-1 downto 0 loop
                result := result and out_ack(i);
            end loop;
            in_ack <= result;
        end process;

    end generate;

end Behavioral;
