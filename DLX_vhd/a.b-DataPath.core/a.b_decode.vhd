--==============================================================================
--  Project     : DLX Processor Implementation
--  File        : a.b_decode.vhd
--  Description : VHDL design of a decode unit.
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
-- Entity Declaration
-- Operation types 
-- 00: R-type, 01: I-type, 11: J-type
entity decode_stage is
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

    PC_out  : out std_logic_vector(OPERAND_SIZE - 1 downto 0); -- PC output for jump instructions (IMM_1)
    A       : out std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Output for source 1 operand
    B       : out std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Output for source 2 operand
    IMM_out : out std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Immediate value for source 2
    -- Register file write address and data ( Writte Back stage)
    RD_addr_in : in std_logic_vector(NUM_REG - 1 downto 0); -- Register file write address for destination register (used in Write Back stage)
    RD_data_in : in std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Register file data for the destination register write (used in Write Back stage)
    -- Register file read addresses for source registers ( Used for Forwarding)
    RD_out     : out std_logic_vector(NUM_REG - 1 downto 0); -- Register file write address for destination register bypass (not used in decode stage)
    R_source_1 : out std_logic_vector(NUM_REG - 1 downto 0); -- Register 1 source address for forwarding
    R_source_2 : out std_logic_vector(NUM_REG - 1 downto 0); -- Register 2 source address for forwarding

    -- Signals to handle jump instructions
    jmp_en   : out std_logic; -- Jump enable signal
    jmp_addr : out std_logic_vector(OPERAND_SIZE - 1 downto 0) -- Jump address output
  );
end decode_stage;

architecture Behavioral of decode_stage is

  -- Register file
  component register_file is
    generic (
      NBit : integer := OPERAND_SIZE; -- number of bit per register
      NReg : integer := 2 ** NUM_REG -- number of memory locations/registers
    );
    port (
      CLK     : in std_logic; -- Clock Signal
      RESET   : in std_logic; -- Reset Signal
      ENABLE  : in std_logic; -- Enable Signal
      RD1     : in std_logic; -- Read 1 Signal
      RD2     : in std_logic; -- Read 2 Signal
      WR      : in std_logic; -- Write Signal
      ADD_WR  : in std_logic_vector(integer(ceil(log2(real(NReg)))) - 1 downto 0); -- Write Address
      ADD_RD1 : in std_logic_vector(integer(ceil(log2(real(NReg)))) - 1 downto 0); -- Read 1 Address
      ADD_RD2 : in std_logic_vector(integer(ceil(log2(real(NReg)))) - 1 downto 0); -- Read 2 Address
      DATAIN  : in std_logic_vector(NBit - 1 downto 0); -- Data in Signal
      OUT1    : out std_logic_vector(NBit - 1 downto 0); -- Data Out 1 Signal
      OUT2    : out std_logic_vector(NBit - 1 downto 0) -- Data Out 2 Signal
    );
  end component register_file;

  signal opcode : std_logic_vector(5 downto 0); -- Opcode of the instruction
  -- Register file read addresses
  -- RF_R1_addr and RF_R2_addr are used to read the source registers
  signal RF_R1_addr : std_logic_vector(NUM_REG - 1 downto 0); -- Register file read address for source 1
  signal RF_R2_addr : std_logic_vector(NUM_REG - 1 downto 0); -- Register file read address for source 2

  -- Register File Output operands
  signal RF_data_out_1 : std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Register Output for source 1 register
  signal RF_data_out_2 : std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Register Output for source 2 register

  -- Immediate values for source operands
  signal IMM_1   : std_logic_vector(OPERAND_SIZE - 1 - 6 downto 0); -- Immediate value for source 1 J-Type instruction
  signal IMM_2   : std_logic_vector(OPERAND_SIZE - 1 - 16 downto 0); -- Immediate value for source 2 I-Type instruction
  signal IMM_ext : std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Immediate value for source 2 I-Type instruction
begin
  decode_RF : entity work.register_file
    generic map(
      NBit => OPERAND_SIZE, -- Number of bits per register
      NReg => 2 ** NUM_REG -- Number of registers
    )
    port map
    (
      clk     => clk,
      reset   => reset,
      ENABLE  => RF_en, -- Register file enable signal
      RD1     => RF_re_1, -- Read 1 signal for source 1 register
      RD2     => RF_re_2, -- Read 2 signal for source 2 register
      WR      => RF_we, -- Write signal for register file
      ADD_WR  => RD_addr_in, -- Write address for destination register
      ADD_RD1 => RF_R1_addr, -- Read address for source 1 register
      ADD_RD2 => RF_R2_addr, -- Read address for source 2 register
      DATAIN  => RD_data_in, -- Data input for register file (not used in decode stage)
      OUT1    => RF_data_out_1, -- Data output for source 1 register
      OUT2    => RF_data_out_2 -- Data output for source 2 register 
    );
  -- IR signal splitting
  RF_R1_addr <= IR_in(25 downto 21) when reset = '0' else
    (others => '0'); -- Source 1 register address (rs)
  RF_R2_addr <= IR_in(20 downto 16) when reset = '0' else
    (others => '0'); -- Source 2 register address (rt)
  IMM_1 <= IR_in(25 downto 0) when reset = '0' else
    (others => '0'); -- Immediate value for source 1 (J-Type instruction)
  IMM_2 <= IR_in(15 downto 0) when reset = '0' else
    (others => '0'); -- Immediate value for source 2 (I-Type instruction)
  opcode <= IR_in(31 downto 26) when reset = '0' else
    (others => '0'); -- Opcode of the instruction

  -- Immediate value extension for I-Type instructions
  IMM_ext <= std_logic_vector(resize(signed(IMM_2), IMM_out'length)) when inst_type = "01" else
    std_logic_vector(resize(signed(IMM_1), IMM_out'length)) when inst_type = "11" else
    (others => '0'); -- Sign-extend immediate value for source 2 (I-Type instruction)

  -- Jump instruction handling
  -- If opcode is bqez and A is zero, set jump enable and address

  jmp_en <= '1' when (opcode = JTYPE_BEQZ) and RF_data_out_1 = (RF_data_out_1'range => '0') else -- beqz instruction
    '1' when (opcode = JTYPE_BNEZ) and RF_data_out_1 /= (RF_data_out_1'range          => '0') else -- bnez instruction
    '1' when (opcode = JTYPE_JMP) or (opcode = JTYPE_JAL) else -- jmp and jal instructions
    '0'; -- Jump enable signal for J-Type instructions

  jmp_addr <= std_logic_vector(signed(IMM_ext)/4); -- jump address output

  -- Process to decode instruction and read operands from register file
  DECODE_PROCESS : process (clk, reset)
  begin
    if reset = '1' then
      A          <= (others => '0'); -- Reset output for source 1 operand
      B          <= (others => '0'); -- Reset output for source 2 operand
      PC_out     <= (others => '0'); -- Reset immediate value output for source 1
      IMM_out    <= (others => '0'); -- Reset immediate value output for source 2
      RD_out     <= (others => '0'); -- Reset register file write address for destination register
      R_source_1 <= (others => '0'); -- Reset register source 1
      R_source_2 <= (others => '0'); -- Reset register source 2

    elsif rising_edge(clk) then
      if stage_enable = '1' then
        -- Decode instruction and set read addresses based on instruction format
        -- Register values are read from the register file
        A <= RF_data_out_1; -- Source 1 register 
        B <= RF_data_out_2; -- Source 2 register 

        -- Immediate values
        PC_out     <= PC_in; -- PC to compute a JUMP instruction
        R_source_1 <= RF_R1_addr; -- Source 1 register 
        R_source_2 <= RF_R2_addr; -- Source 2 register 

        -- Decode the address for destination register
        if inst_type = "00" then
          RD_out <= IR_in(15 downto 11);
        elsif inst_type = "01" then
          RD_out <= IR_in(20 downto 16);
        elsif inst_type = "11" then
          if opcode = JTYPE_JAL then
            RD_out <= (others => '1'); -- Link register (R31 or the last one) for JAL instruction
          else
            RD_out <= (others => '0');
          end if;
        else
          RD_out <= (others => '0');
        end if;
        IMM_out <= IMM_ext; -- Immediate value for source 2
      end if;
    end if;
  end process DECODE_PROCESS;
end Behavioral;
--==============================================================================
