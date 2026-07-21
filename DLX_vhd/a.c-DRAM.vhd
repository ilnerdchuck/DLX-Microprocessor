--==============================================================================
--  Project     : DLX Processor Implementation
--  File        : a.c_DRAM.vhd
--  Description : VHDL testbench to test a DRAM module.
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
use std.textio.all;
use ieee.math_real.all;
use ieee.std_logic_textio.all;
--==============================================================================
entity DRAM is
  generic (
    DATA_SIZE : integer := 32; -- Size of instruction in bits
    RAM_DEPTH : integer := 48 -- Number of instructions in the memory, TODO: should be the power of 2^DATA_SIZE if no caching is used
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

end DRAM;

architecture DRAM_Bhe of DRAM is

  type RAMtype is array (RAM_DEPTH - 1 downto 0) of std_logic_vector(DATA_SIZE - 1 downto 0);

  signal DRAM_mem : RAMtype;

begin -- DRAM_Bhe

  process (rst, re, we, Addr, data_in) is
  begin -- process FILL_MEM_P
    if (rst = '1') then
      for i in RAM_DEPTH - 1 downto 0 loop
        DRAM_mem(i) <= (others => '0'); -- Initialize memory to zero on reset
      end loop;
    else
      if re = '1' then
        data_out <= DRAM_mem(to_integer(unsigned(Addr))); -- Read data from memory when read enable is high
      end if;
      if we = '1' then
        DRAM_mem(to_integer(unsigned(Addr))) <= data_in; -- Write data to memory when write enable is high
      end if;
    end if;
  end process;

end DRAM_Bhe;
