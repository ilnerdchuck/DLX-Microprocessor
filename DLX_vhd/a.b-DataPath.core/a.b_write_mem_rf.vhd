--==============================================================================
--  Project     : DLX Processor Implementation
--  File        : a.b_write_back.vhd
--  Description : VHDL design of a memory and write back stage unit.
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
--==============================================================================
-- Entity Declaration
entity write_mem_rf_stage is
  generic (
    OPERAND_SIZE : integer := 32; -- Size operands in bits
    NUM_REG      : integer := 5 -- Number of registers in bits (log_2(RF_SIZE))
  );
  port (
    -- DLX Processor signals
    clk   : in std_logic; -- Clock signal
    reset : in std_logic; -- Reset signal
    -- Control unit signals
    stage_enable  : in std_logic; -- stage enable 
    DRAM_enable   : in std_logic; -- DRAM enable signal 
    DRAM_RE       : in std_logic; -- DRAM read enable signal
    DRAM_WE       : in std_logic; -- DRAM write enable signal
    source_select : in std_logic; -- Source select signal MEM/ALU
    -- Input/Output signals
    alu_result    : in std_logic_vector(OPERAND_SIZE - 1 downto 0); -- ALU result input
    MEM_data_in   : in std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Memory data input (from execute stage)
    MEM_stage_out : out std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Memory stage output

    -- Register file signals
    RD_in  : in std_logic_vector(NUM_REG - 1 downto 0); -- Register file write address for destination register input
    RD_out : out std_logic_vector(NUM_REG - 1 downto 0) -- Register file address input (WB stage)
  );
end write_mem_rf_stage;
--==============================================================================
architecture Behavioral of write_mem_rf_stage is
  component DRAM is
    generic (
      DATA_SIZE : integer := 32; -- Size of instruction in bits
      RAM_DEPTH : integer := 48 -- DRAM Size
    );
    port (
      Rst : in std_logic;
      re  : in std_logic; -- Read enable signal
      we  : in std_logic; -- Write enable signal
      -- Address and data ports
      Addr     : in std_logic_vector(DATA_SIZE - 1 downto 0);
      data_in  : in std_logic_vector(DATA_SIZE - 1 downto 0);
      data_out : out std_logic_vector(DATA_SIZE - 1 downto 0)
    );

  end component DRAM;

  signal DRAM_out : std_logic_vector(OPERAND_SIZE - 1 downto 0);

begin

  DRAM_inst : DRAM
  generic map(
    DATA_SIZE => OPERAND_SIZE, -- Size of data in bits
    RAM_DEPTH => 48 -- DRAM Size (increase if needed)
  )
  port map
  (
    rst      => reset,
    re       => DRAM_RE,
    we       => DRAM_WE,
    Addr     => alu_result,
    data_in  => MEM_data_in,
    data_out => DRAM_out
  );

  MEM_STAGE : process (clk, reset)
  begin
    if reset = '1' then

      MEM_stage_out <= (others => '0'); -- Reset memory stage output
      RD_out        <= (others => '0'); -- Reset register file data output

    elsif rising_edge(clk) then

      if stage_enable = '1' then
        RD_out <= RD_in;
        -- Output of memory stage
        if source_select = '0' then
          MEM_stage_out <= alu_result; -- Forward ALU result to Write back stage
        else
          MEM_stage_out <= DRAM_out; -- Forward DRAM output to Write back stage
        end if;
      end if;

    end if;
  end process MEM_STAGE;
end Behavioral;
--==============================================================================
