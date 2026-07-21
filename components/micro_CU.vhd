library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.constants.all;
use work.myTypes.all;
-- We have taken the assumption that the Decode unit gives only the valuable bits of the function
-- field. In the laboratory case is two. This is useful to use them to directly drive the ALU
-- configuration

-- To make the uprogrammed control unit even more generic we could output only the control word
-- in any needed size and then a wrapper entity is done to connect 
-- the needed output signals of the CW to drive a datapath.
-- As the datapath is defined in the laboratory, then the control unit is made ad hoc
-- for this datapath

entity micro_CU is
  generic (
    OPCODE_SIZE     : integer := 6; -- Number Bits of the OPCODE
    FUNCITON_SIZE   : integer := 2; -- Number Bits of the FUNCTION
    CW_SIZE         : integer := 13; -- Number Bits of the Control Word
    OP_CLOCK_NEEDED : integer := 3 -- Number control words/stages/etc per instruction
  );
  port (
    clk    : in std_logic;
    reset  : in std_logic;
    opcode : in std_logic_vector(OPCODE_SIZE - 1 downto 0);
    func   : in std_logic_vector(FUNCITON_SIZE - 1 downto 0);
    rdy    : in std_logic; -- Used to enable a new OPCODE fetch
    -- Stage 1
    rf_rd1 : out std_logic; -- Enable signal for read 1 of the RF
    rf_rd2 : out std_logic; -- Enable signal for read 2 of the RF
    en_1   : out std_logic; -- Enable signal for the first stage for A,B, in_1,in_2, rd_1
    -- Stage 2
    s_a    : out std_logic; -- Enable signal for selecting operand A
    s_b    : out std_logic; -- Enable signal for selecting operand B
    alu_op : out std_logic_vector (1 downto 0);
    en_2   : out std_logic; -- Enable signal for the second stage ALU output/data memory, rd_2
    -- Stage 3
    s_am : out std_logic; -- Enable signal for selecting alu or memory result
    en_3 : out std_logic; -- Enable signal for the memory
    wrf  : out std_logic; -- Write enable for the RF
    mr   : out std_logic; -- Enable signal for the memory read request
    mw   : out std_logic -- Enable signal for the memory write request
  );
end entity;
architecture rtl of micro_CU is
  constant reloc_size : integer := 2 ** OPCODE_SIZE;
  -- In our case there are only 3 cw per instruction thus is multiplied by 3
  -- size is 2 ** OPCODE_SIZE * OP_CLOCK_NEEDED in this case OP_CLOCK_NEEDED
  constant ucode_mem_size : integer := 2 ** OPCODE_SIZE * OP_CLOCK_NEEDED;
  -- OPCODE to memory address translator
  -- We could also not use a memory translator and add +3 to each OPCODE to find the base address
  -- Note that then there will edge cases (R-Type instruction) in instruction that have the same opcode
  -- in a generic case the formula could be OPCODDE * (OP_CLOCK_NEEDED * FUNCTION)
  type opcode_mem_tr is array (0 to reloc_size - 1) of std_logic_vector(integer(ceil(log2(real(ucode_mem_size)))) - 1 downto 0);
  signal base_addr_tr : opcode_mem_tr := (
  -- used to translate the opcode to its base address in the memory
  -- initialized for OPCODE_SIZE to be on 6 bits
  "00000000", -- 000000 NOP
  "00000011", -- 000001 ADD - SUB - AND - OR
  "00000000", -- 000010 NOP
  "00000000", -- 000011 NOP
  "00000000", -- 000100 NOP
  "00000000", -- 000101 NOP
  "00000000", -- 000110 NOP
  "00000000", -- 000111 NOP
  "00000000", -- 001000 NOP
  "00000000", -- 001001 NOP
  "00000000", -- 001010 NOP
  "00000000", -- 001011 NOP
  "00000000", -- 001100 NOP
  "00000000", -- 001101 NOP
  "00000000", -- 001110 NOP
  "00000000", -- 001111 NOP
  "00000000", -- 010000 NOP
  "00000000", -- 010001 NOP
  "00000000", -- 010010 NOP
  "00000000", -- 010011 NOP
  "00000000", -- 010100 NOP
  "00000000", -- 010101 NOP
  "00000000", -- 010110 NOP
  "00000000", -- 010111 NOP
  "00000000", -- 011000 NOP
  "00000000", -- 011001 NOP
  "00000000", -- 011010 NOP
  "00000000", -- 011011 NOP
  "00000000", -- 011100 NOP
  "00000000", -- 011101 NOP
  "00000000", -- 011110 NOP
  "00000000", -- 011111 NOP
  "01100000", -- 100000 ADDI1 RS1,RD,INP1
  "01100011", -- 100001 SUBI1 RS1,RD,INP1
  "01100110", -- 100010 ANDI1 RS1,RD,INP1
  "01101001", -- 100011 ORI1 RS1,RD,INP1
  "01101100", -- 100100 ADDI2 RS1,RD,INP1
  "01101111", -- 100101 SUBI2 RS1,RD,INP1
  "01110010", -- 100110 ANDI2 RS1,RD,INP1
  "01110101", -- 100111 ORI2 RS1,RD,INP1
  "01111000", -- 101000 MOV RS1,RD,INP1
  "01111010", -- 101001 SREG1 RS1,RD,INP1
  "01111011", -- 101010 SREG2 RS1,RD,INP1
  "10000001", -- 101011 SMEM RS1,RD,INP1
  "10000100", -- 101100 LMEM1 RS1,RD,INP1
  "10000111", -- 101101 LMEM2 RS1,RD,INP1
  "00000000", -- 101110 NOP
  "00000000", -- 101111 NOP
  "00000000", -- 110000 NOP
  "00000000", -- 110001 NOP
  "00000000", -- 110010 NOP
  "00000000", -- 110011 NOP
  "00000000", -- 110100 NOP
  "00000000", -- 110101 NOP
  "00000000", -- 110110 NOP
  "00000000", -- 110111 NOP
  "00000000", -- 111000 NOP
  "00000000", -- 111001 NOP
  "00000000", -- 111010 NOP
  "00000000", -- 111011 NOP
  "00000000", -- 111100 NOP
  "00000000", -- 111101 NOP
  "00000000", -- 111110 NOP
  "00000000" -- 111111 NOP
  );

  -- Function memory  not used in this case because the two LSB of the function field are directly used to drive the ALU
  -- type function_tr is array (2 ** FUNCTION_SIZE downto 0) of std_logic_vector(OPCODE_SIZE + 1 downto 0);
  -- signal base_addr_tr : opcode_mem_tr := (
  -- -- used to translate the opcode to its base address in the memory
  -- -- initialized for OPCODE_SIZE to be on 6 bits
  -- X"00", -- 000000 NOP
  -- X"01", -- 000001 ADD - SUB - AND - OR
  -- X"00", -- 000010 NOP
  -- X"00", -- 000011 NOP
  -- X"00"
  -- );

  -- Assumption is that if a value 0 is needed is loaded in A or B depending on the
  -- instruction if it require a specific immediate, otherwise the first location of
  -- the register file is loaded in B as it is always 0

  -- Code Words
  -- "0000000000000", --0 op: 000000 NOP
  -- "1111100100111", --1 op: 000001 ADD
  -- "1111101100111", --2 op: 000001 SUB
  -- "1111110100111", --3 op: 000001 AND
  -- "1111111100111", --4 op: 000001 OR
  -- "0110100100111", --5 op: 100000 ADDI1 RS1,RD,INP1
  -- "0110101100111", --6 op: 100001 SUBI1 RS1,RD,INP1
  -- "0110110100111", --7 op: 100010 ANDI1 RS1,RD,INP1
  -- "0110111100111", --8 op: 100011 ORI1 RS1,RD,INP1
  -- "1011000100111", --9 op: 100100 ADDI2 RS1,RD,INP1
  -- "1011001100111", --10 op: 100101 SUBI2 RS1,RD,INP1
  -- "1011010100111", --11 op: 100110 ANDI2 RS1,RD,INP1
  -- "1011011100111", --12 op: 100111 ORI2 RS1,RD,INP1
  -- "1011100100111", --13 op: 101000 MOV RS1,RD,INP1
  -- "0010000100111", --14 op: 101001 SREG1 RS1,RD,INP1
  -- "0010100100111", --15 op: 101010 SREG2 RS1,RD,INP1
  -- "1110100101100", --16 op: 101011 SMEM RS1,RD,INP1
  -- "0110000110101", --17 op: 101100 LMEM1 RS1,RD,INP1
  -- "1011100110101", --18 op: 101101 LMEM2 RS1,RD,INP1

  -- ucode memory (could also implented in another module)
  type ucode_mem_layout is array (0 to ucode_mem_size - 1) of std_logic_vector(CW_SIZE - 1 downto 0);

  -- Codeword Structure
  -- ****************************************************************************
  -- * RF1 * RF2 * EN1 * SA * SB * ALU1 * ALU2 * EN2 * RM * WM * EN3 * S3 * WF1 *
  -- ****************************************************************************

  signal ucode_mem : ucode_mem_layout := (
  "0000000000000", -- uaddr: 00000000 op: 000000 NOP
  "0000000000000", -- uaddr: 00000001 op: 000000 NOP
  "0000000000000", -- uaddr: 00000010 op: 000000 NOP
  "1110000000000", -- uaddr: 00000011 op: 000001 ADD - SUB - AND - OR
  "0001000100000", -- uaddr: 00000100 op: 000001 ADD - SUB - AND - OR
  "0010000000111", -- uaddr: 00000101 op: 000001 ADD - SUB - AND - OR
  "0000000000000", -- uaddr: 00000110 op: 000010 NOP
  "0000000000000", -- uaddr: 00000111 op: 000010 NOP
  "0000000000000", -- uaddr: 00001000 op: 000010 NOP
  "0000000000000", -- uaddr: 00001001 op: 000011 NOP
  "0000000000000", -- uaddr: 00001010 op: 000011 NOP
  "0000000000000", -- uaddr: 00001011 op: 000011 NOP
  "0000000000000", -- uaddr: 00001100 op: 000100 NOP
  "0000000000000", -- uaddr: 00001101 op: 000100 NOP
  "0000000000000", -- uaddr: 00001110 op: 000100 NOP
  "0000000000000", -- uaddr: 00001111 op: 000101 NOP
  "0000000000000", -- uaddr: 00010000 op: 000101 NOP
  "0000000000000", -- uaddr: 00010001 op: 000101 NOP
  "0000000000000", -- uaddr: 00010010 op: 000110 NOP
  "0000000000000", -- uaddr: 00010011 op: 000110 NOP
  "0000000000000", -- uaddr: 00010100 op: 000110 NOP
  "0000000000000", -- uaddr: 00010101 op: 000111 NOP
  "0000000000000", -- uaddr: 00010110 op: 000111 NOP
  "0000000000000", -- uaddr: 00010111 op: 000111 NOP
  "0000000000000", -- uaddr: 00011000 op: 001000 NOP
  "0000000000000", -- uaddr: 00011001 op: 001000 NOP
  "0000000000000", -- uaddr: 00011010 op: 001000 NOP
  "0000000000000", -- uaddr: 00011011 op: 001001 NOP
  "0000000000000", -- uaddr: 00011100 op: 001001 NOP
  "0000000000000", -- uaddr: 00011101 op: 001001 NOP
  "0000000000000", -- uaddr: 00011110 op: 001010 NOP
  "0000000000000", -- uaddr: 00011111 op: 001010 NOP
  "0000000000000", -- uaddr: 00100000 op: 001010 NOP
  "0000000000000", -- uaddr: 00100001 op: 001011 NOP
  "0000000000000", -- uaddr: 00100010 op: 001011 NOP
  "0000000000000", -- uaddr: 00100011 op: 001011 NOP
  "0000000000000", -- uaddr: 00100100 op: 001100 NOP
  "0000000000000", -- uaddr: 00100101 op: 001100 NOP
  "0000000000000", -- uaddr: 00100110 op: 001100 NOP
  "0000000000000", -- uaddr: 00100111 op: 001101 NOP
  "0000000000000", -- uaddr: 00101000 op: 001101 NOP
  "0000000000000", -- uaddr: 00101001 op: 001101 NOP
  "0000000000000", -- uaddr: 00101010 op: 001110 NOP
  "0000000000000", -- uaddr: 00101011 op: 001110 NOP
  "0000000000000", -- uaddr: 00101100 op: 001110 NOP
  "0000000000000", -- uaddr: 00101101 op: 001111 NOP
  "0000000000000", -- uaddr: 00101110 op: 001111 NOP
  "0000000000000", -- uaddr: 00101111 op: 001111 NOP
  "0000000000000", -- uaddr: 00110000 op: 010000 NOP
  "0000000000000", -- uaddr: 00110001 op: 010000 NOP
  "0000000000000", -- uaddr: 00110010 op: 010000 NOP
  "0000000000000", -- uaddr: 00110011 op: 010001 NOP
  "0000000000000", -- uaddr: 00110100 op: 010001 NOP
  "0000000000000", -- uaddr: 00110101 op: 010001 NOP
  "0000000000000", -- uaddr: 00110110 op: 010010 NOP
  "0000000000000", -- uaddr: 00110111 op: 010010 NOP
  "0000000000000", -- uaddr: 00111000 op: 010010 NOP
  "0000000000000", -- uaddr: 00111001 op: 010011 NOP
  "0000000000000", -- uaddr: 00111010 op: 010011 NOP
  "0000000000000", -- uaddr: 00111011 op: 010011 NOP
  "0000000000000", -- uaddr: 00111100 op: 010100 NOP
  "0000000000000", -- uaddr: 00111101 op: 010100 NOP
  "0000000000000", -- uaddr: 00111110 op: 010100 NOP
  "0000000000000", -- uaddr: 00111111 op: 010101 NOP
  "0000000000000", -- uaddr: 01000000 op: 010101 NOP
  "0000000000000", -- uaddr: 01000001 op: 010101 NOP
  "0000000000000", -- uaddr: 01000010 op: 010110 NOP
  "0000000000000", -- uaddr: 01000011 op: 010110 NOP
  "0000000000000", -- uaddr: 01000100 op: 010110 NOP
  "0000000000000", -- uaddr: 01000101 op: 010111 NOP
  "0000000000000", -- uaddr: 01000110 op: 010111 NOP
  "0000000000000", -- uaddr: 01000111 op: 010111 NOP
  "0000000000000", -- uaddr: 01001000 op: 011000 NOP
  "0000000000000", -- uaddr: 01001001 op: 011000 NOP
  "0000000000000", -- uaddr: 01001010 op: 011000 NOP
  "0000000000000", -- uaddr: 01001010 op: 011001 NOP
  "0000000000000", -- uaddr: 01001011 op: 011001 NOP
  "0000000000000", -- uaddr: 01001100 op: 011001 NOP
  "0000000000000", -- uaddr: 01001101 op: 011010 NOP
  "0000000000000", -- uaddr: 01001110 op: 011010 NOP
  "0000000000000", -- uaddr: 01001111 op: 011010 NOP
  "0000000000000", -- uaddr: 01010000 op: 011011 NOP
  "0000000000000", -- uaddr: 01010001 op: 011011 NOP
  "0000000000000", -- uaddr: 01010010 op: 011011 NOP
  "0000000000000", -- uaddr: 01010011 op: 011100 NOP
  "0000000000000", -- uaddr: 01010100 op: 011100 NOP
  "0000000000000", -- uaddr: 01010101 op: 011100 NOP
  "0000000000000", -- uaddr: 01010110 op: 011101 NOP
  "0000000000000", -- uaddr: 01010111 op: 011101 NOP
  "0000000000000", -- uaddr: 01011000 op: 011101 NOP
  "0000000000000", -- uaddr: 01011001 op: 011110 NOP
  "0000000000000", -- uaddr: 01011010 op: 011110 NOP
  "0000000000000", -- uaddr: 01011011 op: 011110 NOP
  "0000000000000", -- uaddr: 01011100 op: 011111 NOP
  "0000000000000", -- uaddr: 01011101 op: 011111 NOP
  "0000000000000", -- uaddr: 01011110 op: 011111 NOP
  "0110000000000", -- uaddr: 01011111 op: 100000 ADDI1 RS1,RD,INP1
  "0000000100000", -- uaddr: 01100000 op: 100000 ADDI1 RS1,RD,INP1
  "0010000000111", -- uaddr: 01100001 op: 100000 ADDI1 RS1,RD,INP1
  "0110000000000", -- uaddr: 01100010 op: 100001 SUBI1 RS1,RD,INP1
  "0000001100000", -- uaddr: 01100011 op: 100001 SUBI1 RS1,RD,INP1
  "0010000000111", -- uaddr: 01100100 op: 100001 SUBI1 RS1,RD,INP1
  "0110000000000", -- uaddr: 01100101 op: 100010 ANDI1 RS1,RD,INP1
  "0000010100000", -- uaddr: 01100110 op: 100010 ANDI1 RS1,RD,INP1
  "0010000000111", -- uaddr: 01100111 op: 100010 ANDI1 RS1,RD,INP1
  "0110000000000", -- uaddr: 01101000 op: 100011 ORI1 RS1,RD,INP1
  "0000011100000", -- uaddr: 01101001 op: 100011 ORI1 RS1,RD,INP1
  "0010000000111", -- uaddr: 01101010 op: 100011 ORI1 RS1,RD,INP1
  "1010000000000", -- uaddr: 01101011 op: 100100 ADDI2 RS1,RD,INP2
  "0001100100000", -- uaddr: 01101100 op: 100100 ADDI2 RS1,RD,INP2
  "0010000000111", -- uaddr: 01101101 op: 100100 ADDI2 RS1,RD,INP2
  "1010000000000", -- uaddr: 01101110 op: 100101 SUBI2 RS1,RD,INP2
  "0001101100000", -- uaddr: 01101111 op: 100101 SUBI2 RS1,RD,INP2
  "0010000000111", -- uaddr: 01110000 op: 100101 SUBI2 RS1,RD,INP2
  "1010000000000", -- uaddr: 01110001 op: 100110 ANDI2 RS1,RD,INP2
  "0001110100000", -- uaddr: 01110010 op: 100110 ANDI2 RS1,RD,INP2
  "0010000000111", -- uaddr: 01110011 op: 100110 ANDI2 RS1,RD,INP2
  "1010000000000", -- uaddr: 01110100 op: 100111 ORI2 RS1,RD,INP2
  "0001111100000", -- uaddr: 01110101 op: 100111 ORI2 RS1,RD,INP2
  "0010000000111", -- uaddr: 01110110 op: 100111 ORI2 RS1,RD,INP2
  "1110000000000", -- uaddr: 01110111 op: 101000 MOV RS1,RD
  "0001000100000", -- uaddr: 01111000 op: 101000 MOV RS1,RD
  "0010000000111", -- uaddr: 01111001 op: 101000 MOV RS1,RD
  "0110000000000", -- uaddr: 01111010 op: 101001 SREG1 RS1,RD,INP1
  "0000000100000", -- uaddr: 01111011 op: 101001 SREG1 RS1,RD,INP1
  "0010000000111", -- uaddr: 01111100 op: 101001 SREG1 RS1,RD,INP1
  "1010000000000", -- uaddr: 01111101 op: 101010 SREG2 RS1,RD,INP2
  "0000100100000", -- uaddr: 01111110 op: 101010 SREG2 RS1,RD,INP2
  "0010000000111", -- uaddr: 01111111 op: 101010 SREG2 RS1,RD,INP2
  "1110000000000", -- uaddr: 10000000 op: 101011 SMEM RS1,RD,INP2
  "0001100100000", -- uaddr: 10000001 op: 101011 SMEM RS1,RD,INP2
  "0000000001100", -- uaddr: 10000010 op: 101011 SMEM RS1,RD,INP2
  "0110000000000", -- uaddr: 10000011 op: 101100 LMEM1 RS1,RD,INP1
  "0000000100000", -- uaddr: 10000100 op: 101100 LMEM1 RS1,RD,INP1
  "0010000010101", -- uaddr: 10000101 op: 101100 LMEM1 RS1,RD,INP1
  "1010000000000", -- uaddr: 10000110 op: 101101 LMEM2 RS1,RD,INP2
  "0001100100000", -- uaddr: 10000111 op: 101101 LMEM2 RS1,RD,INP2
  "0010000010101", -- uaddr: 10001000 op: 101101 LMEM2 RS1,RD,INP2
  "0000000000000", -- uaddr: 10001001 op: 101110 NOP
  "0000000000000", -- uaddr: 10001010 op: 101110 NOP
  "0000000000000", -- uaddr: 10001011 op: 101110 NOP
  "0000000000000", -- uaddr: 10001100 op: 101111 NOP
  "0000000000000", -- uaddr: 10001101 op: 101111 NOP
  "0000000000000", -- uaddr: 10001110 op: 101111 NOP
  "0000000000000", -- uaddr: 10001111 op: 110000 NOP
  "0000000000000", -- uaddr: 10010000 op: 110000 NOP
  "0000000000000", -- uaddr: 10010001 op: 110000 NOP
  "0000000000000", -- uaddr: 10010010 op: 110001 NOP
  "0000000000000", -- uaddr: 10010011 op: 110001 NOP
  "0000000000000", -- uaddr: 10010100 op: 110001 NOP
  "0000000000000", -- uaddr: 10010101 op: 110010 NOP
  "0000000000000", -- uaddr: 10010110 op: 110010 NOP
  "0000000000000", -- uaddr: 10010111 op: 110010 NOP
  "0000000000000", -- uaddr: 10011000 op: 110011 NOP
  "0000000000000", -- uaddr: 10011001 op: 110011 NOP
  "0000000000000", -- uaddr: 10011010 op: 110011 NOP
  "0000000000000", -- uaddr: 10011011 op: 110100 NOP
  "0000000000000", -- uaddr: 10011100 op: 110100 NOP
  "0000000000000", -- uaddr: 10011101 op: 110100 NOP
  "0000000000000", -- uaddr: 10011110 op: 110101 NOP
  "0000000000000", -- uaddr: 10011111 op: 110101 NOP
  "0000000000000", -- uaddr: 10100000 op: 110101 NOP
  "0000000000000", -- uaddr: 10100001 op: 110110 NOP
  "0000000000000", -- uaddr: 10100010 op: 110110 NOP
  "0000000000000", -- uaddr: 10100011 op: 110110 NOP
  "0000000000000", -- uaddr: 10100100 op: 110111 NOP
  "0000000000000", -- uaddr: 10100101 op: 110111 NOP
  "0000000000000", -- uaddr: 10100110 op: 110111 NOP
  "0000000000000", -- uaddr: 10100111 op: 111000 NOP
  "0000000000000", -- uaddr: 10101000 op: 111000 NOP
  "0000000000000", -- uaddr: 10101001 op: 111000 NOP
  "0000000000000", -- uaddr: 10101010 op: 111001 NOP
  "0000000000000", -- uaddr: 10101011 op: 111001 NOP
  "0000000000000", -- uaddr: 10101100 op: 111001 NOP
  "0000000000000", -- uaddr: 10101101 op: 111010 NOP
  "0000000000000", -- uaddr: 10101110 op: 111010 NOP
  "0000000000000", -- uaddr: 10101111 op: 111010 NOP
  "0000000000000", -- uaddr: 10110000 op: 111011 NOP
  "0000000000000", -- uaddr: 10110001 op: 111011 NOP
  "0000000000000", -- uaddr: 10110010 op: 111011 NOP
  "0000000000000", -- uaddr: 10110011 op: 111100 NOP
  "0000000000000", -- uaddr: 10110100 op: 111100 NOP
  "0000000000000", -- uaddr: 10110101 op: 111100 NOP
  "0000000000000", -- uaddr: 10110110 op: 111101 NOP
  "0000000000000", -- uaddr: 10110111 op: 111101 NOP
  "0000000000000", -- uaddr: 10111000 op: 111101 NOP
  "0000000000000", -- uaddr: 10111001 op: 111110 NOP
  "0000000000000", -- uaddr: 10111010 op: 111110 NOP
  "0000000000000", -- uaddr: 10111011 op: 111110 NOP
  "0000000000000", -- uaddr: 10111100 op: 111111 NOP
  "0000000000000", -- uaddr: 10111101 op: 111111 NOP
  "0000000000000" -- uaddr: 10111110 op: 111111 NOP
  );

  type STAR_type is (S0, S1);
  signal STAR                              : STAR_type;
  signal U_ADDR, next_u_addr, reloc_u_addr : std_logic_vector(integer(ceil(log2(real(ucode_mem_size)))) - 1 downto 0);
  signal COUNTER                           : std_logic_vector(1 downto 0);
  signal CONTROL_WORD                      : std_logic_vector(CW_SIZE - 1 downto 0);

begin

  -- The address relocation is to compute OPCODE * OP_CLOCK_NEEDED, this could be slow, thus a LUT is used to
  -- compute the correct address. After the relocation the address is extended to have a coherent address size for the
  -- ucode memory. For example if the pipeline stages (thus OP_CLOCK_NEEDED) were a power of 2 then only a shift is needed

  reloc_u_addr <= base_addr_tr(to_integer(unsigned(opcode)));

  -- The next address is computed here, it is only to describe that beetween the rising clock edges
  -- the adder is computing the next value. This could also be done inside the cloked process
  -- but by doing UADDR <= UADDR + 1
  next_u_addr <= std_logic_vector(unsigned(U_ADDR) + 1);

  -- The U_ADDR is used directly to address the umemory
  CONTROL_WORD <= ucode_mem(to_integer(unsigned(U_ADDR)));

  -- Codeword Structure
  -- ****************************************************************************
  -- * RF1 * RF2 * EN1 * S1 * S2 * ALU1 * ALU2 * EN2 * RM * WM * EN3 * S3 * WF1 *
  -- ****************************************************************************

  -- Stage 1
  rf_rd1 <= CONTROL_WORD(CW_SIZE - 1);
  rf_rd2 <= CONTROL_WORD(CW_SIZE - 2);
  en_1   <= CONTROL_WORD(CW_SIZE - 3);
  -- Stage 2
  s_a <= CONTROL_WORD(CW_SIZE - 4);
  s_b <= CONTROL_WORD(CW_SIZE - 5);
  -- As stated above the function bits are used directly to drive the  ALU unit to
  -- save memory space in the umemory. This is done only when the instruction is a R-Type
  -- OPCODE = 00 ... 0001;

  -- the last condition depends on which phase is the ALU
  -- in our case in the second stage
  alu_op <= func when opcode = RTYPE and STAR = S1 and to_integer(unsigned(COUNTER)) = 1 else
    CONTROL_WORD(CW_SIZE - 6 downto CW_SIZE - 7);
  en_2 <= CONTROL_WORD(CW_SIZE - 8);
  -- Stage 3
  mr   <= CONTROL_WORD(CW_SIZE - 9);
  mw   <= CONTROL_WORD(CW_SIZE - 10);
  en_3 <= CONTROL_WORD(CW_SIZE - 11);
  s_am <= CONTROL_WORD(CW_SIZE - 12);
  wrf  <= CONTROL_WORD(CW_SIZE - 13);

  process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        STAR    <= S0;
        U_ADDR  <= (others => '0');
        COUNTER <= std_logic_vector(to_unsigned(OP_CLOCK_NEEDED - 1, COUNTER'length));
      else
        case STAR is
          when S0 =>
            -- Sample the new OPCODE and start a loop to sweep through 3 memory locations
            U_ADDR  <= reloc_u_addr;
            COUNTER <= std_logic_vector(to_unsigned(OP_CLOCK_NEEDED - 1, COUNTER'length));
            STAR    <= S1;

          when S1 =>
            -- Here we swees all the needed memory locations of the umemory
            -- to output the correct CW
            U_ADDR  <= next_u_addr;
            COUNTER <= std_logic_vector(unsigned(COUNTER) - 1);

            if to_integer(unsigned(COUNTER)) = 1 then
              STAR <= S0;
            else
              STAR <= S1;
            end if;

          when others =>
            STAR <= S0;
        end case;
      end if;
    end if;
  end process;

end architecture;