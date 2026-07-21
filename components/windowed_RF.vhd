library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.constants.all;

-- Read the README.txt or README.pdf as there is all the informations on on the implementation
entity windowed_RF is
  generic (
    NBit    : integer := numBit; -- number of bit per memory locaiton
    NReg    : integer := NumReg; -- number of registers per IN,LOCAL, I/O, GLOBAL
    NWindow : integer := numWindow -- number of windows
  );
  port (
    clk, reset, enable                    : in std_logic;
    write_rq, mem_write_rq                : in std_logic; -- to handle write requests from the cpu
    call                                  : in std_logic; -- to handle a call of a subroutine thus the new window
    ret                                   : in std_logic; -- to handle a return of a subroutine thus the old window
    rd_rq_1                               : in std_logic; -- ALU read request 1
    rd_rq_2                               : in std_logic; -- ALU read request 2
    addr_cpu                              : in std_logic_vector(integer(ceil(log2(real((3 * NReg) + (NWindow * NReg))))) - 1 downto 0);
    addr_read_1, addr_read_2, mem_addr_in : in std_logic_vector(integer(ceil(log2(real(3 * NReg * NWindow)))) - 1 downto 0); -- used from the ALU to read the operands from the register file
    data_in, data_mem_in                  : in std_logic_vector(NBit - 1 downto 0); -- data input form the spu and the memory for the fill
    data_out_1, data_out_2, data_mem_out  : out std_logic_vector(NBit - 1 downto 0) -- output operands for the alu and the data that needs to be spilled in memory

  );
end entity;

architecture rtl of windowed_RF is

  constant active_window_bits : integer := integer(ceil(log2(real((3 * NReg) + (NWindow * NReg)))));
  constant RF_addr_bits       : integer := integer(ceil(log2(real(3 * NReg * NWindow))));
  constant window_bits        : integer := integer(ceil(log2(real(NWindow))));
  constant reg_page_size      : integer := integer(ceil(log2(real(2 * NReg))));

  component register_file is
    generic (
      NBit : integer := NBit; -- number of bit per register
      NReg : integer := (3 * NReg * NWindow) -- number of registers
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
  end component;
  type STAR_TYPE is (S0, S1, S2);
  -- S0:  Idle
  -- S1:  Spill
  -- S2:  Fill
  signal STAR : STAR_TYPE;

  signal CAN_SAVE, CAN_RESTORE  : std_logic;
  signal CWP, O_CWP, N_CWP, SWP : std_logic_vector(window_bits - 1 downto 0); -- counter for the high part of the address of the currrent window and swap window
  signal RF_ADDR                : std_logic_vector(RF_addr_bits - 1 downto 0);
  signal RF_WR_RQ               : std_logic;
  signal RF_DATA_IN             : std_logic_vector(NBit - 1 downto 0);
  signal RF_ADDR_VALUE          : std_logic_vector(RF_addr_bits - 1 downto 0);

  -- the managing of the address is done like in paging, thus we keep a counter of the current page/window with a size of 16 (or 2*Nregs)
  -- memory locations, this allows us to increase/decrease only the counters as needed only in the spill/fill situations. Thus this organizations 
  -- doesn't need an adder for the actual address computation but only concatenations of the correct bits
  -- IN/LOCAL registers 
  -- | 0 |  CWP  | addr(log_2(2*Nregs) downto 0) |
  -- I/O registers
  -- | 0 |  N_CWP  | addr(log_2(2*Nregs) downto 0) |
  -- Globals
  -- | 1 | addr |

  -- SWP keeps track of the window that is currently not swapped thus is NOT the actual address, for the actual address it should be added
  -- trailng zeros as the log_2(2*Numregs)
  -- | 0 |  SWP  | 000000 |

begin
  REG_FILE : register_file
  generic map(
    NBit => NBit, -- number of bit per register
    NReg => 3 * NReg * NWindow -- number of registers
  )
  port map
  (
    CLK     => clk, -- Clock Signal
    RESET   => reset, -- Reset Signal
    ENABLE  => '1', -- Enable Signal
    RD1     => rd_rq_1, -- Read 1 Signal
    RD2     => rd_rq_2, -- Read 2 Signal
    WR      => RF_WR_RQ, -- Write Signal
    ADD_WR  => RF_ADDR, -- Write Address
    ADD_RD1 => addr_read_1, -- Read 1 Address
    ADD_RD2 => addr_read_2, -- Read 2 Address
    DATAIN  => RF_DATA_IN, -- Data in Signal
    OUT1    => data_out_1, -- Data Out 1 Signal
    OUT2    => data_out_2 -- Data Out 2 Signal
  );

  -- If the register file is not in the state S0 thus the memory needs to control the data lines to spill and fill to/from 
  -- memory
  RF_ADDR <= RF_ADDR_VALUE when STAR = S0 else
    mem_addr_in;
  RF_WR_RQ <= write_rq when STAR = S0 else
    mem_write_rq;
  RF_DATA_IN <= data_in when STAR = S0 else
    data_mem_in;

  -- Logic to filter the address from the producer that intecarts with the ACTIVE WINDOW
  process (write_rq, addr_cpu, data_in)
    variable RF_ADDR_TMP : std_logic_vector(RF_addr_bits - 1 downto 0);
  begin
    -- if the MSB is 1 then the request is for the IN/LOCAL/IO sections 
    if addr_cpu(active_window_bits - 1) = '1' then
      if addr_cpu(active_window_bits - 2 downto active_window_bits - 3) = "01" then
        -- The producer requests the IO portion of the active window thus i need to use the CWP+1
        -- as the next INPUT portion is part of the next window
        RF_ADDR_TMP := '0' & N_CWP & addr_cpu(reg_page_size - 1 downto 0);
      elsif addr_cpu(active_window_bits - 2 downto active_window_bits - 3) = "00" then
        -- The producer requests the INPUT or LOCAL portion of memory 
        -- thus we need to concatenate the CWP
        RF_ADDR_TMP := '0' & CWP & addr_cpu(reg_page_size - 1 downto 0);
      else
        RF_ADDR_TMP := (others => 'Z'); -- address not valid
      end if;

    else
      -- The CPU is accessing the globals section
      RF_ADDR_TMP := '1' & addr_cpu;
    end if;
    RF_ADDR_VALUE <= RF_ADDR_TMP;
  end process;

  -- The control part checks every time as the window moves back and forward 
  -- if there is space available to avoid spilling or filling from memory
  CAN_SAVE <= '0' when (unsigned(N_CWP) + 1) = unsigned(SWP) else
    '1';
  CAN_RESTORE <= '0' when (unsigned(CWP)) = unsigned(SWP) else
    '1';

  process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        STAR  <= S0;
        O_CWP <= (others => '1');
        CWP   <= (others => '0');
        N_CWP <= (0 => '1', others => '0');
        SWP   <= (others => '0');
      else
        case STAR is
          when S0 =>
            -- "S0": Base State
            if call = '1' then
              if CAN_SAVE = '1' then
                -- New Window without spill
                O_CWP <= CWP;
                CWP   <= N_CWP;
                N_CWP <= std_logic_vector(unsigned(N_CWP) + 1);

              elsif CAN_SAVE = '0' then
                -- Spill needed to move the window
                STAR <= S1;

              end if;
            elsif ret = '1' then
              if CAN_RESTORE = '1' then
                -- Old Window without fill
                O_CWP <= std_logic_vector(unsigned(N_CWP) - 1);
                CWP   <= O_CWP;
                N_CWP <= CWP;

              elsif CAN_RESTORE = '0' then
                -- Fill needed to restore the previous context
                STAR <= S2;

              end if;
            end if;

          when S1 =>
            -- "S1":  Spill
            -- spill logic for the memory
            -- like push to the stack 16 memory locations (one per clock cycle) 
            -- or even faster push more locations at a time, but need to modify 
            -- heavly the bus

            -- for our implementation we only increase the SWP pointer without caring 
            -- for the memory content
            SWP          <= std_logic_vector(unsigned(SWP) + 1);
            data_mem_out <= (others => '1');
            -- after the spill the actual window is increased
            O_CWP <= CWP;
            CWP   <= N_CWP;
            N_CWP <= std_logic_vector(unsigned(N_CWP) + 1);
            STAR  <= S0;
          when S2 =>

            -- "10":  Fill
            -- fill logic for the memory
            -- like pop fro mthe stack 16 memory locations (one per clock cycle) 
            -- or even faster pop more locations at a time, but need to modify 
            -- heavly the bus

            -- for our implementation we only decrease the SWP pointer without caring 
            -- for the memory content
            SWP          <= std_logic_vector(unsigned(SWP) - 1);
            data_mem_out <= (others => '0');
            -- after the fill the actual window is decreased
            O_CWP <= std_logic_vector(unsigned(N_CWP) - 1);
            CWP   <= O_CWP;
            N_CWP <= CWP;
            STAR  <= S0;
          when others =>
            STAR <= S0;
        end case;
      end if;
    end if;
  end process;
end architecture;