library ieee;
use ieee.std_logic_1164.all;
use work.myTypes.all;
use WORK.alu_types.all;
entity DLX is
  generic (
    IR_SIZE  : integer := 32; -- Instruction Register Size
    FUN_SIZE : integer := 11; -- Func Field Size for R-Type Ops
    PC_SIZE  : integer := 32 -- Program Counter Size
  ); -- ALU_OPC_SIZE if explicit ALU Op Code Word Size
  port (
    clk : in std_logic;
    rst : in std_logic); -- Active Low
end DLX;

architecture dlx_rtl of DLX is

  --------------------------------------------------------------------
  -- Components Declaration
  --------------------------------------------------------------------

  component control_unit is
    generic (
      MICROCODE_MEM_SIZE : integer := 10; -- Microcode Memory Size
      FUN_SIZE           : integer := FUN_SIZE; -- Func Field Size for R-Type Ops
      OP_CODE_SIZE       : integer := 6; -- Op Code Size
      IR_SIZE            : integer := IR_SIZE; -- Instruction Register Size    
      CW_SIZE            : integer := 15
    ); -- Control Word Size
    port (
      clk   : in std_logic; -- Clock
      reset : in std_logic; -- Reset:Active-Low

      -- Instruction Register
      IR_IN : in std_logic_vector(IR_SIZE - 1 downto 0);

      fetch_enable      : out std_logic; -- Fetch Enable Signal
      decode_enable     : out std_logic; -- Decode Enable Signal
      execute_enable    : out std_logic; -- Execute Enable Signal
      memory_enable     : out std_logic; -- Write Back Enable Signal
      write_back_enable : out std_logic; -- Write Back Enable Signal

      -- IF Control Signal
      RF_EN   : out std_logic; -- Instruction Register Latch Enable
      RF_re_1 : out std_logic; -- Instruction Register 1 Read Enable
      RF_re_2 : out std_logic; -- Instruction Register 2 Read Enable
      RF_we   : out std_logic; -- Instruction Register Write Enable 

      source_select_1 : out std_logic; -- Source Select Signal for ALU
      source_select_2 : out std_logic; -- Source Select Signal for ALU
      ALU_op          : out std_logic_vector(FUN_SIZE - 1 downto 0); -- ALU Operation Code
      DRAM_enable     : out std_logic; -- DRAM Enable Signal
      DRAM_WE         : out std_logic; -- DRAM Write Enable Signal
      DRAM_RE         : out std_logic; -- DRAM Read Enable Signal
      source_select_3 : out std_logic; -- Source Select Signal for Memory Stage

      inst_type_out : out std_logic_vector(1 downto 0); -- Instruction Type (R, I, J)
      opcode_out    : out std_logic_vector(OP_CODE_SIZE - 1 downto 0) -- Op Code of the Instruction
    );
  end component control_unit;
  component datapath is
    generic (
      I_SIZE       : integer := 32; -- Size of instruction in bits
      OPERAND_SIZE : integer := 32; -- Size operands in bits
      NUM_REG      : integer := 5; -- Number of registers in bits (log_2(RF_SIZE))
      FUN_SIZE     : integer := 11 -- Number of registers in bits (log_2(RF_SIZE))
    );
    port (
      -- DLX Processor signals
      clk   : in std_logic; -- Clock signal
      reset : in std_logic; -- Reset signal

      -- Control unit signals
      fetch_enable      : in std_logic; -- Output registers enable signal
      decode_enable     : in std_logic; -- Output registers enable signal
      execute_enable    : in std_logic; -- Output registers enable signal
      memory_enable     : in std_logic; -- Output registers enable signal
      write_back_enable : in std_logic; -- Output registers enable signal

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
      source_3_select : in std_logic; -- Source select signal for memory stage (MEM/ALU) -- could be replaced by DRAM_enable

      inst_type : in std_logic_vector(1 downto 0); -- Instruction type (R-type, I-type, J-type)
      opcode    : in std_logic_vector(5 downto 0); -- Opcode of the instruction

      IR_out : out std_logic_vector(I_SIZE - 1 downto 0) -- Instruction register (for the CU)
    );
  end component datapath;
  ----------------------------------------------------------------
  -- Signals Declaration
  ----------------------------------------------------------------
  -- Instruction Register
  signal IR                : std_logic_vector(IR_SIZE - 1 downto 0);
  signal fetch_enable      : std_logic; -- Fetch Enable Signal
  signal decode_enable     : std_logic; -- Decode Enable Signal
  signal execute_enable    : std_logic; -- Execute Enable Signal
  signal memory_enable     : std_logic; -- Write Back Enable Signal
  signal write_back_enable : std_logic; -- Write Back Enable Signal
  -- IF Control Signal
  signal RF_EN   : std_logic; -- Instruction Register Latch Enable
  signal RF_re_1 : std_logic; -- Instruction Register 1 Read Enable
  signal RF_re_2 : std_logic; -- Instruction Register 2 Read Enable
  signal RF_we   : std_logic; -- Instruction Register Write Enable 

  signal source_select_1 : std_logic; -- Source Select Signal for ALU
  signal source_select_2 : std_logic; -- Source Select Signal for ALU
  signal ALU_op          : std_logic_vector(FUN_SIZE - 1 downto 0); -- ALU Operation Code
  signal DRAM_enable     : std_logic; -- DRAM Enable Signal
  signal DRAM_WE         : std_logic; -- DRAM Write Enable Signal
  signal DRAM_RE         : std_logic; -- DRAM Read Enable Signal
  signal source_select_3 : std_logic; -- Source Select Signal for Memory Stage

  signal inst_type : std_logic_vector(1 downto 0); -- Instruction Type (R, I, J)
  signal opcode    : std_logic_vector(OP_CODE_SIZE - 1 downto 0); -- Op Code of the Instruction

  -- Data Ram Bus signals
begin -- DLX

  --------------------------------------------------------------------
  -- Components Instantiation
  --------------------------------------------------------------------

  CU_inst : control_unit
  generic map(
    MICROCODE_MEM_SIZE => 10, -- Microcode Memory Size
    FUN_SIZE           => 11, -- Func Field Size for R-Type Ops
    OP_CODE_SIZE       => 6, -- Op Code Size
    IR_SIZE            => IR_SIZE, -- Instruction Register Size    
    CW_SIZE            => 15 -- Control Word Size
  )
  port map
  (
    clk   => clk,
    reset => rst,

    IR_IN => IR,

    fetch_enable      => fetch_enable,
    decode_enable     => decode_enable,
    execute_enable    => execute_enable,
    memory_enable     => memory_enable,
    write_back_enable => write_back_enable,

    RF_EN   => RF_en,
    RF_re_1 => RF_re_1,
    RF_re_2 => RF_re_2,
    RF_we   => RF_we,

    source_select_1 => source_select_1,
    source_select_2 => source_select_2,
    ALU_op          => ALU_op,
    DRAM_enable     => DRAM_enable,
    DRAM_WE         => DRAM_WE,
    DRAM_RE         => DRAM_RE,
    source_select_3 => source_select_3,

    inst_type_out => inst_type,
    opcode_out    => opcode
  );

  -- Datapath Instantiation
  datapath_inst : entity work.datapath
    generic map(
      I_SIZE       => IR_SIZE, -- Size of instruction in bits
      OPERAND_SIZE => 32, -- Size operands in bits
      NUM_REG      => 5, -- Number of registers in bits (log_2(RF_SIZE))
      FUN_SIZE     => 11 -- Number of registers in bits (log_2(RF_SIZE))
    )
    port map
    (
      clk   => clk,
      reset => rst,

      fetch_enable      => fetch_enable,
      decode_enable     => decode_enable,
      execute_enable    => execute_enable,
      memory_enable     => memory_enable,
      write_back_enable => write_back_enable,
      -- Decode stage signals
      RF_en => RF_EN, -- Register file enable signal
      -- Operand 1
      RF_re_1 => RF_re_1, -- Register file read enable for source 1 register
      -- Operand 2
      RF_re_2 => RF_re_2, -- Register file read enable for source 2 register
      -- Register file write signals
      RF_we => RF_we, -- Register file write enable
      -- Execute stage signals
      source_1_select => source_select_1, -- Source 1 select signal
      source_2_select => source_select_2, -- Source 2 select signal
      ALU_op          => ALU_op, -- ALU operation code input
      -- Memory stage signals
      DRAM_enable     => DRAM_enable, -- DRAM enable signal
      DRAM_RE         => DRAM_RE, -- DRAM read enable signal
      DRAM_WE         => DRAM_WE, -- DRAM write enable signal
      source_3_select => source_select_3, -- Source select signal for memory stage (MEM/ALU) -- could be replaced by DRAM_enable
      inst_type       => inst_type, -- Instruction type (R-type, I-type, J-type)
      opcode          => opcode, -- Opcode of the instruction
      IR_out          => IR -- Instruction register (for the CU)
    );

end dlx_rtl;
