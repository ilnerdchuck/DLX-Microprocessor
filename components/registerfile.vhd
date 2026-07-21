library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.constants.all;

entity register_file is
  generic (
    NBit : integer := numBit; -- number of bit per register
    NReg : integer := numReg -- number of memory locations/registers
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
end register_file;

architecture A of register_file is

  component FD is
    generic (NBIT : integer := NumBit);
    port (
      D     : in std_logic_vector(NBIT - 1 downto 0);
      CK    : in std_logic;
      RESET : in std_logic;
      Q     : out std_logic_vector(NBIT - 1 downto 0)
    );
  end component;

  type REG_ARRAY is array(NReg - 1 downto 0) of std_logic_vector(NBit - 1 downto 0);
  signal REG_ARRAY_IN, REG_ARRAY_OUT : REG_ARRAY;

begin

  -- We are using the FF form the first laboratory. 
  -- We create an array of registers and connect them to the input 
  -- via REG_ARRAY_IN and to the output via REG_ARRAY_OUT

  register_file_FD_gen : for i in NReg - 1 downto 0 generate
    REG_i : FD
    generic map(
      NBIT => NBit
    )
    port map
    (
      CK    => CLK,
      RESET => RESET,
      D     => REG_ARRAY_IN(i),
      Q     => REG_ARRAY_OUT(i)
    );
  end generate;

  -- The addressing of the register file is combinatorial ad the sequential behavior
  -- is baked into the registers already (basically the multiplexer in front of a memory)
  process (WR, ENABLE, RESET, ADD_WR, DATAIN)
  begin
    if WR = '1' and ENABLE = '1' and RESET = '0' then
      REG_ARRAY_IN(to_integer(unsigned(ADD_WR))) <= DATAIN;

    elsif RESET = '1' then

      for i in NReg - 1 downto 0 loop
        REG_ARRAY_IN(i) <= (others => '0');
      end loop;
    end if;

  end process;

  -- The output logic is not combinatorial because if the RDx signal is asserted
  -- then the output is asserted on the output line, but the new value should only be 
  -- asserted on the next rising clock edge after the RD signal is put to a high value.
  -- process (CLK)
  process (ADD_RD1, ADD_RD2, ENABLE, RESET)
  begin
    if RESET = '1' then
      OUT1 <= (others => '0'); -- Reset output 1
      OUT2 <= (others => '0'); -- Reset output 2
    end if;
    -- if rising_edge(CLK) then
    if ENABLE = '1' and RESET = '0' then
      -- if the RD signal is asserted we just update the output with the 
      -- correct value of the output signlas net of the registers 
      if RD1 = '1' then
        OUT1 <= REG_ARRAY_OUT(to_integer(unsigned(ADD_RD1)));
      end if;
      if RD2 = '1' then
        OUT2 <= REG_ARRAY_OUT(to_integer(unsigned(ADD_RD2)));
      end if;
    end if;
    -- end if;
  end process;
end A;

configuration CFG_RF_BEH of register_file is
  for A
  end for;
end configuration;
