#==============================================================================
#  Project     : DLX Processor Implementation
#  File        : simulation_template.tcl
#  Description : TCL file used to run the simulation of the DLX processor
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
# ${TOP_LEVEL_ENTITY} : Name of the top level entity to simulate
# ${SIM_TIME} : Simualtion Time
# ${SIM_RES} : Simualtion resolution
# ${WAVEFORM_FILE} : Output waveform file
# PS: if you need more info from the user given to
# the bash script you obv need to modify the
# bash script to export/eval those variables


# Load the simulation
# TODO: maybe ask for additional arguments?
vsim -t ${SIM_RES} -voptargs=+acc ${TOP_LEVEL_ENTITY}

# Open a waveform file to dump the simulaiton
vcd file ${WAVEFORM_FILE}
vcd add -r *
# add wave /*

# Run the simulation for the specified time
run ${SIM_TIME}

# wave zoom full
# Save the waveform file
# write wave waveform.ps -landscape -perpage 6ns
# view structure
# Exit Modelsim
quit;
