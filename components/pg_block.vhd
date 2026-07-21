library ieee;
use ieee.std_logic_1164.all;

ENTITY PG_BLOCK IS
  PORT (
    Pik, Gik, Pkj, Gkj: IN STD_LOGIC;
    Pij, Gij: OUT STD_LOGIC
  );
END ENTITY;
    
ARCHITECTURE BEHAVIORAL OF PG_BLOCK IS

BEGIN
  Pij <= Pik AND Pkj;
  Gij <= Gik OR (Pik AND Gkj);
END ARCHITECTURE;
