#!/bin/bash

function boh() {
    ## UI things
    orange=$(tput setaf 215)

    VHDL_FILES=()
    WORK_DIR=$(pwd)

    e_header "     boh      "
    cat ./scripts/utils/boh.txt
    e_header "Synthesis tool"

    ## Check and ask if the user wants to run briciola before simulating
    if [ ! -e compile.list ]; then
        e_warning "It seems that there was no previous compilation done by Briciola"
        while true; do
            read -r -p "Do you want to continue? (y/n)" ANSWER
            case $ANSWER in
            [Yy]*) break ;;
            [Nn]*) exit ;;
            *) e_error "Please answer Y or N." ;;
            esac
        done
    fi
    while true; do
        read -r -p "Do you want to run Briciola to compile the files? (y/n)" ANSWER
        case $ANSWER in
        [Yy]*)
            briciola
            break
            ;;
        [Nn]*) break ;;
        *) e_error "Please answer Y or N." ;;
        esac
    done

    # If mode synthesis are needed ask to name ad put the output files in
    # a separate folder
    while true; do
        read -r -p "Do you want to give a name to the synthesis? (y/n)" ANSWER
        case $ANSWER in
        [Yy]*)
            read -r -p "Synthesis name: " SYN_NAME
            WORK_DIR="$WORK_DIR/synthesis/$SYN_NAME"
            if [ ! -d $WORK_DIR ]; then
                mkdir -p $WORK_DIR
                mkdir -p $WORK_DIR/timing
                mkdir -p $WORK_DIR/power
                mkdir -p $WORK_DIR/area

            else
                echo "Synthesis with the same name present."
                while true; do
                    read -r -p "Do you want to overwrite  it? (y/n)" ANSWER
                    case $ANSWER in
                    [Yy]*)
                        rm -rf $WORK_DIR/*
                        mkdir -p $WORK_DIR/timing
                        mkdir -p $WORK_DIR/power
                        mkdir -p $WORK_DIR/area
                        mkdir -p $WORK_DIR/clk
                        mkdir -p $WORK_DIR/synthesized_constraints
                        mkdir -p $WORK_DIR/structural
                        break
                        ;;
                    [Nn]*)
                        e_warning "Exiting Boh"
                        exit
                        ;;
                    *) e_error "Please answer Y or N." ;;
                    esac
                done
            fi
            break
            ;;
        [Nn]*) break ;;
        *) e_error "Please answer Y or N." ;;
        esac
    done

    ## TODO: get the available entities or configurations from the library
    # ******************************
    # * Entity: TB_ALU             *
    # * Available Configurations:  *
    # *   TEST_BEH_ALU             *
    # *   TEST_STR_ALU             *
    # * Entity: ALU                *
    # * Available Configurations:  *
    # *   STR_ALU                  *
    # *   BEH_ALU                  *
    # ******************************

    ## Ask for simulaiton parameters
    echo "Enter the name of the top level entity to be Synthetized:"
    read TOP_LEVEL_ENTITY
    echo "Enter the the name of the architecture/configuration of $TOP_LEVEL_ENTITY to be Synthetized:"
    read ENTITY_CONF

    ## Design Vision setup
    cp /home/repository/ms/setup/.synopsys_dc.setup .
    source /eda/scripts/init_design_vision

    e_header "Starting Synthesis"
    # Append files in the compile.list file
    # and remove trailing spaces or empty lines
    VHDL_FILES=$(cat ./compile.list)

    ## TODO: add custom synthesis file
    # Build the tcl file with the user defined variables
    ## NOT SAFE WE ARE USING EVAL, but we don´t need to export variables

    TCL_FILE=$(eval "echo \"$(<./scripts/scripts_templates/synthesis_template.tcl)\"" 2>/dev/null)
    echo "$TCL_FILE" >./scripts/tmp.tcl

    ## Safer but we need to export the variables
    # export TOP_LEVEL_ENTITY SIM_RES SIM_TIME WAVEFORM_FILEe
    # TCL_FILE=$(cat ./scripts_templates/synthesis_template.tcl | envsubst)

    # Run the tcl template
    dc_shell-xg-t -f ./scripts/tmp.tcl
    # vsim -c -do "$TCL_FILE"

    # Check vsim eexit status
    if [ $? -ne 0 ]; then
        e_error "Synthesis of $TOP_LEVEL_ENTITY    [ FAILED ]"
        exit 1
    else
        e_success "Synthesis of $TOP_LEVEL_ENTITY    [ OK ]"
    fi
    rm ./scripts/tmp.tcl
    # If the waveform file is created
    # Create also a waveform file for modelsim, so we can use
    # both gtkwave and modelsim to view it
    # if [ -e $WORK_DIR/report_area.txt ]; then
    #     e_success "Creation of the report_area file    [ OK ]"
    # else
    #     e_error "Creation of the report_area file    [ FAILED ]"
    # fi
    # if [ -e $WORK_DIR/report_timing.txt ]; then
    #     e_success "Creation of the report_area file    [ OK ]"
    # else
    #     e_error "Creation of the report_area file    [ FAILED ]"
    # fi
    # if [ -e $WORK_DIR/report_power.txt ]; then
    #     e_success "Creation of the report_area file    [ OK ]"
    # else
    #     e_error "Creation of the report_area file    [ FAILED ]"
    # fi

    # TODO: we can maybe integrate pushover to tell when the sim/synt is finished

    ## Revert UI things
    orange=$(tput setaf 215)
}
