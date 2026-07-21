library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;

entity SUM_GENERATOR is
    generic (
            NBIT: integer := numBit;
            NBIT_PER_BLOCK: integer := 8
            );
    port (
        A,B:	in	std_logic_vector(NBIT-1 downto 0);
        Ci:	in	std_logic_vector(NBIT/NBIT_PER_BLOCK downto 0);
        S:	out	std_logic_vector(NBIT-1 downto 0)
        );
end SUM_GENERATOR;

architecture STRUCTURAL of SUM_GENERATOR is
    component CARRY_SELECT_BLOCK is
        generic (
            NBIT_PER_BLOCK: integer := NBIT_PER_BLOCK
        );
        port (
            A,B:	in	std_logic_vector(NBIT_PER_BLOCK-1 downto 0);
            Cin:	in	std_logic;
            S:	    out	std_logic_vector(NBIT_PER_BLOCK-1 downto 0)
        );
    end component;
    
begin

    -- we have nbit/4 blocks 
    ADDER1: for I in 0 to NBIT/NBIT_PER_BLOCK - 1 generate
        CSB_I : CARRY_SELECT_BLOCK 
            generic map (NBIT_PER_BLOCK => NBIT_PER_BLOCK) 
            -- find the algorithm to connect the blocks 
            -- First select
            -- Port Map (A=> A(3:0), B => B(3:0), S => S(3:0),Cin => Ci(I-1)); 
            -- First select
            -- Port Map (A=> A(7:4), B => B(7:4), S => S => S(7:4),Cin => Ci(I-1)); 
            -- First select
            -- Port Map (A=> A(11:8), B => B(11:8), S => S => S(11:8),Cin => Ci(I-1));
            -- and so on ... 
            Port Map (  A=> A((((I+1)*NBIT_PER_BLOCK)-1) downto (I*NBIT_PER_BLOCK)), 
                        B => B((((I+1)*NBIT_PER_BLOCK)-1) downto (I*NBIT_PER_BLOCK)), 
                        S => S((((I+1)*NBIT_PER_BLOCK)-1) downto (I*NBIT_PER_BLOCK)),
                        Cin => Ci(I)); 
      end generate;
end architecture;

configuration SUM_GEN_STRUCT of SUM_GENERATOR is
    for STRUCTURAL
        for ADDER1
            for all: CARRY_SELECT_BLOCK
                -- use entity work.CARRY_SELECT_BLOCK(STRUC);
                use configuration work.CSB_STRUCT;
            end for;
        end for;
    end for;
end configuration SUM_GEN_STRUCT;