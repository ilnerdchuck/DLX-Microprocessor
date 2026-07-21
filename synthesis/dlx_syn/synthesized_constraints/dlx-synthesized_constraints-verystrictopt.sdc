###################################################################

# Created by write_sdc on Fri Jul 18 23:07:03 2025

###################################################################
set sdc_version 2.1

set_units -time ns -resistance MOhm -capacitance fF -voltage V -current mA
create_clock [get_ports clk]  -period 0.5  -waveform {0 0.25}
