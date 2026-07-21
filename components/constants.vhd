package CONSTANTS is
  constant IVDELAY     : time    := 0.1 ns;
  constant NDDELAY     : time    := 0.2 ns;
  constant NDDELAYRISE : time    := 0.6 ns;
  constant NDDELAYFALL : time    := 0.4 ns;
  constant NRDELAY     : time    := 0.2 ns;
  constant DRCAS       : time    := 1 ns;
  constant DRCAC       : time    := 2 ns;
  constant TP_MUX      : time    := 0.5 ns;
  constant NumBit      : integer := 32;
  constant NumReg      : integer := 8;
  constant numWindow   : integer := 8;
  constant NumThread   : integer := 4;
end CONSTANTS;