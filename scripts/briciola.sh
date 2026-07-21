#!/bin/sh

function briciola() {
    orange=$(tput setaf 69)

    e_header "    Briciola    "
    cat ./scripts/utils/cat2.txt
    e_header "Compilation tool"

    # Create the hiearachy
    find -type f -name "*.vhd" -not -path "./work/*" -not -path "./exclude/*" -not -path "./simulations/*" | tr " " "\n" | ./scripts/utils/pupi > compile.list
    if [ $? -ne 0 ]; then
        e_error "Error in creating compile.list"
        exit 1
    fi
    
    e_success "Created compile.list file"
    # Append files in the compile.list file
    # and remove trailing spaces or empty lines
    while IFS="" read -r p || [ -n "$p" ]
        do
            VHDL_FILES+=($(echo "$p" | xargs))
        done < compile.list

    # Compile the Hierarchy
    # if /eda/scripts/init_questa_core_prime exists, source it
    if [ -f /eda/scripts/init_questa_core_prime ]; then
        source /eda/scripts/init_questa_core_prime
    fi

    if  [ ! -e work/ ]; then
        mkdir -p work/
    fi
    
    vlib work

    for i in "${VHDL_FILES[@]}"
        do
            e_header "Started Compilation of file: $i"
            # !!WARNINIG!! this works in the docker need to check on the server
            vcom -work work "$i"
            if [ $? -ne 0 ]; then
                e_error "Compilation of file  $i    [ FAILED ]"
                return
                exit 1
            else
                e_success "Compilation of file  $i    [ OK ]"
            fi
            e_header " Ended Compilation of file: $i "
        done

    e_header " Exiting Briciola "
    e_header " Compilation Ended "

    orange=$(tput setaf 215)
}
