library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use work.constants.all;

entity P4_ADDER is 

	generic (
			N:	integer := numBit;
			NBIT_BLOCK:	integer := 4	
		);		

	port (	A:	in	std_logic_vector(N - 1 downto 0);	
			B:	in	std_logic_vector(N - 1 downto 0);	
			Ci:	in	std_logic;				
			S:	out	std_logic_vector(N - 1 downto 0);	
			Co:	out	std_logic);				
    end P4_ADDER;


architecture STRUCTURAL of P4_ADDER is

	component SUM_GENERATOR is
		generic (
				NBIT: integer := numBit;
				NBIT_PER_BLOCK: integer := NBIT_BLOCK
				);
		port (
			A,B:	in	std_logic_vector(NBIT-1 downto 0);
			Ci:	in	std_logic_vector(NBIT/NBIT_PER_BLOCK downto 0);
			S:	out	std_logic_vector(NBIT-1 downto 0)
			);
	end component;
	
	component CARRYGEN is 
		generic (
			N:	integer := N;
			NBIT_BLOCK: integer := NBIT_BLOCK
		);		
		port 	(   A:	in	std_logic_vector(N - 1 downto 0);	
				    B:	in	std_logic_vector(N - 1 downto 0);	
				    Ci:	in	std_logic;				
				    Co:	out	std_logic_vector(N/NBIT_BLOCK - 1 downto 0)
                );	
	end component;

	signal CarryOut: std_logic_vector (N/NBIT_BLOCK - 1 downto 0); 
    signal CarryIn: std_logic_vector (N/NBIT_BLOCK downto 0);

	begin

		P4_CARRY_GENERATOR: CARRYGEN
		generic map (
			N => N,
			NBIT_BLOCK => NBIT_BLOCK
			)
        port map (A=>A, B=>B, Ci=>Ci, Co => CarryOut);
        
        -- Add the carry in to the carries to generate the sum of the LSB bits
        CarryIn <= CarryOut & Ci;

		P4_SUM_GENERATOR: SUM_GENERATOR
		generic map (NBIT => N, NBIT_PER_BLOCK => NBIT_BLOCK)
		port map (A => A, B => B, Ci => CarryIn, S => S);
        
        -- Connect the last generated carry to the adder output 
		Co <= CarryOut(N/NBIT_BLOCK - 1);

end STRUCTURAL;
