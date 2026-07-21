library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use WORK.constants.all;

entity encoder is
    Port (
            y: in std_logic_vector(2 downto 0);
            sel: out std_logic_vector(2 downto 0)
        );
 end encoder;

architecture behav of encoder is

begin
    process (y)
    begin
        case y is
            when "000" | "111" =>
                sel <= "000";   -- Vp = 0
            when "001" | "010" =>
                sel <= "001";   -- Vp = +A
            when "011" =>
                sel <= "010";   -- Vp = +2A
            when "100" =>
                sel <= "100";   -- Vp = -2A
            when "101" | "110" =>
                sel <= "110";   -- Vp = -A
            when others =>
                sel <= "000";
        end case;
    end process;

end architecture;