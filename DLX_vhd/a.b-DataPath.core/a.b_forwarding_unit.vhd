--==============================================================================
--  Project     : DLX Processor Implementation
--  File        : a.b_forwarding_unit.vhd
--  Description : VHDL testbench to test a forwarding unit.
--
--  Group Name  : Group 02
--  Members     : Sabina Sarcuni
--                Leonadro Gallina
--                Francesco Mignone
--                
--  Supervisor  : Mariagrazia Graziano, Giavanna Turvani
--  Institution : Polytechnic of Turin, Italy
--
--  Created     : 11 July 2025
--  Last Edited : 11 July 2025
--
--  Notes       : - 5-stage pipeline (IF, ID, EX, MEM, WB)
--                - Supports basic instruction set: R-type, I-type, J-type
--                - Hazard detection and forwarding implemented
--                - Designed for simulation in ModelSim/Questasim
--
--==============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;
use work.myTypes.all;
use ieee.std_logic_textio.all;
--==============================================================================
-- Entity Declaration
entity forwarding_unit is
  generic (
    OPERAND_SIZE : integer := 32; -- Size operands in bits
    NUM_REG      : integer := 5 -- Number of registers in bits (log_2(RF_SIZE))
  );
  port (
    -- Control unit signals
    stage_enable : in std_logic; -- Stage enable signal

    -- Input/Output signals
    EX_MEM_RD   : in std_logic_vector(NUM_REG - 1 downto 0); -- Destination register from EX stage
    MEM_WB_RD   : in std_logic_vector(NUM_REG - 1 downto 0); -- Destination register from MEM stage
    EX_MEM_RegW : in std_logic; -- Register write enable from MEM stage
    MEM_WB_RegW : in std_logic; -- Register write enable from WB stage
    ID_RS_1     : in std_logic_vector(NUM_REG - 1 downto 0); -- Source register 1 from EX stage
    ID_RS_2     : in std_logic_vector(NUM_REG - 1 downto 0); -- Source register 2 from EX stage
    opcode      : in std_logic_vector(5 downto 0); -- Opcode of the instruction
    fwd_A       : out std_logic_vector(1 downto 0); -- Forwarding control for source A
    fwd_B       : out std_logic_vector(1 downto 0); -- Forwarding control for source B
    stall       : out std_logic -- Stall signal to control data hazards
  );
end forwarding_unit;

-- Additional comments:
-- EX_MEM_RegW MEM_WB_RegW are used to catch if the result will be written back to the register file
--==============================================================================
architecture Behavioral of forwarding_unit is

begin

  fwd_A <= "01" when (EX_MEM_RegW = '1' and ID_RS_1 = EX_MEM_RD) else -- Forward from EX stage if the destination register matches source A
    "11" when (MEM_WB_RegW = '1' and ID_RS_1 = MEM_WB_RD) else -- Forward from MEM stage if the destination register matches source A 
    (others => '0'); -- Default no forwarding for source A

  fwd_B <= "01" when (EX_MEM_RegW = '1' and ID_RS_2 = EX_MEM_RD) else -- Forward from EX stage if the destination register matches source B
    "11" when (MEM_WB_RegW = '1' and ID_RS_2 = MEM_WB_RD) else -- Forward from MEM stage if the destination register matches source B
    (others => '0'); -- Default no forwarding for source B

  -- Stall if the operation is a load and the source registers match the destination register of the EX stage
  stall <= '0' when (opcode = ITYPE_LW and (ID_RS_1 = EX_MEM_RD or ID_RS_2 = EX_MEM_RD)) else
    '1'; -- Stall if the load instruction is in progress and source registers match the destination register of the EX stage

end Behavioral;
--==============================================================================