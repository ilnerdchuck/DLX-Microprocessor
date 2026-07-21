library ieee;
use ieee.std_logic_1164.all;

package myTypes is

  -- Control unit input sizes
  constant OP_CODE_SIZE : integer := 6; -- OPCODE field size
  constant FUNC_SIZE    : integer := 11; -- FUNC field size

  -- R-Type instruction -> OPCODE field 00
  constant RTYPE : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := (others => '0'); -- register-to-register operation 

  -- R-Type instruction -> FUNC field
  constant RTYPE_ADD : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000100000"; -- ADD RS1,RS2,RD 0x20
  constant RTYPE_SUB : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000100010"; -- SUB RS1,RS2,RD 0x22
  constant RTYPE_AND : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000100100"; -- AND RS1,RS2,RD 0x24
  constant RTYPE_OR  : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000100101"; -- OR RS1,RS2,RD 0x25
  constant RTYPE_XOR : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000100110"; -- XOR RS1,RS2,RD 0x26
  constant RTYPE_SLL : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000000100"; -- SLL RS1,RS2,RD 0x04
  constant RTYPE_SRL : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000000110"; -- SRL RS1,RS2,RD 0x06
  constant RTYPE_SNE : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000101001"; -- SLL RS1,RS2,RD 0x29
  constant RTYPE_SLE : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000101100"; -- SRL RS1,RS2,RD 0x2C
  constant RTYPE_SGE : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000101101"; -- SRL RS1,RS2,RD 0x2D
  -- constant RTYPE_MUL : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000001010"; -- MUL RS1,RS2,RD
  -- constant RTYPE_DIV : std_logic_vector(FUNC_SIZE - 1 downto 0) := "00000001011"; -- DIV RS1,RS2,RD

  -- I-Type instruction -> OPCODE field 01
  -- IMM1
  constant ITYPE_ADDI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "001000"; -- ADDI RS1,RD,INP1 
  constant ITYPE_SUBI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "001010"; -- SUBI RS1,RD,INP1
  constant ITYPE_ANDI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "001100"; -- ANDI RS1,RD,INP1
  constant ITYPE_ORI  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "001101"; -- ORI RS1,RD,INP1
  constant ITYPE_XORI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "001110"; -- XORI RS1,RD,INP1
  constant ITYPE_SLLI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "010100"; -- SLLI RS1,RD,INP1
  constant TYPE_NOP   : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "010101"; -- NOP operation 00
  constant ITYPE_SRLI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "010110"; -- SRLI RS1,RD,INP1
  constant ITYPE_SNEI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "011001"; -- SNEI RS1,RD,INP1
  constant ITYPE_SLEI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "011100"; -- SLEI RS1,RD,INP1
  constant ITYPE_SGEI : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "011101"; -- SGEI RS1,RD,INP1

  -- MEM
  constant ITYPE_LW : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "100011"; -- LW RS1,RD,INP1
  constant ITYPE_SW : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "101011"; -- SW RS1,RS2,INP1

  -- J-Type instruction -> OPCODE field 11
  constant JTYPE_JMP  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "000010"; -- JUMP INP1
  constant JTYPE_JAL  : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "000011"; -- JAL INP1
  constant JTYPE_BEQZ : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "000100"; -- BEQZ RS1,INP1
  constant JTYPE_BNEZ : std_logic_vector(OP_CODE_SIZE - 1 downto 0) := "000101"; -- BNEZ RS1,INP1

end myTypes;
