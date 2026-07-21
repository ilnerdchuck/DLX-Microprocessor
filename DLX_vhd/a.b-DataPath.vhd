--==============================================================================
--  Project     : DLX Processor Implementation
--  File        : a.b_DataPath.vhd
--  Description : VHDL design of the DLX Datapath unit.
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
entity datapath is
  generic (
    I_SIZE       : integer := 32; -- Size of instruction in bits
    OPERAND_SIZE : integer := 32; -- Size operands in bits
    NUM_REG      : integer := 5; -- Number of registers in bits (log_2(RF_SIZE))
    FUN_SIZE     : integer := 11 -- ALU operation code size in bits
  );
  port (
    -- DLX Processor signals
    clk   : in std_logic; -- Clock signal
    reset : in std_logic; -- Reset signal

    -- Control unit signals
    fetch_enable      : in std_logic; -- Fetch stage enable signal
    decode_enable     : in std_logic; -- Decode stage enable signal
    execute_enable    : in std_logic; -- Execute stage enable signal
    memory_enable     : in std_logic; -- Memory stage enable signal
    write_back_enable : in std_logic; -- Write Back stage enable signal

    -- Decode stage signals
    -- Register file signals
    RF_en : in std_logic; -- Register file enable signal
    -- Operand 1
    RF_re_1 : in std_logic; -- Register file read enable for source 1 register
    -- Operand 2
    RF_re_2 : in std_logic; -- Register file read enable for source 2 register
    -- Register file write signals
    RF_we : in std_logic; -- Register file write enable

    -- Execute stage signals
    source_1_select : in std_logic; -- Source 1 select signal
    source_2_select : in std_logic; -- Source 2 select signal
    ALU_op          : in std_logic_vector(FUN_SIZE - 1 downto 0); -- ALU operation code input

    -- Memory stage signals
    DRAM_enable     : in std_logic; -- DRAM enable signal
    DRAM_RE         : in std_logic; -- DRAM read enable signal
    DRAM_WE         : in std_logic; -- DRAM write enable signal
    source_3_select : in std_logic; -- Source select signal for memory stage (MEM/ALU) -> Could be replaced by DRAM_enable

    inst_type : in std_logic_vector(1 downto 0); -- Instruction type (R-type, I-type, J-type)
    opcode    : in std_logic_vector(5 downto 0); -- Opcode of the instruction

    IR_out : out std_logic_vector(I_SIZE - 1 downto 0) -- Instruction register (for the CU)
  );
end entity datapath;
--==============================================================================
-- Architecture Declaration
architecture rtl of datapath is

  component fetch_stage is
    generic (
      OPERAND_SIZE : integer := OPERAND_SIZE; -- Size operands in bits
      I_SIZE       : integer := I_SIZE -- Size of instruction in bits
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
  end component fetch_stage;

  component decode_stage is
    generic (
      I_SIZE       : integer := 32; -- Size of instruction in bits
      OPERAND_SIZE : integer := 32; -- Size operands in bits
      NUM_REG      : integer := 5 -- Number of registers in bits (log_2(RF_SIZE))
    );
    port (
      -- DLX Processor signals
      clk   : in std_logic; -- Clock signal
      reset : in std_logic; -- Reset signal

      -- Control unit signals
      stage_enable : in std_logic; -- Output registers enable signal
      -- Register file signals
      RF_en : in std_logic; -- Register file enable signal
      -- Operand 1
      RF_re_1 : in std_logic; -- Register file read enable for source 1 register
      -- Operand 2
      RF_re_2 : in std_logic; -- Register file read enable for source 2 register
      -- Register file write signals
      RF_we     : in std_logic; -- Register file write enable
      inst_type : in std_logic_vector(1 downto 0); -- Instruction type (R-type, I-type, J-type)

      -- Input/Output signals
      IR_in : in std_logic_vector(I_SIZE - 1 downto 0); -- Instruction register
      PC_in : in std_logic_vector(I_SIZE - 1 downto 0); -- Program Counter

      PC_out  : out std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Immediate value for source 1
      A       : out std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Output for source 1 operand
      B       : out std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Output for source 2 operand
      IMM_out : out std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Immediate value for source 1
      -- Register file write address and data ( Writte Back stage)
      RD_addr_in : in std_logic_vector(NUM_REG - 1 downto 0); -- Register file write address for destination register (used in Write Back stage)
      RD_data_in : in std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Register file data for the destination register (used in Write Back stage)
      -- Register file read addresses for source registers ( Used for Forwarding)
      RD_out     : out std_logic_vector(NUM_REG - 1 downto 0); -- Register file write address for destination register bypass (not used in decode stage)
      R_source_1 : out std_logic_vector(NUM_REG - 1 downto 0); -- Register 1 source address for forwarding
      R_source_2 : out std_logic_vector(NUM_REG - 1 downto 0); -- Register 2 source address for forwarding

      -- Signals to handle jump instructions
      jmp_en   : out std_logic; -- Jump enable signal
      jmp_addr : out std_logic_vector(OPERAND_SIZE - 1 downto 0) -- Jump address output
    );
  end component decode_stage;

  component execute_stage is
    generic (
      OPERAND_SIZE : integer := 32; -- Size operands in bits
      NUM_REG      : integer := 5; -- Number of registers in bits (log_2(RF_SIZE))
      FUN_SIZE     : integer := 11 -- Size of ALU operation code in bits
    );
    port (
      -- DLX Processor signals
      clk   : in std_logic; -- Clock signal
      reset : in std_logic; -- Reset signal

      -- Control unit signals
      stage_enable : in std_logic; -- ALU enable signal

      -- ALU operation signals
      alu_op          : in std_logic_vector(FUN_SIZE - 1 downto 0); -- ALU operation code input
      source_1_select : in std_logic; -- Source 1 select signal
      source_2_select : in std_logic; -- Source 2 select signal

      -- Input/Output signals
      PC_in  : in std_logic_vector(OPERAND_SIZE - 1 downto 0); -- PC value input (IMM_1)
      A      : in std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Operand A input
      B      : in std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Operand B input
      IMM_in : in std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Immediate 2 value input

      alu_out : out std_logic_vector(OPERAND_SIZE - 1 downto 0); -- ALU result output

      MEM_data_out : out std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Memory data output (for memory operations)
      -- Register file signals
      RD_in  : in std_logic_vector(NUM_REG - 1 downto 0); -- Register file write address for destination register input (Bypass)
      RD_out : out std_logic_vector(NUM_REG - 1 downto 0); -- Register file write address for destination register output (Bypass)

      -- Forwarding signals
      -- 00: no forwarding, 01: forward from MEM stage, 11: forward from WB stage
      fwd_A : in std_logic_vector(1 downto 0); -- Forwarded value for source A operand
      fwd_B : in std_logic_vector(1 downto 0); -- Forwarded value for source B operand

      RS_wb : in std_logic_vector(OPERAND_SIZE - 1 downto 0) -- Data Forwarded from Write Back stage (WB stage)
    );
  end component execute_stage;
  component write_mem_rf_stage is
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
      MEM_stage_out : out std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Memory stage output -> to Write Back stage

      -- Register file signals
      RD_in  : in std_logic_vector(NUM_REG - 1 downto 0); -- Register file write address for destination register input
      RD_out : out std_logic_vector(NUM_REG - 1 downto 0) -- Register file address input (WB stage)
    );
  end component write_mem_rf_stage;

  component forwarding_unit is
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
  end component forwarding_unit;

  -- Signals for the fetch stage
  signal PC_FD : std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Program Counter output Fetch -> Decode stage
  signal PC_DE : std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Program Counter output Decode -> Execute stage
  signal IR    : std_logic_vector(I_SIZE - 1 downto 0); -- Instruction Register output

  -- Signals for jumps
  signal jmp_en   : std_logic; -- Jump enable signal
  signal jmp_addr : std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Jump address input

  -- Signals for the decode stage
  signal A           : std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Output for source 1 operand
  signal B           : std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Output for source 2 operand
  signal IMM_out     : std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Immediate value for source 1 output
  signal RD_DE       : std_logic_vector(NUM_REG - 1 downto 0); -- Register file write address for destination register input Decode -> Execute stage
  signal RD_addr_WBD : std_logic_vector(NUM_REG - 1 downto 0); -- Register file write address for destination register input Write Back -> Decode (used in Write Back stage)
  signal RD_data_WBD : std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Register file write address for destination register Write Back -> Decode (used in Write Back stage)
  signal R_source_1  : std_logic_vector(NUM_REG - 1 downto 0); -- Register file write address for destination register Decode -> Execute (for forwarding)
  signal R_source_2  : std_logic_vector(NUM_REG - 1 downto 0); -- Register file write address for destination register Decode -> Execute (for forwarding)
  -- Signals for the execute stage
  signal alu_out      : std_logic_vector(OPERAND_SIZE - 1 downto 0); -- ALU result output
  signal MEM_data_out : std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Memory data output (data for memory operations)
  signal RD_EM        : std_logic_vector(NUM_REG - 1 downto 0); -- Register file write address for destination register input Decode -> Execute stage

  -- Forwarding signals
  signal fwd_A : std_logic_vector(1 downto 0); -- Forwarded value for source A operand
  signal fwd_B : std_logic_vector(1 downto 0); -- Forwarded value for source B operand
  signal stall : std_logic; -- Stall signal to control data hazards

  signal f_en : std_logic; -- True Fetch stage enable signal
  signal d_en : std_logic; -- True Decode stage enable signal

begin
  f_en <= fetch_enable and stall; -- Fetch stage enable signal disabled if stall is needed 
  d_en <= decode_enable and stall; -- Fetch stage enable signal disabled if stall is needed 

  -- Instantiate the fetch stage
  fetch_inst : fetch_stage
  generic map(
    OPERAND_SIZE => OPERAND_SIZE,
    I_SIZE       => I_SIZE
  )
  port map
  (
    clk          => clk,
    reset        => reset,
    stage_enable => f_en,
    next_PC_out  => PC_FD, -- Output Program Counter
    IR_out       => IR, -- Output Instruction Register
    jmp_en       => jmp_en, -- Jump enable signal
    jmp_addr     => jmp_addr -- Jump address input
  );

  -- Instantiate the decode stage
  decode_inst : decode_stage
  generic map(
    I_SIZE       => I_SIZE,
    OPERAND_SIZE => OPERAND_SIZE,
    NUM_REG      => NUM_REG
  )
  port map
  (
    clk          => clk,
    reset        => reset,
    stage_enable => d_en,
    RF_en        => RF_en, -- Register file enable signal
    RF_re_1      => RF_re_1, -- Register file read enable for source 1 register
    RF_re_2      => RF_re_2, -- Register file read enable for source 2 register
    RF_we        => RF_we, -- Register file write enable
    inst_type    => inst_type, -- Instruction type (R-type, I-type, J-type)
    IR_in        => IR, -- Instruction register input
    PC_in        => PC_FD, -- Program Counter input

    PC_out  => PC_DE, -- Immediate value for source 1 output
    A       => A, -- Output for source 1 operand
    B       => B, -- Output for source 2 operand
    IMM_out => IMM_out, -- Immediate value for source 1 output

    RD_addr_in => RD_addr_WBD, -- Register file write address for destination register input (used in Write Back stage)
    RD_data_in => RD_data_WBD, -- Register file data for the destination register write (used in Write Back stage)

    RD_out     => RD_DE, -- Register file write address for destination register bypass (not used in decode stage)
    R_source_1 => R_source_1, -- Register file write address for destination register bypass (not used in decode stage)
    R_source_2 => R_source_2, -- Register file write address for destination register bypass (not used in decode stage)

    jmp_en   => jmp_en, -- Jump enable signal
    jmp_addr => jmp_addr -- Jump address output
  );
  -- Instantiate the execute stage
  execute_inst : execute_stage
  generic map(
    OPERAND_SIZE => OPERAND_SIZE,
    NUM_REG      => NUM_REG,
    FUN_SIZE     => FUN_SIZE
  )
  port map
  (
    clk          => clk,
    reset        => reset,
    stage_enable => execute_enable, -- ALU enable signal

    alu_op          => ALU_op, -- ALU operation code input
    source_1_select => source_1_select, -- Source 1 select signal
    source_2_select => source_2_select, -- Source 2 select signal

    PC_in  => PC_DE, -- Immediate 1 value input
    A      => A, -- Operand A input
    B      => B, -- Operand B input
    IMM_in => IMM_out, -- Immediate 2 value input

    alu_out      => alu_out, -- ALU result output
    MEM_data_out => MEM_data_out, -- Memory data output (data for memory operations)

    RD_in  => RD_DE, -- Register file write address for destination register input
    RD_out => RD_EM, -- Register file write address for destination register output (conenct directly to decode stage)

    fwd_A => fwd_A, -- Forwarded value for source A operand (not used in this example)
    fwd_B => fwd_B, -- Forwarded value for source B operand (not used in this example)

    RS_wb => RD_data_WBD -- Data Forwarded from Write Back stage (WB stage)
  );

  -- Instantiate the write memory and write back file stage
  write_mem_rf_inst : write_mem_rf_stage
  generic map(
    OPERAND_SIZE => OPERAND_SIZE,
    NUM_REG      => NUM_REG
  )
  port map
  (
    clk           => clk,
    reset         => reset,
    stage_enable  => memory_enable, -- stage enable signal
    DRAM_enable   => DRAM_enable, -- DRAM enable signal
    DRAM_RE       => DRAM_RE, -- DRAM read enable signal
    DRAM_WE       => DRAM_WE, -- DRAM write enable signal
    source_select => source_3_select, -- Source select signal MEM/ALU

    alu_result    => alu_out, -- ALU result input
    MEM_data_in   => MEM_data_out, -- Memory data input (from execute stage)
    MEM_stage_out => RD_data_WBD, -- Memory stage output

    RD_in  => RD_EM, -- Register file write address for destination register input
    RD_out => RD_addr_WBD -- Register file address input (WB stage)
  );
  -- Instantiate the forwarding unit
  forwarding_unit_inst : forwarding_unit
  generic map(
    OPERAND_SIZE => OPERAND_SIZE,
    NUM_REG      => NUM_REG
  )
  port map
  (
    stage_enable => execute_enable, -- Stage enable signal

    EX_MEM_RD   => RD_DE, -- Destination register from EX stage
    MEM_WB_RD   => RD_addr_WBD, -- Destination register from MEM stage
    EX_MEM_RegW => RF_we, -- Register write enable from MEM stage
    MEM_WB_RegW => RF_we, -- Register write enable from WB stage
    ID_RS_1     => R_source_1, -- Source register 1 from EX stage
    ID_RS_2     => R_source_2, -- Source register 2 from EX stage
    opcode      => opcode, -- Opcode of the instruction

    fwd_A => fwd_A, -- Forwarding control for source A (not used in this example)
    fwd_B => fwd_B, -- Forwarding control for source B (not used in this example)
    stall => stall -- Stall signal to control data hazards (not used in this example)
  );

  IR_out <= IR when reset = '0' else
    X"54000000"; -- Connect the instruction register output to the datapath output
end architecture rtl;
--==============================================================================
