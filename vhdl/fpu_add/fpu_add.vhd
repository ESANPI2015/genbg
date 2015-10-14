-------------------------------------------------------------------------------
--
-- Project:	<Floating Point Unit Core>
--  	
-- Description: top entity
-------------------------------------------------------------------------------
--
--				100101011010011100100
--				110000111011100100000
--				100000111011000101101
--				100010111100101111001
--				110000111011101101001
--				010000001011101001010
--				110100111001001100001
--				110111010000001100111
--				110110111110001011101
--				101110110010111101000
--				100000010111000000000
--
-- 	Author:		 Jidan Al-eryani 
-- 	E-mail: 	 jidan@gmx.net
--
--  Copyright (C) 2006
--
--	This source file may be used and distributed without        
--	restriction provided that this copyright statement is not   
--	removed from the file and that any derivative work contains 
--	the original copyright notice and the associated disclaimer.
--                                                           
--		THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     
--	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   
--	TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   
--	FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      
--	OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         
--	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    
--	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   
--	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        
--	BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  
--	LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  
--	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  
--	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         
--	POSSIBILITY OF SUCH DAMAGE. 
--


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library work;
use work.fpupack.all;


entity fpu_add is
    port (
        clk_i 			: in std_logic;

        -- Input Operands A & B
        opa_i        	: in std_logic_vector(FP_WIDTH-1 downto 0);  -- Default: FP_WIDTH=32 
        opb_i           : in std_logic_vector(FP_WIDTH-1 downto 0);
        
        -- Rounding Mode: 
        -- ==============
        -- 00 = round to nearest even(default), 
        -- 01 = round to zero, 
        -- 10 = round up, 
        -- 11 = round down
        rmode_i 		: in std_logic_vector(1 downto 0);
        
        -- Output port   
        output_o        : out std_logic_vector(FP_WIDTH-1 downto 0);
        
        -- Control signals
        start_i			: in std_logic; -- is also restart signal
        ready_o 		: out std_logic;
        
        -- Exceptions
        ine_o 			: out std_logic; -- inexact
        overflow_o  	: out std_logic; -- overflow
        underflow_o 	: out std_logic; -- underflow
        div_zero_o  	: out std_logic; -- divide by zero
        inf_o			: out std_logic; -- infinity
        zero_o			: out std_logic; -- zero
        qnan_o			: out std_logic; -- queit Not-a-Number
        snan_o			: out std_logic -- signaling Not-a-Number
	);   
end fpu_add;

architecture rtl of fpu_add is
    
	component pre_norm_addsub is
	port(clk_i 			: in std_logic;
			 opa_i			: in std_logic_vector(31 downto 0);
			 opb_i			: in std_logic_vector(31 downto 0);
			 fracta_28_o		: out std_logic_vector(27 downto 0);	-- carry(1) & hidden(1) & fraction(23) & guard(1) & round(1) & sticky(1)
			 fractb_28_o		: out std_logic_vector(27 downto 0);
			 exp_o			: out std_logic_vector(7 downto 0));
	end component;
	
	component addsub_28 is
	port(clk_i 			  : in std_logic;
			 fpu_op_i		   : in std_logic;
			 fracta_i			: in std_logic_vector(27 downto 0); -- carry(1) & hidden(1) & fraction(23) & guard(1) & round(1) & sticky(1)
			 fractb_i			: in std_logic_vector(27 downto 0);
			 signa_i 			: in std_logic;
			 signb_i 			: in std_logic;
			 fract_o			: out std_logic_vector(27 downto 0);
			 sign_o 			: out std_logic);
	end component;
	
	component post_norm_addsub is
	port(clk_i 				: in std_logic;
			 opa_i 				: in std_logic_vector(31 downto 0);
			 opb_i 				: in std_logic_vector(31 downto 0);
			 fract_28_i		: in std_logic_vector(27 downto 0);	-- carry(1) & hidden(1) & fraction(23) & guard(1) & round(1) & sticky(1)
			 exp_i			  : in std_logic_vector(7 downto 0);
			 sign_i			  : in std_logic;
			 fpu_op_i			: in std_logic;
			 rmode_i			: in std_logic_vector(1 downto 0);
			 output_o			: out std_logic_vector(31 downto 0);
			 ine_o				: out std_logic
		);
	end component;

	-- Input/output registers
	signal s_opa_i, s_opb_i : std_logic_vector(FP_WIDTH-1 downto 0);
	signal s_fpu_op_i		: std_logic_vector(2 downto 0);
	signal s_rmode_i : std_logic_vector(1 downto 0);
	signal s_output_o : std_logic_vector(FP_WIDTH-1 downto 0);
    signal s_ine_o, s_overflow_o, s_underflow_o, s_div_zero_o, s_inf_o, s_zero_o, s_qnan_o, s_snan_o : std_logic;
	
	type   t_state is (waiting,busy);
	signal s_state : t_state;
	signal s_start_i : std_logic;
	signal s_count : integer;
	signal s_output1 : std_logic_vector(FP_WIDTH-1 downto 0);	
	signal s_infa, s_infb : std_logic;
	
	--	***Add/Substract units signals***

	signal prenorm_addsub_fracta_28_o, prenorm_addsub_fractb_28_o : std_logic_vector(27 downto 0);
	signal prenorm_addsub_exp_o : std_logic_vector(7 downto 0); 
	
	signal addsub_fract_o : std_logic_vector(27 downto 0); 
	signal addsub_sign_o : std_logic;
	
	signal postnorm_addsub_output_o : std_logic_vector(31 downto 0); 
	signal postnorm_addsub_ine_o : std_logic;
	
	
begin
	--***Add/Substract units***
	
	i_prenorm_addsub: pre_norm_addsub
    	port map (
    	  clk_i => clk_i,
				opa_i => s_opa_i,
				opb_i => s_opb_i,
				fracta_28_o => prenorm_addsub_fracta_28_o,
				fractb_28_o => prenorm_addsub_fractb_28_o,
				exp_o=> prenorm_addsub_exp_o);
				
	i_addsub: addsub_28
		port map(
			 clk_i => clk_i, 			
			 fpu_op_i => s_fpu_op_i(0),		 
			 fracta_i	=> prenorm_addsub_fracta_28_o,	
			 fractb_i	=> prenorm_addsub_fractb_28_o,		
			 signa_i =>  s_opa_i(31),			
			 signb_i =>  s_opb_i(31),				
			 fract_o => addsub_fract_o,			
			 sign_o => addsub_sign_o);	
			 
	i_postnorm_addsub: post_norm_addsub
	port map(
		clk_i => clk_i,		
		opa_i => s_opa_i,
		opb_i => s_opb_i,	
		fract_28_i => addsub_fract_o,
		exp_i => prenorm_addsub_exp_o,
		sign_i => addsub_sign_o,
		fpu_op_i => s_fpu_op_i(0), 
		rmode_i => s_rmode_i,
		output_o => postnorm_addsub_output_o,
		ine_o => postnorm_addsub_ine_o
		);
	
			
-----------------------------------------------------------------			

	-- Input Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then	
			s_opa_i <= opa_i;
			s_opb_i <= opb_i;
			s_fpu_op_i <= "000";
			s_rmode_i <= rmode_i;
			s_start_i <= start_i;
		end if;
	end process;
	  
	-- Output Register
	process(clk_i)
	begin
		if rising_edge(clk_i) then	
			output_o <= s_output_o;
			ine_o <= s_ine_o;
			overflow_o <= s_overflow_o;
			underflow_o <= s_underflow_o;
			div_zero_o <= s_div_zero_o;
			inf_o <= s_inf_o;
			zero_o <= s_zero_o;
			qnan_o <= s_qnan_o;
			snan_o <= s_snan_o;
		end if;
	end process;	

    
	-- FSM
	process(clk_i)
	begin
		if rising_edge(clk_i) then
			if s_start_i ='1' then
				s_state <= busy;
				s_count <= 0;
			elsif s_count=6 then
				s_state <= waiting;
				ready_o <= '1';
				s_count <=0;
			elsif s_state=busy then
				s_count <= s_count + 1;
			else
				s_state <= waiting;
				ready_o <= '0';
			end if;
	end if;	
	end process;
	        
    s_output1 		<= postnorm_addsub_output_o;
    s_ine_o 		<= postnorm_addsub_ine_o;

	
	s_infa <= '1' when s_opa_i(30 downto 23)="11111111"  else '0';
	s_infb <= '1' when s_opb_i(30 downto 23)="11111111"  else '0';
	

	--In round down: the subtraction of two equal numbers other than zero are always -0!!!
	process(s_output1, s_rmode_i, s_div_zero_o, s_infa, s_infb, s_qnan_o, s_snan_o, s_zero_o, s_fpu_op_i, s_opa_i, s_opb_i )
	begin
			if s_rmode_i="00" or (s_div_zero_o or (s_infa or s_infb) or s_qnan_o or s_snan_o)='1' then --round-to-nearest-even
				s_output_o <= s_output1;
			elsif s_rmode_i="01" and s_output1(30 downto 23)="11111111" then
				--In round-to-zero: the sum of two non-infinity operands is never infinity,even if an overflow occures
				s_output_o <= s_output1(31) & "1111111011111111111111111111111";
			elsif s_rmode_i="10" and s_output1(31 downto 23)="111111111" then
				--In round-up: the sum of two non-infinity operands is never negative infinity,even if an overflow occures
				s_output_o <= "11111111011111111111111111111111";
			elsif s_rmode_i="11" then
				--In round-down: a-a= -0
				if (s_fpu_op_i="000" or s_fpu_op_i="001") and s_zero_o='1' and (s_opa_i(31) or (s_fpu_op_i(0) xor s_opb_i(31)))='1' then
					s_output_o <= "1" & s_output1(30 downto 0);	
				--In round-down: the sum of two non-infinity operands is never postive infinity,even if an overflow occures
				elsif s_output1(31 downto 23)="011111111" then
					s_output_o <= "01111111011111111111111111111111";
				else
					s_output_o <= s_output1;
				end if;			
			else
				s_output_o <= s_output1;
			end if;
	end process;
		

	-- Generate Exceptions 
	s_underflow_o <= '1' when s_output1(30 downto 23)="00000000" and s_ine_o='1' else '0'; 
	s_overflow_o <= '1' when s_output1(30 downto 23)="11111111" and s_ine_o='1' else '0';
	s_div_zero_o <= '0';
	s_inf_o <= '1' when s_output1(30 downto 23)="11111111" and (s_qnan_o or s_snan_o)='0' else '0';
	s_zero_o <= '1' when or_reduce(s_output1(30 downto 0))='0' else '0';
	s_qnan_o <= '1' when s_output1(30 downto 0)=QNAN else '0';
    s_snan_o <= '1' when s_opa_i(30 downto 0)=SNAN or s_opb_i(30 downto 0)=SNAN else '0';

end rtl;
