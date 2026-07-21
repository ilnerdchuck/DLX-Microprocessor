--==============================================================================
--  Project     : DLX Processor Implementation
--  File        : a.a-CW_HW.vhd
--  Description : VHDL design of a hardwired control unit.
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
use work.myTypes.all;
--==============================================================================

entity control_unit is
  generic (
    MICROCODE_MEM_SIZE : integer := 10; -- Microcode Memory Size
    FUN_SIZE           : integer := 11; -- Func Field Size for R-Type Ops
    OP_CODE_SIZE       : integer := 6; -- Op Code Size
    IR_SIZE            : integer := 32; -- Instruction Register Size    
    CW_SIZE            : integer := 15 -- Control Word Size
  );
  port (
    clk   : in std_logic; -- Clock
    reset : in std_logic; -- Reset:Active-Low

    -- Instruction Register
    IR_IN : in std_logic_vector(IR_SIZE - 1 downto 0);

    fetch_enable      : out std_logic; -- Fetch Enable Signal
    decode_enable     : out std_logic; -- Decode Enable Signal
    execute_enable    : out std_logic; -- Execute Enable Signal
    memory_enable     : out std_logic; -- Memory Enable Signal
    write_back_enable : out std_logic; -- Write Back Enable Signal

    -- IF Control Signal
    RF_EN   : out std_logic; -- Instruction Register Latch Enable
    RF_re_1 : out std_logic; -- Instruction Register 1 Read Enable
    RF_re_2 : out std_logic; -- Instruction Register 2 Read Enable
    RF_we   : out std_logic; -- Instruction Register Write Enable 

    source_select_1 : out std_logic; -- Source Select Signal 1 for ALU
    source_select_2 : out std_logic; -- Source Select Signal 2 for ALU
    ALU_op          : out std_logic_vector(FUN_SIZE - 1 downto 0); -- ALU Operation Code
    DRAM_enable     : out std_logic; -- DRAM Enable Signal
    DRAM_WE         : out std_logic; -- DRAM Write Enable Signal
    DRAM_RE         : out std_logic; -- DRAM Read Enable Signal
    source_select_3 : out std_logic; -- Source Select Signal for Memory Stage -> Write back Stage

    inst_type_out : out std_logic_vector(1 downto 0); -- Instruction Type (R, I, J)
    opcode_out    : out std_logic_vector(OP_CODE_SIZE - 1 downto 0) -- OpCode of the Instruction
  );
end control_unit;
architecture Behavioral of control_unit is
  type cw_memory_Type is array(0 to 43) of std_logic_vector(CW_SIZE - 1 downto 0);
  -- This is the cw_memory table with all the CWs
  signal cw_memory : cw_memory_Type := (
  "111111001000011", -- op: 0x00 R Type
  "100000000000000", -- op: 0x01 not implemented
  "110001110000000", -- op: 0x02 JTYPE_JMP
  "110001111000011", -- op: 0x03 JTYPE_JAL
  "111101000000000", -- op: 0x04 JTYPE_BNEZ
  "111101000000000", -- op: 0x05 JTYPE_BEQZ
  "100000000000000", -- op: 0x06 not implemented
  "100000000000000", -- op: 0x07 not implemented
  "111101011000011", -- op: 0x08 ADDI
  "100000000000000", -- op: 0x09 not implemented
  "111101011000011", -- op: 0x0A SUBI
  "100000000000000", -- op: 0x0B not implemented
  "111101011000011", -- op: 0x0C ANDI
  "111101011000011", -- op: 0x0D ORI 
  "111101011000011", -- op: 0x0E XORI
  "100000000000000", -- op: 0x0F not implemented
  "100000000000000", -- op: 0x10 not implemented
  "100000000000000", -- op: 0x11 not implemented
  "100000000000000", -- op: 0x12 not implemented
  "100000000000000", -- op: 0x13 not implemented
  "111101011000011", -- op: 0x14 SLLI
  "100000000000000", -- op: 0x15 NOP
  "111101011000011", -- op: 0x16 SRLI
  "100000000000000", -- op: 0x17 not implemented
  "100000000000000", -- op: 0x18 not implemented
  "111101011000011", -- op: 0x19 SNEI
  "100000000000000", -- op: 0x1A not implemented
  "100000000000000", -- op: 0x1B not implemented
  "111101011000011", -- op: 0x1C SLEI
  "111101011000011", -- op: 0x1D SGEI
  "100000000000000", -- op: 0x1E not implemented
  "100000000000000", -- op: 0x1F not implemented
  "100000000000000", -- op: 0x20 not implemented
  "100000000000000", -- op: 0x21 not implemented
  "100000000000000", -- op: 0x22 not implemented
  "111101011110111", -- op: 0x23 ITYPE_LW
  "100000000000000", -- op: 0x24 not implemented
  "100000000000000", -- op: 0x25 not implemented
  "100000000000000", -- op: 0x26 not implemented
  "100000000000000", -- op: 0x27 not implemented
  "100000000000000", -- op: 0x28 not implemented
  "100000000000000", -- op: 0x29 not implemented
  "100000000000000", -- op: 0x2A not implemented
  "111101011101000" -- op: 0x2B ITYPE_SW
  );

  signal opcode    : std_logic_vector(OP_CODE_SIZE - 1 downto 0); -- OpCode of the Instruction
  signal cw_target : std_logic_vector(CW_SIZE - 1 downto 0); -- Control Word for the decode stage
  signal cw_ex     : std_logic_vector(CW_SIZE - 1 downto 0); -- Control Word for the execute stage
  signal cw_mem    : std_logic_vector(CW_SIZE - 1 downto 0); -- Control Word for the memory stage
  signal cw_wb     : std_logic_vector(CW_SIZE - 1 downto 0); -- Control Word for the write back stage

  signal opcode_ex  : std_logic_vector(OP_CODE_SIZE - 1 downto 0); -- OpCode for the execute stage
  signal opcode_mem : std_logic_vector(OP_CODE_SIZE - 1 downto 0); -- OpCode for the memory stage
  signal opcode_wb  : std_logic_vector(OP_CODE_SIZE - 1 downto 0); -- OpCode for the write back stage

  signal alu_func_type : std_logic_vector(FUN_SIZE - 1 downto 0); -- ALU Function Type for the execute stage

begin
  opcode <= IR_IN(IR_SIZE - 1 downto IR_SIZE - OP_CODE_SIZE) when reset = '0' else
    TYPE_NOP; -- Extracting opcode from instruction register @reset default to NOP
  cw_target <= cw_memory(to_integer(unsigned(opcode))) when reset = '0' else
    (others => '0'); -- Extracting control word from the microcode memory based on the opcode @reset default to NOP

  -- need to output the opcode to the datapath for the forwarding unit to check for hazards for the execution stage
  opcode_out <= opcode_mem; -- used to stall if the instruction is a load and the source register matches the destination register of the EX stage
  ALU_op     <= alu_func_type; -- ALU operation code output

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (reset = '1') then
        -- Reset all control words and opcode signals to a NOP filled pipeline
        cw_ex         <= (others => '0');
        cw_mem        <= (others => '0');
        cw_wb         <= (others => '0');
        opcode_ex     <= (others => '0');
        opcode_mem    <= (others => '0');
        opcode_wb     <= (others => '0');
        alu_func_type <= (others => '0');

      else

        -- update control words for each stage
        cw_ex  <= cw_target;
        cw_mem <= cw_ex;
        cw_wb  <= cw_mem;

        -- Extracting opcode for the next stages
        opcode_ex  <= opcode;
        opcode_mem <= opcode_ex;
        opcode_wb  <= opcode_mem;

        -- ALU function for the Execute stage
        if opcode = TYPE_NOP then
          alu_func_type <= (others => '0'); -- NOP operation
        elsif opcode = ITYPE_ADDI then
          alu_func_type <= RTYPE_ADD; -- ADDI operation
        elsif opcode = ITYPE_SUBI then
          alu_func_type <= RTYPE_SUB; -- SUBI operation
        elsif opcode = ITYPE_ANDI then
          alu_func_type <= RTYPE_AND; -- ANDI operation
        elsif opcode = ITYPE_ORI then
          alu_func_type <= RTYPE_OR; -- ORI operation
        elsif opcode = ITYPE_XORI then
          alu_func_type <= RTYPE_XOR; -- XORI operation
        elsif opcode = ITYPE_SLLI then
          alu_func_type <= RTYPE_SLL; -- SLLI operation
        elsif opcode = ITYPE_SRLI then
          alu_func_type <= RTYPE_SRL; -- SRLI operation
        elsif opcode = ITYPE_SNEI then
          alu_func_type <= RTYPE_SNE; -- SNEI operation
        elsif opcode = ITYPE_SLEI then
          alu_func_type <= RTYPE_SLE; -- SLEI operation
        elsif opcode = ITYPE_SGEI then
          alu_func_type <= RTYPE_SGE; -- SGEI operation
        elsif opcode = ITYPE_LW then
          alu_func_type <= RTYPE_ADD; -- LW operation, ALU adds offset to base address
        elsif opcode = ITYPE_SW then
          alu_func_type <= RTYPE_ADD; -- SW operation, ALU adds offset to base address
        elsif opcode = JTYPE_JMP then
          alu_func_type <= RTYPE_ADD; -- JMP operation, ALU adds offset to base address
        elsif opcode = JTYPE_JAL then
          alu_func_type <= RTYPE_ADD; -- JAL operation, ALU adds offset to base address
        elsif opcode = JTYPE_BEQZ then
          alu_func_type <= RTYPE_ADD; -- BEQZ operation, ALU adds offset to base address
        elsif opcode = JTYPE_BNEZ then
          alu_func_type <= RTYPE_ADD; -- BNEZ operation, ALU adds offset to base address
        else
          alu_func_type <= (others => '0'); -- Default case, reset ALU function type 
        end if;

        -- ALU function for the Execute stage
        -- case opcode is
        --   when TYPE_NOP            =>
        --     alu_func_type <= (others => '0'); -- NOP operation
        --     opcode_ex     <= (others => '0'); -- NOP operation
        --     opcode_mem    <= (others => '0'); -- NOP operation
        --     opcode_wb     <= (others => '0'); -- NOP operation

        --   when RTYPE =>
        --     -- R-Type operation the function is in the IR register 
        --     alu_func_type <= IR_in(FUN_SIZE - 1 downto 0); -- R-Type operation
        --   when ITYPE_ADDI =>
        --     alu_func_type <= RTYPE_ADD; -- ADDI1 operation
        --   when ITYPE_SUBI =>
        --     alu_func_type <= RTYPE_SUB; -- SUBI1 operation
        --   when ITYPE_ANDI =>
        --     alu_func_type <= RTYPE_AND; -- ANDI1 operation
        --   when ITYPE_ORI =>
        --     alu_func_type <= RTYPE_OR; -- ORI1 operation
        --   when ITYPE_XORI =>
        --     alu_func_type <= RTYPE_XOR; -- ORI1 operation
        --   when ITYPE_SLLI =>
        --     alu_func_type <= RTYPE_SLL; -- ORI1 operation
        --   when ITYPE_SRLI =>
        --     alu_func_type <= RTYPE_SRL; -- ORI1 operation
        --   when ITYPE_SNEI =>
        --     alu_func_type <= RTYPE_SNE; -- ORI1 operation
        --   when ITYPE_SLEI =>
        --     alu_func_type <= RTYPE_SLE; -- ORI1 operation
        --   when ITYPE_SGEI =>
        --     alu_func_type <= RTYPE_SGE; -- ORI1 operation
        --   when ITYPE_LW =>
        --     alu_func_type <= RTYPE_ADD; -- ORI1 operation
        --   when ITYPE_SW =>
        --     alu_func_type <= RTYPE_ADD; -- ORI1 operation
        --   when JTYPE_JMP =>
        --     alu_func_type <= RTYPE_ADD; -- ORI1 operation
        --   when JTYPE_JAL =>
        --     alu_func_type <= RTYPE_ADD; -- ORI1 operation
        --   when JTYPE_BEQZ =>
        --     alu_func_type <= RTYPE_ADD; -- ORI1 operation
        --   when JTYPE_BNEZ =>
        --     alu_func_type <= RTYPE_ADD; -- ORI1 operation
        --   when others              =>
        --     alu_func_type <= (others => '0');
        -- end case;
      end if;

    end if;
  end process;

  -- Instruction type update mostly for the jump and branch instructions
  process (opcode, reset)
  begin
    if reset = '1' then
      inst_type_out <= (others => '0'); -- NOP operation
    else
      if opcode = TYPE_NOP then
        inst_type_out <= (others => '0'); -- NOP operation
      elsif opcode = ITYPE_ADDI then
        inst_type_out <= "00"; -- ADDI operation
      elsif opcode = ITYPE_SUBI then
        inst_type_out <= "01"; -- SUBI operation
      elsif opcode = ITYPE_ANDI then
        inst_type_out <= "01"; -- ANDI operation
      elsif opcode = ITYPE_ORI then
        inst_type_out <= "01"; -- ORI operation
      elsif opcode = ITYPE_XORI then
        inst_type_out <= "01"; -- XORI operation
      elsif opcode = ITYPE_SLLI then
        inst_type_out <= "01"; -- SLLI operation
      elsif opcode = ITYPE_SRLI then
        inst_type_out <= "01"; -- SRLI operation
      elsif opcode = ITYPE_SNEI then
        inst_type_out <= "01"; -- SNEI operation
      elsif opcode = ITYPE_SLEI then
        inst_type_out <= "01"; -- SLEI operation
      elsif opcode = ITYPE_SGEI then
        inst_type_out <= "01"; -- SGEI operation
      elsif opcode = ITYPE_LW then
        inst_type_out <= "01"; -- LW operation, ALU adds offset to base address
      elsif opcode = ITYPE_SW then
        inst_type_out <= "01"; -- SW operation, ALU adds offset to base address
      elsif opcode = JTYPE_JMP then
        inst_type_out <= "11"; -- JMP operation, ALU adds offset to base address
      elsif opcode = JTYPE_JAL then
        inst_type_out <= "11"; -- JAL operation, ALU adds offset to base address
      elsif opcode = JTYPE_BEQZ then
        inst_type_out <= "01"; -- BEQZ operation, ALU adds offset to base address
      elsif opcode = JTYPE_BNEZ then
        inst_type_out <= "01"; -- BNEZ operation, ALU adds offset to base address
      else
        inst_type_out <= (others => '0'); -- Default case, reset ALU function type 
      end if;

      -- case opcode is
      --   when TYPE_NOP            =>
      --     inst_type_out <= (others => '0'); -- NOP operation
      --   when RTYPE               =>
      --     inst_type_out <= "00"; -- R-Type operation
      --   when ITYPE_ADDI =>
      --     inst_type_out <= "01"; -- I-Type operation
      --   when ITYPE_SUBI =>
      --     inst_type_out <= "01"; -- I-Type operation
      --   when ITYPE_ANDI =>
      --     inst_type_out <= "01"; -- I-Type operation
      --   when ITYPE_ORI =>
      --     inst_type_out <= "01"; -- I-Type operation
      --   when ITYPE_XORI =>
      --     inst_type_out <= "01"; -- I-Type operation
      --   when ITYPE_SLLI =>
      --     inst_type_out <= "01"; -- I-Type operation
      --   when ITYPE_SRLI =>
      --     inst_type_out <= "01"; -- I-Type operation
      --   when ITYPE_SNEI =>
      --     inst_type_out <= "01"; -- I-Type operation
      --   when ITYPE_SLEI =>
      --     inst_type_out <= "01"; -- I-Type operation
      --   when ITYPE_SGEI =>
      --     inst_type_out <= "01"; -- I-Type operation
      --   when ITYPE_LW =>
      --     inst_type_out <= "01"; -- I-Type operation
      --   when ITYPE_SW =>
      --     inst_type_out <= "01"; -- I-Type operation
      --   when JTYPE_JMP =>
      --     inst_type_out <= "11"; -- J-Type operation
      --   when JTYPE_JAL =>
      --     inst_type_out <= "11"; -- J-Type operation but also I-Type operation for the write back stage
      --   when JTYPE_BEQZ =>
      --     inst_type_out <= "01"; -- J-Type operation
      --   when JTYPE_BNEZ =>
      --     inst_type_out <= "01"; -- J-Type operation
      --   when others =>
      --     inst_type_out <= "00"; -- J-Type operation
      -- end case;
    end if;
  end process;

  -- Update Control signals for the different stages of the pipeline
  -- Fetch stage
  fetch_enable <= cw_target(14); -- Fetch Enable Signal
  -- Decode stage
  decode_enable <= cw_target(13); -- Decode Enable Signal
  RF_EN         <= cw_wb(0) or cw_target(12); -- Register file Enable Signal either form the Write Back stage or Decode stage
  RF_re_1       <= cw_target(11); -- Instruction Register 1 Read Enable
  RF_re_2       <= cw_target(10); -- Instruction Register 2 Read Enable
  -- Execute stage
  execute_enable  <= cw_ex(9); -- Execute Enable Signal
  source_select_1 <= cw_ex(8); -- Source Select Signal 1 for ALU
  source_select_2 <= cw_ex(7); -- Source Select Signal 1 for ALU
  -- Memory stage
  memory_enable   <= cw_mem(6); -- Memory Enable Signal
  DRAM_enable     <= cw_mem(5); -- DRAM Enable Signal
  DRAM_RE         <= cw_mem(4); -- DRAM Read Enable Signal
  DRAM_WE         <= cw_mem(3); -- DRAM Write Enable Signal
  source_select_3 <= cw_mem(2); -- Source Select Signal for Memory Stage
  -- Write Back stage
  write_back_enable <= cw_wb(1); -- Write Back Stage Enable
  RF_we             <= cw_wb(1); -- Instruction Register Write Enable
end architecture;