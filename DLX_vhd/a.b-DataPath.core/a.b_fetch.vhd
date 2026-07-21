--==============================================================================
--  Project     : DLX Processor Implementation
--  File        : a.b_fetch.vhd
--  Description : VHDL design of a fetch unit.
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
use ieee.math_real.all;
use work.myTypes.all;

--==============================================================================

entity fetch_stage is
  generic (
    OPERAND_SIZE : integer := 32; -- Size operands in bits
    I_SIZE       : integer := 32 -- Size of instruction in bits
  );
  port (
    -- DLX Processor signals
    clk   : in std_logic; -- Clock signal
    reset : in std_logic; -- Reset signal
    -- Control unit signals
    stage_enable : in std_logic; -- Program Counter enable signal

    -- Input/Output signals
    next_PC_out : out std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Output Program Counter
    IR_out      : out std_logic_vector(I_SIZE - 1 downto 0); -- Output Instruction Register
    -- Jump/Branch signals
    jmp_en   : in std_logic; -- Jump enable signal
    jmp_addr : in std_logic_vector(I_SIZE - 1 downto 0) -- Jump address input
  );
end fetch_stage;

architecture Behavioral of fetch_stage is
  --Instruction Ram
  component IRAM
    generic (
      RAM_DEPTH : integer := 48; -- Depth of instruction RAM
      I_SIZE    : integer := I_SIZE -- Size of instruction in bits
    );
    port (
      Rst  : in std_logic;
      Addr : in std_logic_vector(I_SIZE - 1 downto 0);
      Dout : out std_logic_vector(I_SIZE - 1 downto 0)
    );
  end component;

  signal PC           : std_logic_vector(I_SIZE - 1 downto 0); -- Program Counter
  signal IR           : std_logic_vector(I_SIZE - 1 downto 0); -- Instruction Register
  signal RAM_data_out : std_logic_vector(I_SIZE - 1 downto 0); -- Instruction Register
begin
  -- Instantiate the IRAM component
  IRAM_inst : entity work.IRAM
    generic map(
      RAM_DEPTH => 48, -- Depth of instruction RAM
      I_SIZE    => I_SIZE -- Size of instruction in bits
    )
    port map
    (
      Rst  => reset,
      Addr => PC, -- Address for IRAM 
      Dout => RAM_data_out -- Next instruction output
    );
  -- Process to handle Program Counter and Instruction Register
  FETCH_PROCESS : process (clk, reset)
  begin
    if reset = '1' then
      PC <= (others => '0'); -- Reset Program Counter
      IR <= X"54000000"; -- Reset Instruction Register
    elsif rising_edge(clk) then
      if stage_enable = '1' then
        if jmp_en = '1' then
          PC <= std_logic_vector(signed(PC) + signed(jmp_addr)); -- Jump to specified address
          IR <= X"54000000"; -- Force a NOP operation to stall the pipeline
        else
          PC <= std_logic_vector(signed(PC) + 1); -- Increment Program Counter
          IR <= RAM_data_out; -- Load instruction from IRAM
        end if;
      end if;
    end if;
  end process FETCH_PROCESS;

  -- Output assignments
  next_pc_out <= PC; -- Output Program Counter value
  ir_out      <= IR; -- Output fetched instruction

end Behavioral;
--==============================================================================