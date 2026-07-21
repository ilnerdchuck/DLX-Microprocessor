--==============================================================================
--  Project     : DLX Processor Implementation
--  File        : a.b_execute.vhd
--  Description : VHDL design of a execute unit.
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
entity execute_stage is
  generic (
    OPERAND_SIZE : integer := 32; -- Size operands in bits
    NUM_REG      : integer := 5; -- Number of registers in bits (log_2(RF_SIZE))
    FUN_SIZE     : integer := 11 -- ALU function size in bits 
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
    PC_in  : in std_logic_vector(OPERAND_SIZE - 1 downto 0); -- PC input (Program Counter) (for jump instructions)
    A      : in std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Operand A input
    B      : in std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Operand B input
    IMM_in : in std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Immediate 2 value input

    alu_out : out std_logic_vector(OPERAND_SIZE - 1 downto 0); -- ALU result output

    MEM_data_out : out std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Memory data output (B source bypass for memory operations)
    -- Register file signals
    RD_in  : in std_logic_vector(NUM_REG - 1 downto 0); -- Register file write address for destination register input
    RD_out : out std_logic_vector(NUM_REG - 1 downto 0); -- Register file write address for destination register output (conenct directly to decode stage)

    -- Forwarding signals
    -- 00: no forwarding, 01: forward from MEM stage, 11: forward from WB stage
    fwd_A : in std_logic_vector(1 downto 0); -- Forwarded value for source A operand
    fwd_B : in std_logic_vector(1 downto 0); -- Forwarded value for source B operand

    RS_wb : in std_logic_vector(OPERAND_SIZE - 1 downto 0) -- Data Forwarded from Write Back stage (WB stage)
  );
end execute_stage;
--==============================================================================
architecture Behavioral of execute_stage is

  signal source_1 : std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Selected source 1 operand
  signal source_2 : std_logic_vector(OPERAND_SIZE - 1 downto 0); -- Selected source 2 operand
  signal a_fw     : std_logic_vector(OPERAND_SIZE - 1 downto 0);
  signal b_fw     : std_logic_vector(OPERAND_SIZE - 1 downto 0);
  signal result   : std_logic_vector(OPERAND_SIZE - 1 downto 0); -- ALU output signal

begin
  -- TODO: Use p4 adder, booth multiplier, and T2 shifter (this if we have time to implement them)

  -- Forwarding logic for source 1 operand
  a_fw <= A when fwd_A = "00" else
    result when fwd_A = "01" else
    RS_wb; -- Forwarded value for source 1 operand

  -- Forwarding logic for source 2 operand
  b_fw <= B when fwd_B = "00" else
    result when fwd_B = "01" else
    RS_wb; -- Forwarded value for source 2 operand

  source_1 <= a_fw when source_1_select = '0' else
    PC_in when source_1_select = '1' else
    (others => '0'); -- Select source 1 operand

  source_2 <= b_fw when source_2_select = '0' else
    IMM_in when source_2_select = '1' else
    (others => '0'); -- Select source 2 operand

  alu_out <= result; -- Assert ALU output
  EXECUTE_PROCESS : process (clk, reset)
  begin
    if reset = '1' then
      result       <= (others => '0'); -- Reset result to zero
      MEM_data_out <= (others => '0'); -- Reset memory data output to zero
      RD_out       <= (others => '0'); -- Reset register file data output to zero

    elsif rising_edge(clk) then
      if stage_enable = '1' then
        if alu_op = RTYPE_ADD then
          result <= std_logic_vector(signed(source_1) + signed(source_2)); -- ADD operation
        elsif alu_op = RTYPE_SUB then
          result <= std_logic_vector(signed(source_1) - signed(source_2)); -- SUB operation
        elsif alu_op = RTYPE_AND then
          result <= source_1 and source_2; -- AND operation
        elsif alu_op = RTYPE_OR then
          result <= source_1 or source_2; -- OR operation
        elsif alu_op = RTYPE_XOR then
          result <= source_1 xor source_2; -- XOR operation
        elsif alu_op = RTYPE_SLL then
          result <= std_logic_vector(shift_left(unsigned(source_1), to_integer(unsigned(source_2)))); -- SLL (Shift Left Logical)
        elsif alu_op = RTYPE_SRL then
          result <= std_logic_vector(shift_right(unsigned(source_1), to_integer(unsigned(source_2)))); -- SRL (Shift Right Logical)
        elsif alu_op = RTYPE_SNE then -- SNE (Set Not Equal)
          if unsigned(source_1) /= unsigned(source_2) then
            result <= std_logic_vector(to_signed(1, result'length));
          else
            result <= (others => '0');
          end if;
        elsif alu_op = RTYPE_SLE then -- SLE (Set Less Than or Equal)
          if unsigned(source_1) <= unsigned(source_2) then
            result                <= std_logic_vector(to_signed(1, result'length));
          else
            result <= (others => '0');
          end if;
        elsif alu_op = RTYPE_SGE then -- SGE (Set Greater Than or Equal)
          if unsigned(source_1) >= unsigned(source_2) then
            result <= std_logic_vector(to_signed(1, result'length));
          else
            result <= (others => '0');
          end if;
        else
          result <= (others => '0'); -- Default case, reset result
        end if;
        -- case alu_op_int is
        --   when RTYPE_ADD => -- ADD
        --     result <= std_logic_vector(unsigned(source_1) + unsigned(source_2));
        --   when RTYPE_SUB => -- SUB
        --     result <= std_logic_vector(unsigned(source_1) - unsigned(source_2));
        --   when RTYPE_AND => -- AND
        --     result <= source_1 and source_2;
        --   when RTYPE_OR => -- OR
        --     result <= source_1 or source_2;
        --   when RTYPE_XOR => -- XOR
        --     result <= source_1 xor source_2;
        --   when RTYPE_SLL => -- SLL (Shift Left Logical)
        --     result <= std_logic_vector(shift_left(unsigned(source_1), to_integer(unsigned(source_2))));
        --   when RTYPE_SRL => -- SRL (Shift Right Logical)
        --     result <= std_logic_vector(shift_right(unsigned(source_1), to_integer(unsigned(source_2))));
        --   when RTYPE_SNE => -- SNE (Set Not Equal)
        --     if unsigned(source_1) /= unsigned(source_2) then
        --       result <= std_logic_vector(to_signed(1, result'length));
        --     else
        --       result <= (others => '0');
        --     end if;
        --   when RTYPE_SLE => -- SLE (Set Less Than)
        --     if unsigned(source_1) <= unsigned(source_2) then
        --       result                <= std_logic_vector(to_signed(1, result'length));
        --     else
        --       result <= (others => '0');
        --     end if;
        --   when RTYPE_SGE => -- SGE (Set Greater Than)
        --     if unsigned(source_1) >= unsigned(source_2) then
        --       result <= std_logic_vector(to_signed(1, result'length));
        --     else
        --       result <= (others => '0');
        --     end if;
        --   when others       =>
        --     result <= (others => '0'); -- Default case, reset result
        -- end case;
        RD_out       <= RD_in; -- Assert register file write address for destination register
        MEM_data_out <= b_fw; -- Assert memory data output (for memory operations)
      end if;
    end if;
  end process;

end Behavioral;
--==============================================================================
