library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use WORK.constants.all;
use WORK.alu_types.all;

entity ALU is
  generic (N : integer := numBit);
  port 	 ( FUNC: IN TYPE_OP;
           DATA1, DATA2: IN std_logic_vector(N-1 downto 0);
           OUTALU: OUT std_logic_vector(N-1 downto 0));
end ALU;

architecture BEHAVIOR of ALU is

	-- signal MUL_RES : std_logic_vector(N-1 downto 0);

begin
    -- We tried with an if generate but the VHDL version dosen't seem 
    -- to like the else statement
    -- mul_bits : if (N mod 2 = 0) generate
    --     MUL_RES <= std_logic_vector(unsigned(DATA1((N-1)/2 downto 0)) * unsigned(DATA2((N-1)/2 downto 0)));
    --   else
    --     MUL_RES <= std_logic_vector(unsigned(DATA1((N-2)/2 downto 0)) * unsigned(DATA2((N-2)/2 downto 0)));
    -- end generate mul_bits;

P_ALU: process (FUNC, DATA1, DATA2)
  begin
    case FUNC is
		
	    when ADD 	    => OUTALU <= std_logic_vector(unsigned(DATA1) + unsigned(DATA2)); 
	    when SUB 	    => OUTALU <= std_logic_vector(unsigned(DATA1) - unsigned(DATA2));
   
      -- This takes into account if the number of bits is odd we need to decrease of another bit
		  when MULT 	    => 
        if (N mod 2 = 0) then
          OUTALU <= std_logic_vector(unsigned(DATA1((N-1)/2 downto 0)) * unsigned(DATA2((N-1)/2 downto 0)));
        else 
          OUTALU <= std_logic_vector(unsigned(DATA1((N-2)/2 downto 0)) * unsigned(DATA2((N-2)/2 downto 0)));
        end if;
      
      --- Bitwise Operations
		  when BITAND   => OUTALU <= DATA1 AND DATA2; 
	    when BITOR 	  => OUTALU <= DATA1 OR DATA2;
	    when BITXOR 	=> OUTALU <= DATA1 XOR DATA2;
      ---

	    when FUNCLSL 	=> OUTALU <= DATA1(N-2 downto 0) & "0";       -- logical shift left  
	    when FUNCLSR 	=> OUTALU <= "0" & DATA1(N-1 downto 1);       -- logical shift right
	    when FUNCRL 	=> OUTALU <= DATA1(N-2 downto 0)& DATA1(N-1); -- rotate left
	    when FUNCRR 	=> OUTALU <= DATA1(0) & DATA1(N-1 downto 1);  -- roate right
	    
		  -- Added N times LSL,LSR,ROR,ROL functions
      when FUNNCLSL 	=> OUTALU <= std_logic_vector(shift_left(unsigned(DATA1), to_integer(unsigned(DATA2)))); -- logical shift left  
      when FUNNCLSR 	=> OUTALU <= std_logic_vector(shift_right(unsigned(DATA1), to_integer(unsigned(DATA2)))); -- logical shift right
	    when FUNNCRL 	  => OUTALU <= std_logic_vector(rotate_left(unsigned(DATA1), to_integer(unsigned(DATA2)))); -- rotate left
	    when FUNNCRR 	  => OUTALU <= std_logic_vector(rotate_right(unsigned(DATA1), to_integer(unsigned(DATA2))));  -- roate right
	    when others     => OUTALU <= (others => '0') ;
    end case; 
  end process P_ALU;

end BEHAVIOR;

configuration CFG_ALU_BEHAVIORAL of ALU is
  for BEHAVIOR
  end for;
end CFG_ALU_BEHAVIORAL;
