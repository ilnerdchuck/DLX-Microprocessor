library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use WORK.constants.all;

entity BOOTHMUL is
    Generic ( N : integer := numBit );
    Port (
            A: in std_logic_vector(N-1 downto 0);
            B: in std_logic_vector(N-1 downto 0);
            P: out std_logic_vector(2*N-1 downto 0)
        );
end BOOTHMUL;

-- the booth multiplier works on at least 3 bits

architecture mul_struct of BOOTHMUL is

-- Signals
signal zeros : std_logic_vector( N -1 downto 0 );               -- Used to extend A 
signal ext_A : std_logic_vector( 2*N -1 downto 0 );              -- A expanded to 2N bits

signal sel_sig : std_logic_vector( ((N/2)*3)-1 downto 0 );    -- Nbits which is B operands +1 for the first stage
signal B0 : std_logic_vector( 2 downto 0 );


-- n sum stages is N/2-1
signal shiftout_sig : std_logic_vector((2*N * ((N/2))) - 1 downto 0); -- N bits for each stage for the mux output

signal sum_sig : std_logic_vector((2*N * (N/2)) - 1 downto 0);    -- 32bit x ((N/2 - 1)adders - 1)
signal Vp_sig : std_logic_vector((2*N * ((N/2)-1)) - 1 downto 0);   -- 32bit x (N/2)muxes one for each stage

-- Components
component encoder is
    Port (
            y: in std_logic_vector(2 downto 0);
            sel: out std_logic_vector(2 downto 0)
        );
end component;

component mux5to1 is
    Generic ( N: integer := N );  
    Port (
            sel: in std_logic_vector(2 downto 0);
            A  : in std_logic_vector(N -1 downto 0);
            Vp : out std_logic_vector(N -1 downto 0)
        );
end component;

component RCA is
    generic (N : integer := 2*N);
    port (
            A  : in std_logic_vector(N - 1 downto 0);
            B  : in std_logic_vector(N - 1 downto 0);
            Ci : in std_logic;
            S  : out std_logic_vector(N - 1 downto 0);
            Co : out std_logic
         );
end component;
  
component left_shifter is
    Generic (
                N: integer := 2*N;
                pos: integer := 1
            );
    Port (
            A  : in std_logic_vector(N-1 downto 0);
            A_shifted : out std_logic_vector(N-1 downto 0)
         );
end component;

component P4_ADDER is 
	generic (
			N:	integer := 2*N;
			NBIT_BLOCK:	integer := 4	
		);		

	port (	A:	in	std_logic_vector(N - 1 downto 0);	
			B:	in	std_logic_vector(N - 1 downto 0);	
			Ci:	in	std_logic;				
			S:	out	std_logic_vector(N - 1 downto 0);	
			Co:	out	std_logic);				
    end component;


begin
-- Extend A
zeros <= (others => '0');
ext_A <= zeros & A;

-- Prepare the first encoder input
B0 <= B(1 downto 0)&'0';

-- First stage is only a MUX with the select bits
E0 : encoder port map (
                        y => B0, 
                        sel => sel_sig(2 downto 0)
                      );

MUX0 : mux5to1 generic map (
                                N => 2*N
                            )
                port map (
                            sel => sel_sig(2 downto 0), 
                            A   => ext_A,                -- A
                            Vp  => sum_sig(2*N-1 downto 0)
                        );
-- need to shift A by 2 positions to get 4A
SH0 : left_shifter generic map (
                            N => 2*N,
                            pos => 2
                        )  
                        port map (
                            A  => ext_A, 
                            A_shifted => shiftout_sig(2*N-1 downto 0)
                        );
-- A is now 4Anull

-- now we generate for the number of true stages 

booth_stages : for i in 1 to ((N/2) - 1) generate -- N=8
    -- generate the stage encoder
    EXi : encoder port map (
                            y => B((i*2)+1 downto (i*2)-1), 
                            sel => sel_sig((i*3)+2 downto (i*3)) 
                          );

    -- -- generate the stage multiplexer
    MUXi : mux5to1 generic map (
                                N => 2*N
                                ) 
                    port map (
                                sel => sel_sig((i*3)+2 downto (i*3)), 
                                A   => shiftout_sig(2*N*(i)-1 downto 2*N*(i-1)),    -- 4*iA shift selection generated in the previous stage 
                                Vp  => Vp_sig(2*N*(i)-1 downto 2*N*(i-1))           -- Update the current    
                    );

    -- -- generate the stage shifter for the next A value 
    SHi : left_shifter generic map (
                                N => 2*N,
                                pos => 2
                            )  
                            port map (
                                A  => shiftout_sig(2*N*(i)-1 downto 2*N*(i-1)),  -- Take the previous A value 
                                A_shifted => shiftout_sig(2*N*(i+1)-1 downto 2*N*(i))   -- Shift of 2 further bits 4*(i+1)A
                            );

    -- generate the sium generator
    -- SUMi: rca generic map (N => 2*N) 
    --     port map (
    --                 A   => sum_sig(2*N*(i)-1 downto 2*N*(i-1)),    -- Add the previous sum result to the 
    --                 B   => Vp_sig(2*N*(i)-1 downto 2*N*(i-1)),       -- current mux output
    --                 Ci  => '0', 
    --                 S   => sum_sig(2*N*(i+1)-1 downto 2*N*(i)),    -- Assign it to the current stage sum output
    --                 Co  => open                            
    --             );
    Pi: P4_ADDER  
        generic map(
                N => 2*N,
                NBIT_BLOCK => 4	
            )		    
        port map(	
                A   => sum_sig(2*N*(i)-1 downto 2*N*(i-1)),    -- Add the previous sum result to the 
                B   => Vp_sig(2*N*(i)-1 downto 2*N*(i-1)),       -- current mux output
                Ci  => '0', 
                S   => sum_sig(2*N*(i+1)-1 downto 2*N*(i)),    -- Assign it to the current stage sum output
                Co  => open
        );				

    -- sum_sig(2*N*(i+1)-1 downto 2*N*(i)) <= std_logic_vector(unsigned(sum_sig(2*N*(i)-1 downto 2*N*(i-1))) + unsigned(Vp_sig(2*N*(i)-1 downto 2*N*(i-1))));
end generate;

-- The last sum is the last part of the sum signal
P <= sum_sig((2*N*(N/2))-1 downto (2*N*((N/2)-1)));

end architecture;
