library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use WORK.constants.all;

entity mux5to1 is
    Generic ( N: integer := 8 );    
    Port (
            sel: in std_logic_vector(2 downto 0);
            A  : in std_logic_vector(N-1 downto 0);   -- A already expanded
            Vp : out std_logic_vector(N-1 downto 0)
         );
 end mux5to1;

 architecture arch_mux of mux5to1 is 

    signal Vp_2A : std_logic_vector(N-1 downto 0);

    component left_shifter is
        Generic ( 
                    N: integer := N;
                    pos: integer := 12
                );
        Port (
                A  : in std_logic_vector(N-1 downto 0);
                A_shifted : out std_logic_vector(N-1 downto 0)
             );
     end component;

 begin
    SH : left_shifter   generic map (
                                        N => N,
                                        pos => 1 
                                    ) 
                        port map (
                                    A => A, 
                                    A_shifted => Vp_2A
                                );
    
    Vp <=       (others => '0') when sel="000" else
                A               when sel="001" else 
                Vp_2A           when sel="010" else 
                std_logic_vector(unsigned(not(Vp_2A)) + 1) when sel="100" else 
                std_logic_vector(unsigned(not(A)) + 1) when sel="110" else 
                (others => '0'); 
    
 end architecture;

