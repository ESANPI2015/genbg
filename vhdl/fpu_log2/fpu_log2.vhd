-----
-- This component computes log2(x)
--
-- Author: M.Schilling
-- Date: 2015/11/27
-- 
-----

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work;
use work.fpupack.all;

entity fpu_log2 is
	port(
        clk_i 			: in std_logic;

        -- Input Operand
        opa_i        	: in std_logic_vector(FP_WIDTH-1 downto 0);  -- Default: FP_WIDTH=32 
        
        -- Output port   
        output_o        : out std_logic_vector(FP_WIDTH-1 downto 0);
        
        -- Control signals
        start_i			: in std_logic; -- is also restart signal
        ready_o 		: out std_logic
		);
end fpu_log2;

architecture rtl of fpu_log2 is

type lookup_t is array(FP_WIDTH-EXP_WIDTH-2 downto 1) of std_logic_vector(FP_WIDTH-1 downto 0);
type t_state is (
                idle,
                compute,
                compute1,
                compute2,
                compute3,
                compute4
                );
signal s_state : t_state := idle;

--constant sqrt_2 : std_logic_vector(FP_WIDTH-1 downto 0) := x"3fb504f3"; -- 1.414214f
constant one : std_logic_vector(FP_WIDTH-1 downto 0) := x"3f800000";
signal s_opa_i : std_logic_vector(FP_WIDTH-1 downto 0);
signal exponent : signed(EXP_WIDTH-1 downto 0);
signal exponent_std : std_logic_vector(EXP_WIDTH-1 downto 0);
signal leading_zeros : std_logic_vector(5 downto 0);
signal nlz : natural range 0 to 8;
signal new_exponent : signed(EXP_WIDTH-1 downto 0);
--signal logm : std_logic_vector(FP_WIDTH-1 downto 0);
signal bit_cnt : integer range 1 to FP_WIDTH-EXP_WIDTH-2;
signal lut_addr : integer range 1 to FP_WIDTH-EXP_WIDTH-2;
signal s_inf_o, s_nan_o : std_logic;

signal fp_mul_opa : std_logic_vector(FP_WIDTH-1 downto 0);
signal fp_mul_opb : std_logic_vector(FP_WIDTH-1 downto 0);
signal fp_mul_result : std_logic_vector(FP_WIDTH-1 downto 0);
signal fp_mul_start : std_logic;
signal fp_mul_rdy : std_logic;

signal fp_add_opa : std_logic_vector(FP_WIDTH-1 downto 0);
signal fp_add_opb : std_logic_vector(FP_WIDTH-1 downto 0);
signal fp_add_result : std_logic_vector(FP_WIDTH-1 downto 0);
signal fp_add_start : std_logic;
signal fp_add_rdy : std_logic;

signal sqrt_value: std_logic_vector(FP_WIDTH-1 downto 0);
signal sqrt_value_inv: std_logic_vector(FP_WIDTH-1 downto 0);
constant lookup : lookup_t :=
(
    22 => x"3fb504f3", -- 1.414214f
    21 => x"3f9837f0", -- 1.189207f
    20 => x"3f8b95c2", -- 1.090508f
    19 => x"3f85aac3", -- 1.044274f
    18 => x"3f82cd86", -- 1.021897f
    17 => x"3f8164d2", -- 1.010889f
    16 => x"3f80b1ed", -- 1.005430f
    15 => x"3f8058d8", -- 1.002711f
    14 => x"3f802c64", -- 1.001355f
    13 => x"3f801630", -- 1.000677f
    12 => x"3f800b18", -- 1.000339f
    11 => x"3f80058c", -- 1.000169f
    10 => x"3f8002c6", -- 1.000085f
    9 => x"3f800163", -- 1.000042f
    8 => x"3f8000b1", -- 1.000021f
    7 => x"3f800058", -- 1.000010f
    6 => x"3f80002c", -- 1.000005f
    5 => x"3f800016", -- 1.000003f
    4 => x"3f80000b", -- 1.000001f
    3 => x"3f800005", -- 1.000001f
    2 => x"3f800002", -- 1.000000f
    1 => x"3f800001" -- 1.000000f
    --0 => x"3f800000" -- 1.000000f
);
constant lookup2 : lookup_t :=
(
    22 => x"3f3504f3", -- 0.707107f
    21 => x"3f5744fd", -- 0.840896f
    20 => x"3f6ac0c7", -- 0.917004f
    19 => x"3f75257e", -- 0.957603f
    18 => x"3f7a83b4", -- 0.978572f
    17 => x"3f7d3e0c", -- 0.989228f
    16 => x"3f7e9e12", -- 0.994599f
    15 => x"3f7f4ecb", -- 0.997296f
    14 => x"3f7fa757", -- 0.998647f
    13 => x"3f7fd3a8", -- 0.999323f
    12 => x"3f7fe9d2", -- 0.999662f
    11 => x"3f7ff4e8", -- 0.999831f
    10 => x"3f7ffa74", -- 0.999915f
    9 => x"3f7ffd3a", -- 0.999958f
    8 => x"3f7ffe9e", -- 0.999979f
    7 => x"3f7fff50", -- 0.999990f
    6 => x"3f7fffa8", -- 0.999995f
    5 => x"3f7fffd4", -- 0.999997f
    4 => x"3f7fffea", -- 0.999999f
    3 => x"3f7ffff6", -- 0.999999f
    2 => x"3f7ffffc", -- 1.000000f
    1 => x"3f7ffffe" -- 1.000000f
    --0 => x"3f800000" -- 1.000000f
);

begin

    fp_mul : entity work.fpu_mul(rtl)
        port map (
                    clk_i => clk_i,
                    opa_i => fp_mul_opa,
                    opb_i => fp_mul_opb,
                    rmode_i => "00", -- round to nearest even
                    output_o => fp_mul_result,
                    start_i => fp_mul_start,
                    ready_o => fp_mul_rdy
                 );
    fp_add : entity work.fpu_add(rtl)
        port map (
                    clk_i => clk_i,
                    opa_i => fp_add_opa,
                    opb_i => fp_add_opb,
                    rmode_i => "00", -- round to nearest even
                    output_o => fp_add_result,
                    start_i => fp_add_start,
                    ready_o => fp_add_rdy
                 );

        -- ROM process
        process(clk_i)
        begin
            if rising_edge(clk_i) then
                sqrt_value_inv <= lookup2(lut_addr); -- 1/sqrt(2)
                sqrt_value <= lookup(lut_addr);  -- sqrt(2)
            end if;
        end process;

        exponent_std <= std_logic_vector(abs(exponent));
        leading_zeros <= count_l_zeros(exponent_std);
-- FSM
process(clk_i)
begin
	if rising_edge(clk_i) then
        -- real defaults
        ready_o <= '0';
        fp_mul_start <= '0';
        fp_add_start <= '0';
        new_exponent <= (others => '0');
        fp_add_opb <= (others => '0');
        fp_mul_opb <= sqrt_value_inv;
        -- pseudo defaults
        s_state <= s_state;
        --bit_cnt <= bit_cnt;
        --lut_addr <= lut_addr;
        --exponent <= exponent;
        --nlz <= nlz;
        --fp_add_opa <= fp_add_opa;
        --fp_mul_opa <= fp_mul_opb;
        case s_state is
            when idle =>
                bit_cnt <= FP_WIDTH-EXP_WIDTH-2;
                if start_i ='1' then
                    s_opa_i <= opa_i;
                    -- get the exponent (-126 - 127)
                    exponent <= signed(opa_i(FP_WIDTH-2 downto FP_WIDTH-EXP_WIDTH-1)) - 127;
                    s_state <= compute;
                end if;
            when compute =>
                -- count number of leading zeros of the absolute value of the exponent
                nlz <= to_integer(unsigned(leading_zeros)); -- range: 0,8
                s_state <= compute1;
            when compute1 =>
                -- derive new_exponent
                if (nlz < 8) then
                    new_exponent <= 127 + to_signed(EXP_WIDTH-1 - nlz, 8); -- range: 7,0
                end if;
                -- fetch
                lut_addr <= bit_cnt;
                s_state <= compute2;
            when compute2 =>
                -- compose the start value of the logarithm of 2^exponent = exponent (TODO: We should do the sum backwards!)
                fp_add_opa <= (others => '0');
                fp_add_opa(FP_WIDTH-2 downto FP_WIDTH-EXP_WIDTH-1) <= std_logic_vector(new_exponent);
                if (nlz < 7) then
                    fp_add_opa(FP_WIDTH-EXP_WIDTH-2 downto FP_WIDTH-2*EXP_WIDTH+nlz) <= exponent_std(EXP_WIDTH-2-nlz downto 0);
                end if;
                if (exponent < 0) then
                    fp_add_opa(FP_WIDTH-1) <= '1';
                end if;
                -- prepare MUL value = (1.m)*2^0
                fp_mul_opa <= (others => '1');
                fp_mul_opa(FP_WIDTH-1 downto FP_WIDTH-2) <= "00";
                fp_mul_opa(FP_WIDTH-EXP_WIDTH-2 downto 0) <= s_opa_i(FP_WIDTH-EXP_WIDTH-2 downto 0);
                -- prefetch
                lut_addr <= lut_addr - 1;
                s_state <= compute3;
            when compute3 =>
                bit_cnt <= bit_cnt - 1;
                fp_add_opb(FP_WIDTH-2 downto FP_WIDTH-EXP_WIDTH-1) <= std_logic_vector(to_signed(bit_cnt - (FP_WIDTH-EXP_WIDTH-1), 8)+127);
                if (bit_cnt = 1) then
                    -- we are finished
                    ready_o <= '1';
                    output_o <= fp_add_opa;
                    s_state <= idle;
                else
                    if (unsigned(fp_mul_opa(FP_WIDTH-2 downto 0)) >= unsigned(sqrt_value(FP_WIDTH-2 downto 0))) then
                        -- start mul
                        fp_mul_start <= '1';
                        -- start add
                        fp_add_start <= '1';
                        s_state <= compute4;
                    else
                        -- prefetch
                        lut_addr <= lut_addr - 1;
                    end if;
                end if;
            when compute4 =>
                -- update opa
                fp_mul_opa <= fp_mul_result;
                -- update fp_add_opa
                fp_add_opa <= fp_add_result;
                if (fp_mul_rdy = '1') then
                    -- prefetch
                    lut_addr <= lut_addr - 1;
                    s_state <= compute3;
                end if;
        end case;
	end if;	
end process;

-- Generate Exceptions 
s_inf_o <= '1' when s_opa_i(30 downto 23)="11111111" and s_nan_o='0' else '0';
s_nan_o <= '1' when s_opa_i(30 downto 0)=SNAN or s_opa_i(30 downto 0)=QNAN else '0';

end rtl;
