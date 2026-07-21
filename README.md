# DLX Microprocessor

This Repository contains the design of a 32-Bit DLX microprocessor. The project aims to enhance understanding of microprocessor design stack: starting from RTL VHDL description to the Physical Design process.

## Tools

- **VHDL**: The hardware description language used for the design.
- **ModelSim**: Used for simulation and verification of the VHDL code.
- **Design Compiler**: Used for synthesis of the VHDL code into a gate-level netlist.
- **Cadence Innovus**: Used for physical design, including placement and routing.
- **Custom Scripts**: Shell scripts for automating various tasks in the design flow.

## Project Structure

- **asm**: Contains assembly files for the DLX microprocessor.
- **DLX_vhdl**: Contains the VHDL source code for the DLX microprocessor.
- **Simulations**: Contains files related to the simulation of the microprocessor.
- **Synthesis**: Contains files related to the synthesis process.
- **Physical_Design**: Contains files related to the physical design process.
- **Scripts**: Contains shell scripts for automating various tasks in the design flow.

To run the project, you need to have the necessary tools installed and configured on your system.

if you are only running the simulation yyou can run the project in a docker container available at [hw-tools-docker repository](https://github.com/ilnerdchuck/hw-tools-docker).

To run the project just start the `marley.sh` script in the root directory of the project. This script will guide you through all the necessary steps to Simulate, Synthetize and perform Physical Design of the DLX microprocessor.
