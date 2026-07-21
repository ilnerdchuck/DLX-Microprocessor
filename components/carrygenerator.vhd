LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;

ENTITY CARRYGEN IS
  GENERIC (
            N: INTEGER := 32;
            NBIT_BLOCK: INTEGER := 4
          );
  PORT (
    Ci: IN STD_LOGIC;
    A, B: IN STD_LOGIC_VECTOR(N DOWNTO 1);
    Co: OUT STD_LOGIC_VECTOR(N/NBIT_BLOCK-1 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE STRUCTURAL OF CARRYGEN IS

  CONSTANT MAX_I: INTEGER := INTEGER(CEIL(LOG2(REAL(N))))+1;

  COMPONENT PG_BLOCK IS
    PORT (
      Pik, Gik, Pkj, Gkj: STD_LOGIC;
      Pij, Gij: OUT STD_LOGIC
    );
  END COMPONENT;

  COMPONENT G_BLOCK IS
    PORT (
      Pik, Gik, Gkj: IN STD_LOGIC;
      Gij: OUT STD_LOGIC
    );
  END COMPONENT;

  COMPONENT PG_NETWORK_BLOCK IS
    PORT (
      Ai, Bi: IN STD_LOGIC;
      Pi, Gi: OUT STD_LOGIC
    );
  END COMPONENT;

  COMPONENT PG_CARRY_BLOCK IS
    PORT (
      Ai, Bi, Ci: IN STD_LOGIC;
      Pi, Gi: OUT STD_LOGIC
    );
  END COMPONENT;

  TYPE MAT IS ARRAY(MAX_I-1 DOWNTO 0) OF STD_LOGIC_VECTOR(N DOWNTO 1);
  SIGNAL P_MAT, G_MAT: MAT;
BEGIN

  -- This loop creates the first row of PG blocks
  PG_NET_LOOP: FOR I IN 2 TO N GENERATE
  BEGIN
    PG_J: PG_NETWORK_BLOCK PORT MAP (Ai=>A(I), Bi=>B(I), Pi=>P_MAT(0)(I), Gi=>G_MAT(0)(I));
  END GENERATE;

  -- The first block takes also the Ci input
  PG_C: PG_CARRY_BLOCK PORT MAP (Ai=>A(1), Bi=>B(1), Ci=>Ci, Pi=>P_MAT(0)(1), Gi=>G_MAT(0)(1));

  -- This loop creates the three rows with only one G block
  FIRST_OUTER_LOOP: FOR I IN 1 TO 3 GENERATE
  BEGIN
    -- Since it is generic, this if checks if the row has to be generated or not (if N<16 I don't need all the rows)
    OUTER_CHECK: IF (2**I)<=N GENERATE
    BEGIN
      -- I need N/(2^I) blocks, but the least significant one is a G block
      FIRST_INNER_LOOP: FOR J IN 0 TO N/(2**I)-2 GENERATE
      BEGIN
        PG_J: PG_BLOCK PORT MAP (Pik=>P_MAT(I-1)(N-(2**I)*J), Gik=>G_MAT(I-1)(N-(2**I)*J), Pkj=>P_MAT(I-1)(N-(2**I)*J-(2**(I-1))),
                                  Gkj=>G_MAT(I-1)(N-(2**I)*J-(2**(I-1))), Pij=>P_MAT(I)(N-(2**I)*J), Gij=>G_MAT(I)(N-(2**I)*J));
      END GENERATE;

      SECOND_INNER_LOOP: FOR J IN 0 TO N GENERATE
        INNER_CHECK: IF (J REM (2**I))/=0 GENERATE
          P_MAT(I)(J)<=P_MAT(I-1)(J);
          G_MAT(I)(J)<=G_MAT(I-1)(J);
        END GENERATE;
      END GENERATE;

      G_I: G_BLOCK PORT MAP (Pik=>P_MAT(I-1)(2**I), Gik=>G_MAT(I-1)(2**I), Gkj=>G_MAT(I-1)((2**I)-(2**(I-1))), Gij=>G_MAT(I)(2**I));
      
      -- Assigning the correspondent G_MAT element to Co 
      -- Co(I-1)<=G_MAT(I+INTEGER(CEIL(LOG2(REAL(NBIT_BLOCK))))-1)(NBIT_BLOCK*I);
    END GENERATE;
  END GENERATE;

  -- From I=4 the pattern changes
  SECOND_OUTER_LOOP: FOR I IN 4 TO MAX_I GENERATE
  BEGIN
    INNER_CHECK: IF (2**I)<=N GENERATE
    BEGIN
      -- Loop to generate PG blocks
      FIRST_INNER_LOOP: FOR J IN 0 TO (N/(2**(I)))-2 GENERATE
      BEGIN
        INNER_INNER_LOOP: FOR K IN 0 TO 2**(I-3)-1 GENERATE
        BEGIN
          PG_J: PG_BLOCK PORT MAP (Pik=>P_MAT(I-1)(N-J*(2**I)-(4*K)), Gik=>G_MAT(I-1)(N-J*(2**I)-(4*K)), Pkj=>P_MAT(I-1)(N-J*(2**I)-(2**(I-1))),
                                    Gkj=>G_MAT(I-1)(N-J*(2**I)-(2**(I-1))), Pij=>P_MAT(I)(N-J*(2**I)-(4*K)), Gij=>G_MAT(I)(N-J*(2**I)-(4*K)));

          P_MAT(I)(N-J*(2**I)-(2**(I-1))-(4*K))<=P_MAT(I-1)(N-J*(2**I)-(2**(I-1))-(4*K));
          G_MAT(I)(N-J*(2**I)-(2**(I-1))-(4*K))<=G_MAT(I-1)(N-J*(2**I)-(2**(I-1))-(4*K));
        END GENERATE;

      END GENERATE;

      -- Loop to generate G blocks
      SECOND_INNER_LOOP: FOR K IN 0 TO 2**(I-3)-1 GENERATE
      BEGIN
        G_I: G_BLOCK PORT MAP (Pik=>P_MAT(I-1)((2**I)-4*K), Gik=>G_MAT(I-1)((2**I)-4*K), Gkj=>G_MAT(I-1)(2**(I-1)), Gij=>G_MAT(I)((2**I)-4*K));

        -- Assigning the correspondent G_MAT element to Co 
        -- Co((2**(I-INTEGER(CEIL(LOG2(REAL(NBIT_BLOCK))))))-K-1)<=G_MAT(I)((2**I)-NBIT_BLOCK*K);
      END GENERATE;
    END GENERATE;
  END GENERATE;

  -- Assigning the correspondent G_MAT element to Co 
  C_OUT_ASSIGNMENT: FOR I IN 1 TO N/NBIT_BLOCK GENERATE
    Co(I-1) <= G_MAT(INTEGER(CEIL(LOG2(REAL(I*NBIT_BLOCK)))))(I*NBIT_BLOCK);
  END GENERATE;
END ARCHITECTURE;