library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity CARRY_SELECT_BLOCK is
    generic (
        NBIT_PER_BLOCK: integer := 8
    );
    port (
        A,B:	in	std_logic_vector(NBIT_PER_BLOCK-1 downto 0);
        Cin:	in	std_logic;
        S:	    out	std_logic_vector(NBIT_PER_BLOCK-1 downto 0)
    );
end CARRY_SELECT_BLOCK;


architecture STRUCTURAL of CARRY_SELECT_BLOCK is
    component RCA is 
        generic (   N     :       integer := NumBit;
                    DRCAS : 	Time := 0 ns;
                    DRCAC : 	Time := 0 ns);
        Port (	A:	In	std_logic_vector(N-1 downto 0);
                B:	In	std_logic_vector(N-1 downto 0);
                Ci:	In	std_logic;
                S:	Out	std_logic_vector(N-1 downto 0);
                Co:	Out	std_logic);
    end component; 

    component MUX21_GENERIC IS
        Generic (NBIT: integer:= numBit;
                DELAY_MUX: Time:= tp_mux);
        Port (	A:	In	std_logic_vector(NBIT-1 downto 0) ;
            B:	In	std_logic_vector(NBIT-1 downto 0);
            SEL:	In	std_logic;
            Y:	Out	std_logic_vector(NBIT-1 downto 0));
    end component;


-- Output of the two RCAs
signal RCA_OUT_0,RCA_OUT_1 : STD_LOGIC_VECTOR (NBIT_PER_BLOCK-1 downto 0);

-- Useless signals as the carry out is not needed (we are making this to avoid using this wire)
signal c_out_0,c_out_1 : std_logic;

begin
    ADD_1: RCA 
        generic map (N => NBIT_PER_BLOCK, DRCAS => 0.02 ns, DRCAC => 0 ns) 
        port map (A=>A, B =>B, Ci =>'0', S=>RCA_OUT_0, Co => c_out_0);
    ADD_2: RCA 
        generic map (N => NBIT_PER_BLOCK, DRCAS => 0.02 ns, DRCAC => 0 ns) 
        port map (A=>A, B =>B, Ci => '1', S=>RCA_OUT_1, Co => c_out_1);
    
    MUX_OUT: MUX21_GENERIC 
        generic map (NBIT => NBIT_PER_BLOCK, DELAY_MUX => 0.02 ns) 
        port map (A=>RCA_OUT_0, B =>RCA_OUT_1, SEL=>Cin, Y => S);

    -- S <= RCA_OUT_0 when Cin = '0' else
    --      RCA_OUT_1 when Cin = '1' else 
    --      (others => 'Z'); 
    
end architecture;

architecture BEHAVIORAL of CARRY_SELECT_BLOCK is

begin

    S <=    std_logic_vector(unsigned(A)+unsigned(B)) when Cin = '0' else
            std_logic_vector(unsigned(A)+unsigned(B)+"1")when Cin = '1' else 
            (others => 'Z');

end architecture;

configuration CSB_STRUCT of CARRY_SELECT_BLOCK is
    for STRUCTURAL
        for all: RCA
            use configuration WORK.CFG_RCA_STRUCTURAL;
        end for;
        for MUX_OUT: MUX21_GENERIC
            use configuration WORK.CFG_MUX21_GEN_BEHAVIORAL;
        end for;
    end for;
end CSB_STRUCT;

configuration CSB_BEH of CARRY_SELECT_BLOCK is
    for BEHAVIORAL
    end for;
end configuration CSB_BEH;
  