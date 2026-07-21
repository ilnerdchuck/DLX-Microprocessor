library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use WORK.constants.all;

entity left_shifter is
    Generic (
                N: integer := 16;
                pos: integer := 1
            );
    Port (
            A  : in std_logic_vector(N-1 downto 0);
            A_shifted : out std_logic_vector(N-1 downto 0)
        );
 end left_shifter;

 architecture arch_shift of left_shifter is
 
 begin
    
    A_shifted(pos-1 downto 0) <= (others => '0'); 
    A_shifted(N-1 downto pos) <= A(N-1-pos downto 0); -- A left-shift by pos positions

 end architecture;