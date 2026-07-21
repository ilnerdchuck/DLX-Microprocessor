#==============================================================================
#  Project     : DLX Processor Implementation
#  File        : synthesis_template.tcl
#  Description : TCL file used to run the synthesis of the DLX processor
#
#  Group Name  : Group 02
#  Members     : Sabina Sarcuni
#                Leonadro Gallina
#                Francesco Mignone
#
#  Supervisor  : Mariagrazia Graziano, Giavanna Turvani
#  Institution : Polytechnic of Turin, Italy
#
#  Created     : 11 July 2025
#  Last Edited : 11 July 2025
#
#  Notes       : - 5-stage pipeline (IF, ID, EX, MEM, WB)
#                - Supports basic instruction set: R-type, I-type, J-type
#                - Hazard detection and forwarding implemented
#                - Designed for simulation in ModelSim/Questasim
#
#==============================================================================
# Available variables from the bash script
#   WORK_DIR: Directory where the synthesis results will be stored
#     subfolders:
#     - /timing: timing reports
#     - /area: area reports
#     - /power: power reports
#     - /clk: clock reports
#     - /synthesized_constraints: synthesized constraints
#     - /structural: structural VHDL files
#   VHDL_FILES: List of VHDL files to be synthesized
#   TOP_LEVEL_ENTITY: Name of the top-level entity to be synthesized
#   ENTITY_CONF: Configuration of the top-level entity (e.g., architecture name)
# PS: if you need more info from the user given to
# the bash script you obv need to modify the
# bash script to export/eval those variables

# Set the libraries
set library WORK
define_design_lib WORK -path work
analyze -library WORK -format vhdl {${VHDL_FILES}}
elaborate ${TOP_LEVEL_ENTITY} -architecture ${ENTITY_CONF} -library work

# Without constraints
compile -map_effort high
# compile_ultra

# reporting timing and area after the first synthesis without constraints #
report_timing -nworst 10 > ${WORK_DIR}/timing/${TOP_LEVEL_ENTITY}-report-timing-no-opt.txt
report_area > ${WORK_DIR}/area/${TOP_LEVEL_ENTITY}-report-area-no-opt.txt
report_clock > ${WORK_DIR}/clk/${TOP_LEVEL_ENTITY}-report-clk-no-opt.txt
report_power > ${WORK_DIR}/power/${TOP_LEVEL_ENTITY}-report-power-no-opt.txt

write -hierarchy -format verilog -output ${WORK_DIR}/structural/${TOP_LEVEL_ENTITY}-structural-no-opt.v

write_sdc ${WORK_DIR}/synthesized_constraints/${TOP_LEVEL_ENTITY}-synthesized_constraints-no-opt.sdc

## Only with clock contraint
create_clock -name "clk" -period 2 clk
compile -map_effort high
# compile_ultra

report_timing -nworst 10 > ${WORK_DIR}/timing/${TOP_LEVEL_ENTITY}-report-timing-clkopt.txt
report_area > ${WORK_DIR}/area/${TOP_LEVEL_ENTITY}-report-area-clkopt.txt
report_clock > ${WORK_DIR}/clk/${TOP_LEVEL_ENTITY}-report-clk-clkopt.txt
report_power > ${WORK_DIR}/power/${TOP_LEVEL_ENTITY}-report-power-clkopt.txt

write -hierarchy -format verilog -output ${WORK_DIR}/structural/${TOP_LEVEL_ENTITY}-structural-clkopt.v

write_sdc ${WORK_DIR}/synthesized_constraints/${TOP_LEVEL_ENTITY}-synthesized_constraints-clkopt.sdc


## With both type of constraints
create_clock -name "clk" -period 2 clk
set_max_delay 2 -from [all_inputs] -to [all_outputs]
compile -map_effort high
# compile_ultra

report_timing -nworst 10 > ${WORK_DIR}/timing/${TOP_LEVEL_ENTITY}-report-timing-loose.txt
report_area > ${WORK_DIR}/area/${TOP_LEVEL_ENTITY}-report-area-loose.txt
report_clock > ${WORK_DIR}/clk/${TOP_LEVEL_ENTITY}-report-clk-loose.txt
report_power > ${WORK_DIR}/power/${TOP_LEVEL_ENTITY}-report-power-loose.txt

write -hierarchy -format verilog -output ${WORK_DIR}/structural/${TOP_LEVEL_ENTITY}-structural-loose.v
write_sdc ${WORK_DIR}/synthesized_constraints/${TOP_LEVEL_ENTITY}-synthesized_constraints-loose.sdc


## With strict constraints
create_clock -name "clk" -period 1 clk
set_max_delay 0.5 -from [all_inputs] -to [all_outputs]
compile -map_effort high
# compile_ultra

report_timing -nworst 10 > ${WORK_DIR}/timing/${TOP_LEVEL_ENTITY}-report-timing-strictopt.txt
report_area > ${WORK_DIR}/area/${TOP_LEVEL_ENTITY}-report-area-strictopt.txt
report_clock > ${WORK_DIR}/clk/${TOP_LEVEL_ENTITY}-report-clk-strictopt.txt
report_power > ${WORK_DIR}/power/${TOP_LEVEL_ENTITY}-report-power-strictopt.txt

write -hierarchy -format verilog -output ${WORK_DIR}/structural/${TOP_LEVEL_ENTITY}-structural-strictopt.v
write_sdc ${WORK_DIR}/synthesized_constraints/${TOP_LEVEL_ENTITY}-synthesized_constraints-strictopt.sdc


## With veri strict constraints
create_clock -name "clk" -period 0.5 clk
set_max_delay 0.5 -from [all_inputs] -to [all_outputs]
compile -map_effort high
# compile_ultra

report_timing -nworst 10 > ${WORK_DIR}/timing/${TOP_LEVEL_ENTITY}-report-timing-verystrictopt.txt
report_area > ${WORK_DIR}/area/${TOP_LEVEL_ENTITY}-report-area-verystrictopt.txt
report_clock > ${WORK_DIR}/clk/${TOP_LEVEL_ENTITY}-report-clk-verystrictopt.txt
report_power > ${WORK_DIR}/power/${TOP_LEVEL_ENTITY}-report-power-verystrictopt.txt

write -hierarchy -format verilog -output ${WORK_DIR}/structural/${TOP_LEVEL_ENTITY}-structural-verystrictopt.v
write_sdc ${WORK_DIR}/synthesized_constraints/${TOP_LEVEL_ENTITY}-synthesized_constraints-verystrictopt.sdc


## With lower bound constraints
create_clock -name "clk" -period 0 clk
compile -map_effort high
# compile_ultra

report_timing -nworst 10 > ${WORK_DIR}/timing/${TOP_LEVEL_ENTITY}-report-timing-lower-bound.txt
report_area > ${WORK_DIR}/area/${TOP_LEVEL_ENTITY}-report-area-lower-bound.txt
report_clock > ${WORK_DIR}/clk/${TOP_LEVEL_ENTITY}-report-clk-lower-bound.txt
report_power > ${WORK_DIR}/power/${TOP_LEVEL_ENTITY}-report-power-lower-bound.txt

write -hierarchy -format verilog -output ${WORK_DIR}/structural/${TOP_LEVEL_ENTITY}-structural-lower-bound.v
write_sdc ${WORK_DIR}/synthesized_constraints/${TOP_LEVEL_ENTITY}-synthesized_constraints-lower-bound.sdc

# Exit
exit
