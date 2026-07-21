#!/bin/sh

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

function cassiopeia() {
    e_header "   Cassiopeia   "
    cat ./scripts/utils/stars.txt
    e_header "Physical Design tool"
    # Cassiopeia script to run innouvs with specified parameters
    # clean previous runs
    if [ -d ./physical_design ]; then
        rm -rf ./physical_design/*
    else
        mkdir -p ./physical_design
    fi

    touch ./physical_design/physical_design.log
    
    read -r -p "Enter the name of the synthesis folder: " SYN_FOLDER
    if [ ! -d "./synthesis/$SYN_FOLDER" ]; then
        e_error "Synthesis folder $SYN_FOLDER does not exist."
        exit 1
    fi

    read -r -p "Enter the name of the top level synthetsized: " TOP_LEVEL_ENTITY
    if [ ! -f "./synthesis/$SYN_FOLDER/structural/$TOP_LEVEL_ENTITY-structural-no-opt.v" ]; then
        e_error "Structural files for ./synthesis/$SYN_FOLDER/structural/$TOP_LEVEL_ENTITY-structural-no-opt.v does not exist."
        exit 1
    fi

    mkdir -p ./physical_design/designs
    mkdir -p ./physical_design/constraints
    mkdir -p ./physical_design/timingReport
    cp ./synthesis/$SYN_FOLDER/structural/*.v ./physical_design/designs/
    cp ./synthesis/$SYN_FOLDER/synthesized_constraints/*.sdc ./physical_design/constraints/

    if [ -f /eda/scripts/init_cadence_2020-21 ]; then
        source /eda/scripts/init_cadence_2020-21
    fi

    # Check if the physical design script template exists
    if [ ! -f ./scripts/scripts_templates/physical_design.tcl ]; then
        e_error "Physical design script template not found."
        exit 1
    fi

    e_header "Starting Physical Design with Innouvs"
    e_note "This may take a while, please be patient."
    # Run the innouvs command with the physical design script
    innovus -cpus 8 -no_gui -files ./scripts/scripts_templates/physical_design.tcl -log ./physical_design/physical_design.log

} 