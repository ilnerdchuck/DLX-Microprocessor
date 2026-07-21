#!/bin/sh

## Utils scripts
source ./scripts/utils/script_utils.sh
## Main functions scripts
source ./scripts/briciola.sh
source ./scripts/scorzetta.sh
source ./scripts/boh.sh
source ./scripts/cassiopeia.sh

# Main script - marley with continuous loop
clear
e_header "Welcome I'm Marley"
e_note "Using a terminal with color support is raccomended!"
e_bold "I'm the Microelectronics laboratory helper"
while true; do
    # Clear the screen (optional)
    # Display menu options
    e_bold "What do you want to do?"
    e_header "Menu"
    echo "1: Setup lab folder"
    echo "2: Run Briciola   (Compilation)"
    echo "3: Run Scorzetta  (Simulation)"
    echo "4: Run Boh        (Synthesis)"
    echo "5: Run Cassiopeia        (Phisical Design)"
    echo "6: Exit"
    e_header "===="

    # Read user input
    read -p "Enter your choice (1-6): " COMMAND

    # Process user input
    case $COMMAND in
    1)
        if [ ! -d ./exclude ]; then
            mkdir ./exclude
        fi
        if [ ! -d ./work ]; then
            mkdir ./work
        fi
        # TODO: Copy the scripts from the user home folder
        # TODO: Copy the component folder
        ;;
    2)
        # Compilation
        echo "Starting Briciola..."
        briciola
        read -p "Press [Enter] to return to Marley menu..."
        ;;
    3)
        # Simulation
        # compile the asm file
        e_bold "Enter the ASM file to compile (taken from ./asm/ folder !!!only name!!! extension will automatically added):"
        read ASM_FILE
        if [ ! -f "./asm/$ASM_FILE.asm" ]; then
            e_error "ASM file not found in ./asm/ folder."
            read -p "Press [Enter] to return to Marley menu..."
            continue
        fi

        e_arrow "Compiling $ASM_FILE..."
        rm ./test.asm.mem
        perl ./scripts/dlxasm.pl ./asm/${ASM_FILE}.asm && ./scripts/conv2memory ./asm/${ASM_FILE}.asm.exe >test.asm.mem

        if [ ! -f ./test.asm.mem ]; then
            e_error "Memory file not created - ASM compilation failed, please check the ASM file."
            read -p "Press [Enter] to return to Marley menu..."
            continue
        fi
        # Remove unneeded files
        rm ./asm/${ASM_FILE}.asm.exe
        rm ./asm/${ASM_FILE}.asm.exe.hdr

        # Start Scorzetta for the simulation
        if [ -d ./synthesys ]; then
            e_warning "It seems that this is a Simualtion folder!"
            while true; do
                read -r -p "Do you want to continue? (y/n)" ANSWER
                case $ANSWER in
                [Yy]*)
                    echo "Starting Scorzetta..."
                    scorzetta
                    break
                    ;;
                [Nn]*) break ;;
                *) e_error "Please answer Y or N." ;;
                esac
            done
        else
            echo "Starting Scorzetta..."
            scorzetta
        fi

        read -p "Press [Enter] to return to Marley menu..."
        ;;
    4)
        # Synthesis
        if [ -d ./simulation ]; then
            e_warning "It seems that this is a Simualtion folder!"
            while true; do
                read -r -p "Do you want to continue? (y/n)" ANSWER
                case $ANSWER in
                [Yy]*)
                    echo "Starting boh..."
                    boh
                    break
                    ;;
                [Nn]*) break ;;
                *) e_error "Please answer Y or N." ;;
                esac
            done
        else
            echo "Starting boh..."
            boh
        fi
        read -p "Press [Enter] to return to Marley menu..."
        ;;

    5)
        # Phisical Design
        # if no previous synthesis is present give error
        if [ ! -d ./synthesis ]; then
            e_warning "It seems that there was no previous synthesis done by Boh"
            while true; do
                read -r -p "Do you want to continue? (y/n)" ANSWER
                case $ANSWER in
                [Yy]*) break ;;
                [Nn]*) exit ;;
                *) e_error "Please answer Y or N." ;;
                esac
            done
        fi

        echo "Starting Cassiopeia..."
        cassiopeia
        read -p "Press [Enter] to return to Marley menu..."
        ;;
    6)
        e_header "Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice. Please enter 1,2,3,4,5."
        read -p "Press [Enter] to try again..."
        ;;
    esac
    clear
done
