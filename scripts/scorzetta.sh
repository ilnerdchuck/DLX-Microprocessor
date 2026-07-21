#!/bin/bash

function scorzetta() {
    ## UI things
    orange=$(tput setaf 215)

    VHDL_FILES=()
    WORK_DIR=$(pwd)

    e_header "   Scorzetta   "
    cat ./scripts/utils/cat1.txt
    e_header "Simulation tool"

    e_note "Using a terminal with color support is raccomended!"

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

    # If mode simulation are needed ask to name ad put the output files in
    # a separate folder
    while true; do
        read -r -p "Do you want to give a name to the current simulation? (y/n)" ANSWER
        case $ANSWER in
        [Yy]*)
            read -r -p "Simualation name: " SIM_NAME
            WORK_DIR="$WORK_DIR/simulations/$SIM_NAME"
            echo $WORK_DIR

            if [ ! -d "$WORK_DIR" ]; then
                mkdir -p $WORK_DIR
            else
                e_warning "Simulation with the same name present."
                while true; do
                    read -r -p "Do you want to overwrite  it? (y/n)" ANSWER
                    case $ANSWER in
                    [Yy]*)
                        rm $WORK_DIR/*
                        break
                        ;;
                    [Nn]*)
                        e_warning "Exiting Scorzetta"
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
    if [ -f /eda/scripts/init_questa_core_prime ]; then
        source /eda/scripts/init_questa_core_prime
    fi

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
    e_bold "Enter simulation resolution: Ex. "1ns""
    read SIM_RES
    e_bold "Enter the simulation time: Ex "40ns""
    read SIM_TIME
    e_bold "Enter the name of the top level entity to be simulated:"
    read TOP_LEVEL_ENTITY

    WAVEFORM_FILE="$WORK_DIR/waveform.vcd"
    MODELSIM_FILE="$WORK_DIR/waveform.wlf"

    ## TODO: add custom simulation file
    # Build the tcl file with the user defined variables
    ## NOT SAFE WE ARE USING EVAL, but we don´t need to export variables
    TCL_FILE=$(eval "echo \"$(<./scripts/scripts_templates/simulation_template.tcl)\"" 2>/dev/null)

    ## Safer but we need to export the variables
    # export TOP_LEVEL_ENTITY SIM_RES SIM_TIME WAVEFORM_FILEe
    # TCL_FILE=$(cat ./scripts_templates/simulation_template.tcl | envsubst)

    # Run the tcl template
    # If you must call $finish for some reason (e.g. it's called from within your test framework, and you can't modify it), you can get your exit code out to the caller using "onfinish stop". Example:

    # vsim -c test_bench -do "onfinish stop; run -all"
    vsim -c -do "$TCL_FILE"

    # Check vsim eexit status
    if [ $? -ne 0 ]; then
        e_error "Simulation of $TOP_LEVEL_ENTITY    [ FAILED ]"
        exit 1
    else
        e_success "Simulation of $TOP_LEVEL_ENTITY    [ OK ]"
    fi

    # If the waveform file is created
    # Create also a waveform file for modelsim, so we can use
    # both gtkwave and modelsim to view it
    if [ ! -e "$WAWAVEFORM_FILE" ]; then
        e_success "Creation of the waveform file    [ OK ]"
        e_arrow "Creating WLF modelsim waveform file..."
        vcd2wlf $WAVEFORM_FILE $MODELSIM_FILE
        if [ $? -ne 0 ]; then
            e_error "Creating WLF modelsim waveform file    [ FAILED ]"
            exit 1
        else

            e_success "Creating WLF modelsim waveform file    [ OK ]"
            e_note "Simulation finished, results are in $WORK_DIR"
            e_note "You can find the waveform file in $WORK_DIR/waveform.vcd"
            e_note "You can find the modelsim waveform file in $WORK_DIR/waveform.wlf"
            while true; do
                e_arrow "Do you want to open the waveform file with gtkwave(Gg) or modelsim(Mm) or exit(Nn)?"
                read -r -p "Choice (G/g, M/m or N/n): " WAVEFORM_VIEWER
                case $WAVEFORM_VIEWER in
                [Gg]*)
                    if ! type gtkwave >/dev/null; then
                        # install foobar here
                        e_error "gtkwave not found"
                        continue
                    fi

                    gtkwave "$WAVEFORM_FILE" &
                    >/dev/null
                    break
                    ;;
                [Mm]*)
                    if ! type vsim >/dev/null; then
                        # install foobar here
                        e_error "ModelSim/QuestaSim not found"
                        continue
                    fi
                    vsim -view "$MODELSIM_FILE" &
                    >/dev/null
                    break
                    ;;
                [Nn]*)
                    e_note "Oke exiting Scorzetta"
                    break
                    ;;
                *)
                    e_error "Please answer G/g, M/m or N/n."
                    ;;
                esac
            done
        fi
    else
        e_error "Creation of the waveform file    [ FAILED ]"
    fi

    # TODO: we can maybe integrate pushover to tell when the sim/synt is finished
    ## Revert UI things
    orange=$(tput setaf 215)
}
