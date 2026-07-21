--==============================================================================
--  Project     : DLX Processor Implementation
--  File        : TB_DLX.vhd
--  Description : VHDL design of the testbench for the DLX processor.
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
library IEEE;
use IEEE.std_logic_1164.all;
use WORK.all;
--==============================================================================

entity tb_dlx is
end tb_dlx;

architecture TEST of tb_dlx is
  constant SIZE_IR           : integer   := 32; -- Instruction Register Size
  constant SIZE_PC           : integer   := 32; -- Program Counter Size
  constant SIZE_ALU_OPC      : integer   := 6; -- ALU Op Code Word Size in case explicit coding is used
  constant SIZE_ALU_FUNCTION : integer   := 11; -- ALU Op Code Word Size in case explicit coding is used
  constant clock_period      : integer   := 10; -- ALU Op Code Word Size in case explicit coding is used
  signal Clock               : std_logic := '0';
  signal Reset               : std_logic := '1';

  component DLX
    generic (
      IR_SIZE  : integer := 32; -- Instruction Register Size
      FUN_SIZE : integer := 11; -- Func Field Size for R-Type Ops
      PC_SIZE  : integer := 32 -- Program Counter Size
    );
    port (
      Clk : in std_logic;
      Rst : in std_logic);
  end component;
begin
  -- instance of DLX
  U1 : DLX
  generic map(SIZE_IR, SIZE_ALU_FUNCTION, SIZE_PC) -- SIZE_ALU_OPC)   
  port map
    (Clock, Reset);

  Clock <= not Clock after clock_period / 2 * 1 ns;

  process
  begin
    -- Reset the system
    Reset <= '1';
    wait on Clock until falling_edge(Clock);
    Reset <= '0';
    wait;
  end process;
end TEST;

-------------------------------