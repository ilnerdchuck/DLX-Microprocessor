library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;


entity ACC is
    generic (
        numBit : INTEGER := numbit
    );
    port (
        A,B: in  STD_LOGIC_VECTOR (numBit-1 downto 0);
        Y : out  STD_LOGIC_VECTOR (numBit-1 downto 0);
        ACCUMULATE, CLK, RST_n: in STD_LOGIC
    );
end entity;

architecture STRUCTURAL of ACC is
    
    -- MUX declaration
    component MUX21_GENERIC
        Generic (NBIT: integer:= numBit;
                DELAY_MUX: Time:= tp_mux);
        Port (	A:	In	std_logic_vector(NBIT-1 downto 0) ;
            B:	In	std_logic_vector(NBIT-1 downto 0);
            SEL:	In	std_logic;
            Y:	Out	std_logic_vector(NBIT-1 downto 0));
	end component;

    -- Adder declaration
    component RCA is 
        generic ( N     :   integer := numBit;
                  DRCAS : 	Time := 0 ns;
                  DRCAC : 	Time := 0 ns);
        Port (	A:	In	std_logic_vector(N-1 downto 0);
            B:	In	std_logic_vector(N-1 downto 0);
            Ci:	In	std_logic;
            S:	Out	std_logic_vector(N-1 downto 0);
            Co:	Out	std_logic);
    end component;   

    -- Register component declaration
    component FD is
        Generic (NBIT: integer:= numBit);
        Port (	D:	In	std_logic_vector(NBIT-1 downto 0);
                CK:	In	std_logic;
                RESET:	In	std_logic;
                Q:	Out	std_logic_vector(NBIT-1 downto 0));
    end component;
    
  signal MUX_OUT,RCA_OUT,REG_OUT : STD_LOGIC_VECTOR (numBit-1 downto 0);
  signal c_out : STD_LOGIC;
  
begin

	REG_FF : FD
        generic map (NBIT => numBit) 
        Port Map (D => RCA_OUT,CK => CLK, RESET => RST_n, Q=> REG_OUT); 
	
    ADD: RCA 
        generic map (N => numBit, DRCAS => 0.02 ns, DRCAC => 0 ns) 
        port map (A=>A, B =>MUX_OUT, Ci => '0', S=>RCA_OUT, Co => c_out);
    
    MUX : MUX21_GENERIC
        Generic Map (NBIT => numBit, DELAY_MUX => 3 ns)
        Port Map ( A => REG_OUT, B => B, SEL => ACCUMULATE, Y => MUX_OUT); 
    
    Y<=REG_OUT; 
end architecture;

-------------
-------------


architecture BEHAVIORAL of ACC is

    signal REG_Y,OUT_RCA,MUX_OUT : STD_LOGIC_VECTOR (numBit-1 downto 0);

begin
    
-- Register behavior
process (CLK)
begin
    -- we choose a syncronus reset
    if rising_edge(CLK) then
        if RST_n = '0' then
            REG_Y <= (others => '0') ;
        else
            REG_Y <= OUT_RCA;
        end if; 
    end if;
end process;

--MUX behavior
process (ACCUMULATE,B,REG_Y)
begin
    if ACCUMULATE = '0' then
        MUX_OUT <= B after 3 ns;
    elsif ACCUMULATE = '1' then
        MUX_OUT <= REG_Y after 3 ns;
    end if;        
end process;

-- RCA
process (A,MUX_OUT)
begin
    OUT_RCA <= std_logic_vector(unsigned(A)+unsigned(MUX_OUT)) after 0.02 ns;
end process;

Y <= REG_Y;

end architecture;



-------------
-------------


configuration CFG_ACC_STRUCTURAL of ACC is
    for STRUCTURAL
        for ADD: RCA
            use configuration WORK.CFG_RCA_BEHAVIORAL;
        end for;
        for REG_FF : FD
          use configuration WORK.CFG_FD_PIPPO; -- sincrono
        end for;
        for MUX: MUX21_GENERIC
            use configuration WORK.CFG_MUX21_GEN_BEHAVIORAL; 
        end for;
    end for;
end CFG_ACC_STRUCTURAL;

configuration CFG_ACC_BEHAVIORAL of ACC is
    for BEHAVIORAL
    end for;
end CFG_ACC_BEHAVIORAL;

  